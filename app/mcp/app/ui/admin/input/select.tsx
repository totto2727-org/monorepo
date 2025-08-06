import type { JSX, PropsWithChildren } from "hono/jsx"
import { FormControl, type FormControlProps } from "./form-controll.js"

export function Select(
  props: PropsWithChildren<
    FormControlProps & {
      selectAttributes: JSX.IntrinsicElements["select"]
    }
  >,
) {
  return (
    <FormControl
      description={props.description}
      name={props.name}
      required={props.selectAttributes.required ?? false}
    >
      <select {...props.selectAttributes} class="select select-bordered">
        {props.children}
      </select>
    </FormControl>
  )
}
