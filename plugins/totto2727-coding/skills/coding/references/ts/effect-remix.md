# Effect + Remix Integration Patterns

Related skills: [effect-layer](./effect-layer.md), [effect-runtime](./effect-runtime.md)

## Client Event Boundary Pattern

`remix/ui` event handlers are browser boundaries. When a handler performs
Effectful work, the handler must execute exactly one whole workflow Effect.
The outer callback should only establish the boundary with `Effect.runPromise`;
form parsing, state mutation, `handle.update()`, HTTP calls, browser APIs,
navigation, and error recovery all belong inside the same `Effect.gen`.

```tsx
<form
  mix={on('submit', (event) => {
    // oxlint-disable-next-line rules/no-effect-runtime-run -- Client event boundary executes the whole submit workflow once.
    void Effect.runPromise(
      Effect.gen(function* () {
        event.preventDefault()

        const formData = new FormData(event.currentTarget)
        const email = formData.get('email')
        if (!Predicate.isString(email) || String.isEmpty(email)) {
          state.error = 'メールアドレスを入力してください'
          void handle.update()
          return yield* Effect.void
        }

        state.error = ''
        state.submitting = true
        void handle.update()

        const client = yield* HttpClient.HttpClient
        const response = yield* client.execute(
          HttpClientRequest.post('/api/sign-in', {
            body: HttpBody.jsonUnsafe({ email }),
          }),
        )
        if (response.status < 200 || response.status >= 300) {
          return yield* Effect.fail(new Error('サインインに失敗しました'))
        }

        window.location.href = '/app'
        return yield* Effect.void
      }).pipe(
        // oxlint-disable-next-line promise/prefer-await-to-then -- This is Effect.catch, not Promise.catch.
        Effect.catch(() =>
          Effect.sync(() => {
            state.error = 'サインインに失敗しました'
            state.submitting = false
            void handle.update()
          }),
        ),
        Effect.provide(FetchHttpClient.layer),
      ),
    )
  })}
>
```

### Key Rules

- Each `on(...)` handler must contain **0 or 1 runtime execution**:
  - 0 for purely synchronous local UI behavior.
  - 1 when it performs Effectful work such as HTTP, schema decoding,
    WebAuthn, storage, or navigation coupled to Effect results.
- Do not use `async` / `await` plus `try` / `catch` around a partial Effect.
  Use Effect's `catch` operator, `catchTags`, or `tapError` inside the same
  program. If oxlint confuses `Effect.catch` with Promise `.catch()`, add a
  targeted `promise/prefer-await-to-then` disable explaining that the operator
  is Effect, not Promise.
- Do not mutate component state before or after the Effect boundary. Initial
  loading state, validation errors, success state, failure state, and
  `handle.update()` calls are part of the workflow and belong inside
  `Effect.gen`.
- Do not navigate outside the Effect after awaiting a partial program.
  `window.location.href`, `history.pushState`, and Remix navigation helpers
  belong inside the workflow that proved navigation is allowed.
- Do not nest `Effect.gen` blocks to split one event workflow. Compose the
  operations in a single top-level `Effect.gen` and use helper functions only
  when they name reusable domain behavior.
- Browser APIs that return promises, such as WebAuthn
  `navigator.credentials.get/create`, should be wrapped with `Effect.promise`
  in the same workflow.
- `FetchHttpClient.layer` may be provided at the client event boundary when
  the component is the browser runtime boundary. Do not hide that provision
  inside domain service implementations.

## Forbidden Partial Boundary Shape

```tsx
<Button
  mix={on('click', async () => {
    state.submitting = true
    void handle.update()

    await Effect.runPromise(sendRequestOnly)

    // Navigation and final state are outside Effect: forbidden.
    window.location.href = '/app'
  })}
/>
```

The failure mode is the same as Hono endpoint boundaries: the important side
effects happen outside the program being typed, logged, recovered, and tested.
