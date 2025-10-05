import type { Child, FC, PropsWithChildren } from "hono/jsx"
import * as Icon from "./icon.js"

export const SideMenu: FC<PropsWithChildren> = (props) => (
  <div class="space-4">
    <h2 class="text-lg font-semibold">Menu</h2>
    <ul class="menu">{props.children}</ul>
  </div>
)

export const SideMenuItem: FC<PropsWithChildren<{ href: string }>> = (
  props,
) => (
  <li>
    <a class="flex items-center gap-3" href={props.href}>
      {props.children}
    </a>
  </li>
)

export const AppShell: FC<
  PropsWithChildren<{ side: Child; title: string }>
> = ({ children, side, title }) => (
  <div class="min-h-screen bg-base-200" hx-boost="true">
    <div class="drawer lg:drawer-open">
      <input class="drawer-toggle" id="drawer-toggle" type="checkbox" />

      <div class="drawer-content flex flex-col">
        <div class="navbar bg-base-100 shadow-lg">
          <div class="flex-1">
            <h1 class="btn btn-ghost text-xl">{title}</h1>
          </div>
          <div class="flex-none">
            <label
              class="drawer-button btn btn-square btn-ghost"
              htmlFor="drawer-toggle"
            >
              <Icon.Menu ariaLabel="Menu Icon" />
            </label>
          </div>
        </div>

        <main class="flex-1 p-6">{children}</main>
      </div>

      <div class="drawer-side shadow-lg">
        <label
          aria-label="Close menu"
          class="drawer-overlay"
          htmlFor="drawer-toggle"
        ></label>
        <aside class="w-64 min-h-full bg-base-100 p-4">{side}</aside>
      </div>
    </div>
  </div>
)
