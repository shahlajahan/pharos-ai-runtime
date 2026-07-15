# Rules

- Do not implement future tasks.
- Do not create features that were not requested.
- Do not connect any external API.
- Do not consume OpenAI, Claude or Gemini tokens.
- Do not add dependencies unless required.
- One task per commit.
- Never skip tests.
- Never change project architecture.
- Keep solutions simple.
- Stop after successful commit.
The implementation agent must never modify:

- SPRINT.md
- TASK.md
- ROADMAP.md
- BACKLOG.md

unless explicitly requested.

The implementation agent must never decide what to work on next.

After a successful commit, stop immediately.

Planning is required only when the task introduces:

- a new subsystem
- architectural changes
- more than three modified files
- new public APIs

Otherwise, implement directly.