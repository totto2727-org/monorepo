import { Array, Predicate, String } from 'effect'
import { clientEntry, css, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'

interface Item {
  id: string
  text: string
  done: boolean
}

const containerStyle = css({
  display: 'flex',
  flexDirection: 'column',
  gap: '16px',
  margin: '0 auto',
  maxWidth: '480px',
  padding: '24px 16px',
})

const formStyle = css({
  display: 'flex',
  gap: '8px',
})

const inputStyle = css({
  '&:focus-visible': {
    borderColor: '#2563eb',
    outline: 'none',
  },
  background: 'white',
  border: '1px solid #d1d5db',
  borderRadius: '8px',
  flex: '1 1 0',
  fontSize: '14px',
  height: '40px',
  padding: '0 12px',
})

const addButtonStyle = css({
  '&:hover, &:focus-visible': {
    background: '#1d4ed8',
    outline: 'none',
  },
  background: '#2563eb',
  border: 0,
  borderRadius: '8px',
  color: 'white',
  cursor: 'pointer',
  fontSize: '14px',
  fontWeight: 600,
  height: '40px',
  padding: '0 16px',
})

const summaryStyle = css({
  color: '#6b7280',
  fontSize: '13px',
  margin: 0,
})

const listStyle = css({
  display: 'flex',
  flexDirection: 'column',
  gap: '8px',
  listStyle: 'none',
  margin: 0,
  padding: 0,
})

const itemStyle = css({
  alignItems: 'center',
  background: '#f9fafb',
  borderRadius: '8px',
  display: 'flex',
  gap: '8px',
  justifyContent: 'space-between',
  padding: '8px 12px',
})

const labelStyle = css({
  alignItems: 'center',
  cursor: 'pointer',
  display: 'flex',
  flex: '1 1 0',
  fontSize: '14px',
  gap: '12px',
  minWidth: 0,
})

const deleteButtonStyle = css({
  '&:hover, &:focus-visible': {
    background: '#fee2e2',
    color: '#b91c1c',
    outline: 'none',
  },
  background: 'transparent',
  border: 0,
  borderRadius: '6px',
  color: '#6b7280',
  cursor: 'pointer',
  fontSize: '12px',
  height: '28px',
  padding: '0 10px',
})

export const Todo = clientEntry('/assets/app/ui/todo.client.tsx#Todo', (handle: Handle<SerializableProps>) => {
  const state = { items: [] as Item[] }

  return () => {
    const remaining = state.items.filter((item) => !item.done).length

    return (
      <section mix={containerStyle}>
        <form
          mix={[
            formStyle,
            on('submit', (event) => {
              event.preventDefault()
              const form = event.currentTarget
              const data = new FormData(form)
              const raw = data.get('todo')
              const text = (Predicate.isString(raw) ? raw : '').trim()
              if (String.isEmpty(text)) {
                return
              }
              state.items = [...state.items, { done: false, id: crypto.randomUUID(), text }]
              void handle.update()
              form.reset()
            }),
          ]}
        >
          <input
            type='text'
            name='todo'
            aria-label='New todo'
            placeholder='What needs doing?'
            autoComplete='off'
            mix={inputStyle}
          />
          <button type='submit' mix={addButtonStyle}>
            Add
          </button>
        </form>
        <p mix={summaryStyle}>
          {Array.isArrayEmpty(state.items) ? 'No items yet.' : `${remaining} of ${state.items.length} remaining`}
        </p>
        <ul mix={listStyle}>
          {state.items.map((item) => (
            <li key={item.id} mix={itemStyle}>
              <label mix={labelStyle}>
                <input
                  type='checkbox'
                  aria-label={`Toggle ${item.text}`}
                  checked={item.done}
                  mix={on('change', () => {
                    state.items = state.items.map((it) => (it.id === item.id ? { ...it, done: !it.done } : it))
                    void handle.update()
                  })}
                />
                <span style={{ opacity: item.done ? 0.5 : 1, textDecoration: item.done ? 'line-through' : 'none' }}>
                  {item.text}
                </span>
              </label>
              <button
                type='button'
                aria-label={`Delete ${item.text}`}
                mix={[
                  deleteButtonStyle,
                  on('click', () => {
                    state.items = state.items.filter((it) => it.id !== item.id)
                    void handle.update()
                  }),
                ]}
              >
                Delete
              </button>
            </li>
          ))}
        </ul>
      </section>
    )
  }
})
