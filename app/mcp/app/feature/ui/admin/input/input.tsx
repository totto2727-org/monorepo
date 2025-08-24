import type { JSX } from "hono/jsx"
import * as FormControl from "./form-controll.js"

export function Input(
  props: FormControl.FormControlProps & {
    inputAttributes: JSX.IntrinsicElements["input"]
  },
) {
  return (
    <FormControl.FormControl
      description={props.description}
      name={props.name}
      required={props.inputAttributes.required ?? false}
    >
      <input {...props.inputAttributes} class="input input-bordered" />
    </FormControl.FormControl>
  )
}
