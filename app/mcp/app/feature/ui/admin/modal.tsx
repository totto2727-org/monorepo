import type { JSX, PropsWithChildren } from "hono/jsx"

function Modal(props: PropsWithChildren<{ id: string }>) {
  return (
    <dialog class="modal" id={props.id}>
      {props.children}
      <form class="modal-backdrop" method="dialog">
        <button type="submit">close</button>
      </form>
    </dialog>
  )
}

export function createModal(id: string) {
  return {
    CloseButton: (
      props: PropsWithChildren<JSX.IntrinsicElements["button"]>,
    ) => (
      <button
        _="on click call #{@data-modal-id}.close()"
        data-modal-id={id}
        type="button"
        {...props}
      >
        {props.children}
      </button>
    ),
    Form: (props: PropsWithChildren<JSX.IntrinsicElements["form"]>) => (
      <form
        {...props}
        _="on htmx:afterRequest if detail.successful then close() the #{@data-modal-id} then reset() the me"
        data-modal-id={id}
      >
        {props.children}
      </form>
    ),
    Modal: (props: PropsWithChildren) => (
      <Modal id={id}>{props.children}</Modal>
    ),
    OpenButton: (props: PropsWithChildren<JSX.IntrinsicElements["button"]>) => (
      <button
        _="on click call #{@data-modal-id}.showModal()"
        data-modal-id={id}
        type="button"
        {...props}
      >
        {props.children}
      </button>
    ),
  }
}
