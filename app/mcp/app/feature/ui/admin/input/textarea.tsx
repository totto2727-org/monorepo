import type { JSX } from "hono/jsx"
import * as FormControl from "./form-controll.js"

export function Textarea(
  props: FormControl.FormControlProps & {
    textareaAttributes: JSX.IntrinsicElements["textarea"]
  },
) {
  return (
    <FormControl.FormControl
      description={props.description}
      name={props.name}
      required={props.textareaAttributes.required ?? false}
    >
      <textarea
        {...props.textareaAttributes}
        class="textarea textarea-bordered h-24"
      />
    </FormControl.FormControl>
  )
}
