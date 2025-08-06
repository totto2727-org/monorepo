import { DurationFormat } from "@formatjs/intl-durationformat"
import { Temporal } from "@totto/function/temporal"

const formatter = new DurationFormat("en", {
  style: "short",
})

export function formatDurationFromNow(date: Date): string {
  const now = Temporal.Now.instant()
  const targetDate = Temporal.Instant.from(date.toISOString())
  const duration = targetDate.until(now)

  return formatter.format(duration)
}
