import { Predicate } from "@totto/function/effect"
import type { PropsWithChildren } from "hono/jsx"
import * as Required from "./required.js"

export type FormControlProps = {
  name: string
  description?: string
}

export function FormControl(
  props: PropsWithChildren<
    FormControlProps & {
      required: boolean
    }
  >,
) {
  return (
    <div class="form-control space-y-2">
      <div class="label">
        <span class="label-text font-semibold">{props.name}</span>
        <Required.Required required={props.required ?? false} />
      </div>

      {Predicate.isNotNullable(props.description) ? (
        <div class="text-sm text-base-content/70">{props.description}</div>
      ) : null}

      <div>{props.children}</div>
    </div>
  )
}
