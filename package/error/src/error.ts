import type { Simplify } from "@totto/function/type"

export type RFC7807ErrorStruct = {
  type: string
  title?: string
  status?: number
  detail?: string
  instance?: string
}

export function toString(error: RFC7807Error): string {
  return JSON.stringify(error)
}

export class RFC7807Error extends Error implements RFC7807ErrorStruct {
  type: string
  title?: string
  status?: number
  detail?: string
  instance?: string

  constructor(props: Partial<RFC7807ErrorStruct>) {
    const struct = {
      detail: props.detail,
      instance: props.instance,
      status: props.status,
      title: props.title,
      type: props.type ?? "about:blank",
    }
    super(JSON.stringify(struct))
    this.type = struct.type
    this.title = struct.title
    this.status = struct.status
    this.detail = struct.detail
    this.instance = struct.instance
  }
}

export type HTTPErrorStruct<T extends number> = Simplify<
  RFC7807ErrorStruct & {
    status: T
  }
>

export class HTTPError<const T extends number>
  extends RFC7807Error
  implements HTTPErrorStruct<T>
{
  override status: T

  constructor(status: T, props?: Partial<Omit<HTTPErrorStruct<T>, "status">>) {
    super(props ?? {})
    this.status = status
  }

  toJSON(): HTTPErrorStruct<T> {
    return {
      detail: this.detail,
      instance: this.instance,
      status: this.status,
      title: this.title,
      type: this.type,
    }
  }
}

export function toHonoResponse<const T extends number>(
  error: HTTPError<T>,
): [HTTPErrorStruct<T>, T] {
  return [error.toJSON(), error.status]
}
