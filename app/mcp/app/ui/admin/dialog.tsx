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
        onclick={`document.getElementById('${id}').close()`}
        type="button"
        {...props}
      >
        {props.children}
      </button>
    ),
    Modal: (props: PropsWithChildren) => (
      <Modal id={id}>{props.children}</Modal>
    ),
    OpenButton: (props: PropsWithChildren<JSX.IntrinsicElements["button"]>) => (
      <button
        onclick={`document.getElementById('${id}').showModal()`}
        type="button"
        {...props}
      >
        {props.children}
      </button>
    ),
  }
}
