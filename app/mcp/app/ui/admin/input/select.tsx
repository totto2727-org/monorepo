import type { JSX, PropsWithChildren } from "hono/jsx"
import * as FormControl from "./form-controll.js"

export function Select(
  props: PropsWithChildren<
    FormControl.FormControlProps & {
      selectAttributes: JSX.IntrinsicElements["select"]
    }
  >,
) {
  return (
    <FormControl.FormControl
      description={props.description}
      name={props.name}
      required={props.selectAttributes.required ?? false}
    >
      <select {...props.selectAttributes} class="select select-bordered">
        {props.children}
      </select>
    </FormControl.FormControl>
  )
}
