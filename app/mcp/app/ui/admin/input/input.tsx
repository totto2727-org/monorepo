import type { JSX } from "hono/jsx"
import { FormControl, type FormControlProps } from "./form-controll.js"

export function Input(
  props: FormControlProps & {
    inputAttributes: JSX.IntrinsicElements["input"]
  },
) {
  return (
    <FormControl
      description={props.description}
      name={props.name}
      required={props.inputAttributes.required ?? false}
    >
      <input {...props.inputAttributes} class="input input-bordered" />
    </FormControl>
  )
}
