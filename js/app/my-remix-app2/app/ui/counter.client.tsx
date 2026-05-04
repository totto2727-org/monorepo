import { clientEntry, css, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'

interface CounterProps extends SerializableProps {
  initial?: number
}

export const Counter = clientEntry(
  '/assets/app/ui/counter.client.tsx#Counter',
  function Counter(handle: Handle<CounterProps>) {
    let count = handle.props.initial ?? 0

    return () => (
      <section mix={containerStyle}>
        <button
          type="button"
          aria-label="decrement"
          mix={[
            buttonStyle,
            on('click', () => {
              count -= 1
              handle.update()
            }),
          ]}
        >
          -
        </button>
        <output mix={countStyle}>{count}</output>
        <button
          type="button"
          aria-label="increment"
          mix={[
            buttonStyle,
            on('click', () => {
              count += 1
              handle.update()
            }),
          ]}
        >
          +
        </button>
        <button
          type="button"
          mix={[
            resetButtonStyle,
            on('click', () => {
              count = handle.props.initial ?? 0
              handle.update()
            }),
          ]}
        >
          Reset
        </button>
      </section>
    )
  },
)

const containerStyle = css({
  alignItems: 'center',
  display: 'flex',
  gap: '16px',
  justifyContent: 'center',
  padding: '32px 16px',
})

const countStyle = css({
  fontSize: '48px',
  fontVariantNumeric: 'tabular-nums',
  fontWeight: 700,
  minWidth: '4ch',
  textAlign: 'center',
})

const buttonStyle = css({
  '&:hover, &:focus-visible': {
    background: '#1d4ed8',
    outline: 'none',
  },
  alignItems: 'center',
  background: '#2563eb',
  border: 0,
  borderRadius: '8px',
  color: 'white',
  cursor: 'pointer',
  display: 'flex',
  fontSize: '24px',
  height: '44px',
  justifyContent: 'center',
  width: '44px',
})

const resetButtonStyle = css({
  '&:hover, &:focus-visible': {
    background: '#e5e7eb',
    outline: 'none',
  },
  background: '#f3f4f6',
  border: 0,
  borderRadius: '8px',
  color: '#111827',
  cursor: 'pointer',
  fontSize: '14px',
  height: '36px',
  marginLeft: '8px',
  padding: '0 16px',
})
