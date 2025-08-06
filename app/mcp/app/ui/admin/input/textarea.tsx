import type { JSX } from "hono/jsx"
import { FormControl, type FormControlProps } from "./form-controll.js"

export function Textarea(
  props: FormControlProps & {
    textareaAttributes: JSX.IntrinsicElements["textarea"]
  },
) {
  return (
    <FormControl
      description={props.description}
      name={props.name}
      required={props.textareaAttributes.required ?? false}
    >
      <textarea
        {...props.textareaAttributes}
        class="textarea textarea-bordered h-24"
      />
    </FormControl>
  )
}
