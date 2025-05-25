import { Outlet, Scripts } from "react-router"

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta content="width=device-width, initial-scale=1" name="viewport" />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  )
}

export default function App() {
  return <Outlet />
}
