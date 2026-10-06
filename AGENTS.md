# Agentia CLI for AI Agents

<!-- agentia:managed:start -->

Use Agentia to manage Copado work items. Prefer registered Agentia MCP tools; otherwise use the CLI with `--json`.

Authentication must be configured before operational commands. Never print credentials, tokens, or unmasked environment variables.

## Copado workflow

`list → get → set → (implement & git commit) → test → publish → submit [--done|--deploy]`

Read records before changing them and use IDs returned by Copado. Do not skip `work set` before coding; use one story per feature branch. Keep the working tree clean for lifecycle commands, and confirm promotion/deployment intent before `done`.

## Agent Skills

Load exactly one copy of each applicable Agentia skill. Prefer the client-specific root when available (`.cursor/skills` in Cursor or `.claude/skills` in Claude); otherwise use `.agents/skills`.

- `agentia-cicd/SKILL.md`: Copado stories, commits, publish, submit, done, promotions, jobs, environments, pipelines, and data.
- `agentia-testing/SKILL.md`: Copado Robotic Testing operations.
- `agentia-ai/SKILL.md`: Copado AI operations.

Project rules in this file take precedence over managed skill guidance. Refresh managed skills with `agentia setup skills update`; do not hand-edit managed files.
<!-- agentia:managed:end -->
