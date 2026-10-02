# Scheduled and Periodic Task Design

> Document type: language-independent design checklist.

Read before implementing or changing a scheduled job, recurring batch, or polling loop.
Translate phrases such as "every ten minutes" into an explicit execution contract before choosing a timer API, cron expression, or scheduler.

## Define the time basis

- **Calendar schedule:** execute at wall-clock times, such as every day at 09:00 in a named time zone.
  Define behavior for daylight-saving gaps or repeated times when relevant.
- **Fixed rate:** schedule from an anchor, such as every ten minutes from 00:03.
  Decide what happens when an execution exceeds the interval.
- **Fixed delay:** wait ten minutes after completion before starting again.
  This is valid when the requirement is a recovery or polling pause, but task duration adds to the start-to-start interval.

Do not replace one basis with another merely because a scheduler makes it convenient.
For example, a cron expression firing at minutes 00, 10, and 20 does not preserve a fixed-rate anchor at minutes 03, 13, and 23.
Use elapsed-time clocks for in-process duration measurement where appropriate, and wall-clock instants for calendar deadlines and durable records.
Do not assume an in-process clock value remains meaningful after restart.

## Resolve lifecycle and failure semantics

Record the applicable decisions close to the job's implementation or configuration.
Keep the policy proportionate to the job's consequences rather than building a general scheduler for every task.

1. **First run and restart:** run immediately, wait for the next slot, or perform separate initialization?
   Identify which anchor, completed window, or progress state must survive restart so restarting does not silently reset the interval or repeat a side effect.
2. **Slow or overlapping runs:** skip the next slot, queue it with a bound, allow bounded concurrency, cancel safely, or stop and alert?
   Define execution deadlines and cancellation behavior where needed; do not assume the previous run finishes before the next trigger.
3. **Missed runs:** skip, coalesce, or replay the missed windows with a bound?
   Verify the selected scheduler's actual catch-up behavior rather than assuming one trigger per missed slot.
4. **Data ownership:** give each run an explicit logical window, such as `[start, end)`, when processing time-partitioned data.
   Do not let retries accidentally process "everything left over" or depend on the previous run having succeeded unless that dependency is intentional.
5. **Duplicates and partial success:** identify a logical run or operation independently of its retry attempt.
   Define how repeated execution avoids duplicate effects, resumes safely, or detects a conflict and stops.
   Scheduler execution records alone do not prove that business effects happened exactly once.
6. **Retries:** classify retryable failures, set an interval or backoff and an attempt or elapsed-time budget, and account for interaction with the next scheduled run.
   Consider jitter when synchronized retries would amplify load.
   Do not retry irreversible effects without a safe duplicate-handling policy.
7. **Failure visibility and recovery:** expose the failed run, affected window, cause, and recovery action without leaking secrets.
   Decide when continued execution is safe and when to stop and alert an operator.

## Keep scheduling separate from task work

Make the task independently invocable with explicit inputs such as its logical processing window.
Keep timing, overlap control, and retry orchestration outside the business operation so it can be tested and rerun without waiting for a timer.
Prefer an existing scheduler that fits the deployment environment and the required contract.
An in-process loop can be appropriate for a scoped polling lifecycle, but `task(); sleep(interval)` implements fixed delay, not fixed rate, and does not provide durable scheduling by itself.

## Source and interpretation

This checklist draws on Jxck's [Scheduled and Periodic Execution Implementation Guide](https://blog.jxck.io/entries/2026-03-03/scheduled-and-periodic-execution.html) and adds explicit decision boundaries for reuse across runtimes.
Read the article for concrete failure scenarios and operational trade-offs.

Its preference for systemd, stopping to call a human, or roughly two retries is experience-based advice, not a universal requirement.
Choose the scheduler, retry budget, and escalation policy from the deployment environment and the consequences of failure.
Consult the chosen scheduler's official documentation for persistence, overlap, and catch-up guarantees before relying on them.
