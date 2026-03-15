# @package/ui

React UI component library based on Shadcn/UI with Tailwind CSS v4.

## Tech Stack

- **Base**: Shadcn/UI component patterns
- **Styling**: Tailwind CSS v4 + tw-animate-css
- **Variants**: class-variance-authority (CVA)
- **Utilities**: clsx + tailwind-merge
- **Icons**: Lucide React
- **Type Check**: tsgo

## Exports

- `@package/ui/style.css` - Global styles (Tailwind CSS)
- `@package/ui/utils` - Utility functions (cn, etc.)
- `@package/ui/components/*` - React components
- `@package/ui/components/ui/*` - UI primitives (button, etc.)
- `@package/ui/hooks/*` - Custom React hooks
- `@package/ui/lib/*` - Library utilities

## Development

```bash
# Type check
vp run check
```

## Adding Components

Components are managed via `components.json` configuration for Shadcn/UI CLI generation.
