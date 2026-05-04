import { clientEntry, css, on } from 'remix/ui'
import type { Handle, SerializableProps } from 'remix/ui'

interface TodoProps extends SerializableProps {}

interface Item {
  id: string
  text: string
  done: boolean
}

export const Todo = clientEntry(
  '/assets/app/ui/todo.client.tsx#Todo',
  function Todo(handle: Handle<TodoProps>) {
    let items: Item[] = []

    return () => {
      const remaining = items.filter((item) => !item.done).length

      return (
        <section mix={containerStyle}>
          <form
            mix={[
              formStyle,
              on('submit', (event) => {
                event.preventDefault()
                const form = event.currentTarget
                const data = new FormData(form)
                const text = String(data.get('todo') ?? '').trim()
                if (!text) return
                items = [...items, { id: crypto.randomUUID(), text, done: false }]
                handle.update()
                form.reset()
              }),
            ]}
          >
            <input type='text' name='todo' placeholder='What needs doing?' autoComplete='off' mix={inputStyle} />
            <button type='submit' mix={addButtonStyle}>
              Add
            </button>
          </form>
          <p mix={summaryStyle}>
            {items.length === 0 ? 'No items yet.' : `${remaining} of ${items.length} remaining`}
          </p>
          <ul mix={listStyle}>
            {items.map((item) => (
              <li key={item.id} mix={itemStyle}>
                <label mix={labelStyle}>
                  <input
                    type='checkbox'
                    checked={item.done}
                    mix={on('change', () => {
                      items = items.map((it) => (it.id === item.id ? { ...it, done: !it.done } : it))
                      handle.update()
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
                      items = items.filter((it) => it.id !== item.id)
                      handle.update()
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
  },
)

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
