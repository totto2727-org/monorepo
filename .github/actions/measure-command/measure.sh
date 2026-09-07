#!/usr/bin/env bash

set -uo pipefail

if [[ ! "${PERFORMANCE_INTERVAL_SECONDS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "sampling-interval must be a positive integer" >&2
  exit 1
fi

readonly metrics_dir="${GITHUB_WORKSPACE}/ci-metrics/${GITHUB_JOB}"
readonly sar_binary="${metrics_dir}/sar.bin"
readonly timing_file="${metrics_dir}/time.txt"

mkdir -p "${metrics_dir}"

{
  echo "logical_cpus=$(nproc)"
  echo
  lscpu
  echo
  free --bytes
  echo
  df --block-size=1
} >"${metrics_dir}/runner.txt"

LC_ALL=C sar -A -o "${sar_binary}" "${PERFORMANCE_INTERVAL_SECONDS}" >/dev/null 2>&1 &
sampler_pid=$!
sampler_stopped=false

stop_sampler() {
  if [[ "${sampler_stopped}" == "false" ]]; then
    kill -INT "${sampler_pid}" 2>/dev/null || true
    wait "${sampler_pid}" 2>/dev/null || true
    sampler_stopped=true
  fi
}

trap stop_sampler EXIT

set +e
/usr/bin/time \
  --format=$'elapsed_seconds=%e\nuser_seconds=%U\nsystem_seconds=%S\nmax_rss_kb=%M\nexit_status=%x' \
  --output="${timing_file}" \
  bash -euo pipefail -c "${PERFORMANCE_COMMAND}"
command_status=$?
set -e

stop_sampler
trap - EXIT

LC_ALL=C S_TIME_FORMAT=ISO sar -A -f "${sar_binary}" >"${metrics_dir}/sar.txt"
LC_ALL=C S_TIME_FORMAT=ISO sadf -j "${sar_binary}" -- -A >"${metrics_dir}/sar.json"

timing_value() {
  local key=$1
  awk -F= -v key="${key}" '$1 == key { print $2 }' "${timing_file}"
}

elapsed_seconds="$(timing_value elapsed_seconds)"
user_seconds="$(timing_value user_seconds)"
system_seconds="$(timing_value system_seconds)"
max_rss_kb="$(timing_value max_rss_kb)"
logical_cpus="$(nproc)"
readonly elapsed_seconds user_seconds system_seconds max_rss_kb logical_cpus

average_parallelism="$({
  awk \
    -v user="${user_seconds}" \
    -v kernel="${system_seconds}" \
    -v elapsed="${elapsed_seconds}" \
    'BEGIN { if (elapsed > 0) printf "%.2f", (user + kernel) / elapsed; else print "n/a" }'
})"
cpu_capacity_utilization="$({
  awk \
    -v parallelism="${average_parallelism}" \
    -v cpus="${logical_cpus}" \
    'BEGIN { if (cpus > 0) printf "%.1f%%", parallelism / cpus * 100; else print "n/a" }'
})"
max_rss_mib="$({
  awk -v rss="${max_rss_kb}" 'BEGIN { printf "%.1f MiB", rss / 1024 }'
})"
readonly average_parallelism cpu_capacity_utilization max_rss_mib

read -r average_cpu_utilization average_io_wait < <(
  LC_ALL=C S_TIME_FORMAT=ISO sar -u -f "${sar_binary}" | awk '
    /%idle/ {
      for (column = 1; column <= NF; column++) {
        if ($column == "%idle") idle_column = column
        if ($column == "%iowait") io_wait_column = column
      }
      next
    }
    $1 == "Average:" && $2 == "all" && idle_column && io_wait_column {
      printf "%.1f%% %.1f%%\n", 100 - $idle_column, $io_wait_column
    }
  '
)

minimum_available_memory_mib="$({
  LC_ALL=C S_TIME_FORMAT=ISO sar -r -f "${sar_binary}" | awk '
    /kbavail/ {
      for (column = 1; column <= NF; column++) {
        if ($column == "kbavail") available_column = column
      }
      next
    }
    $1 ~ /^[0-9]/ && available_column {
      if (!minimum || $available_column < minimum) minimum = $available_column
    }
    END {
      if (minimum) printf "%.1f MiB", minimum / 1024
      else print "n/a"
    }
  '
})"
readonly minimum_available_memory_mib

{
  echo "## CI performance"
  echo
  echo "| Metric | Value |"
  echo "| --- | ---: |"
  echo "| Elapsed time | ${elapsed_seconds} s |"
  echo "| Logical CPUs | ${logical_cpus} |"
  echo "| Average runner CPU utilization | ${average_cpu_utilization:-n/a} |"
  echo "| Average runner I/O wait | ${average_io_wait:-n/a} |"
  echo "| Average command parallelism | ${average_parallelism} |"
  echo "| Command CPU-capacity utilization | ${cpu_capacity_utilization} |"
  echo "| Minimum available runner memory | ${minimum_available_memory_mib} |"
  echo "| Command max RSS | ${max_rss_mib} |"
  echo "| Command exit status | ${command_status} |"
  echo
  echo "Sampling covers only the measured command. Raw CPU, memory, network, disk, and process-queue data are available in the \`ci-performance-*\` artifact."
} >>"${GITHUB_STEP_SUMMARY}"

exit "${command_status}"
