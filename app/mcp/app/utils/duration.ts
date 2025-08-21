import { DurationFormat } from "@formatjs/intl-durationformat"
import { DateTime, Duration } from "@totto/function/effect"

const formatter = new DurationFormat("en", {
  style: "narrow",
})

export function formatShort(
  from: DateTime.DateTime,
  to: DateTime.DateTime,
): string {
  const duration = DateTime.distanceDuration(from, to)

  const parts = Duration.parts(duration)

  if (parts.days >= 365 / 12) {
    return formatter.format({
      months: Math.trunc(parts.days / (365 / 12)) % 12,
      years: Math.trunc(parts.days / 365),
    })
  } else if (parts.days >= 7) {
    return formatter.format({
      weeks: Math.trunc(parts.days / 7),
    })
  } else if (parts.days !== 0) {
    return formatter.format({
      days: parts.days,
    })
  } else if (parts.hours !== 0) {
    return formatter.format({
      hours: parts.hours,
      minutes: parts.minutes,
    })
  }

  return formatter.format(Duration.parts(duration))
}
