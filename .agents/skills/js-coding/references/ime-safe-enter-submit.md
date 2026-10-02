# IME-safe Enter Submission

> Document type: decision guidance and official upstream source routing, not a local copy of the upstream implementation guide.

Read when implementing custom Enter-to-submit behavior in a browser text editor or fixing submission during Japanese, Chinese, or Korean IME conversion.
This applies across frameworks, not only Remix.

## Decision boundary

Treat IME candidate confirmation and submission as different user intents.
A custom Enter handler must not submit partially composed text or interfere with conversion confirmation.
Keep an explicit submit button and the native form submission path; a keyboard shortcut is an additional interaction, not their replacement.
Do not add custom keyboard interception to an ordinary native single-line form solely to apply this guidance.

## Official source

Prefer the locally installed official `$modern-web-guidance` skill and retrieve its `ime-safe-enter-submit` guide.
If the skill is unavailable, fetch the [official guide's Markdown source at v0.0.186](https://raw.githubusercontent.com/GoogleChrome/modern-web-guidance/v0.0.186/skills/modern-web-guidance/guides/forms/ime-safe-enter-submit.md) directly.
The [official skill entry point](https://github.com/GoogleChrome/modern-web-guidance/blob/v0.0.186/skills/modern-web-guidance/SKILL.md) documents how to retrieve guides when installed.

Use the guide to select an implementation for the project's actual browser and input-method support requirements.
The pinned guide is a reproducible reference, not a promise that compatibility advice stays current.
Consult current browser documentation and verify the target environments before adopting or removing a workaround.

## Compatibility and acceptance

- Do not assume `isComposing` alone covers every target browser's confirming Enter event ordering.
  [KeyboardEvent.isComposing](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/isComposing) describes composition-session state, not submission intent.
- Treat the upstream `keyCode === 229` fallback as a targeted compatibility exception involving a deprecated API, not a general keyboard-handling pattern.
- Treat the upstream timestamp window as a heuristic, not a universal 50 ms invariant.
  Review whether it could suppress a legitimate Enter immediately after confirmation before choosing it.
- Verify normal Enter submission, IME confirmation without submission, the configured newline shortcut such as Shift+Enter, and explicit button submission.
  Confirm that conversion itself still completes normally.
- Synthetic keyboard and composition events can exercise branches but cannot establish real browser/OS/IME event ordering.
  Verify with actual target input methods and browsers, including Safari when supported, and report any unverified combinations rather than claiming full IME coverage.
