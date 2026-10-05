---
name: gws
description: Read and change Google Drive, Docs, Sheets, and Slides files through the gws CLI, and discover its commands from the CLI itself
when_to_use: >-
  When a task reads or changes a Google Workspace file, or names gws, a Google Doc, a Sheet, a
  Slides deck, or a Drive file or folder.
---

# gws

`gws` is the Google Workspace CLI. It builds its commands from Google's API discovery documents,
so the installed CLI is the reference. Ask the CLI rather than your memory or this file.

## Before the first call

Run `gws auth status`, and read `user`, `token_valid`, and `scopes` from the JSON.

- Call only a service whose scope appears in `scopes`. The user may hold fewer scopes than the CLI
  has services.
- When `token_valid` is false, ask the user to run `! gws auth login`. It opens a browser, so never
  run it yourself.

## Discover the command

| Question | Command |
|---|---|
| Which services exist, and what each exit code means | `gws --help` |
| Which resources and helpers a service has | `gws <service> --help` |
| Which flags a method or helper takes | `gws <service> <resource> <method> --help` |
| Which parameters a method takes, and which it requires | `gws schema <service>.<resource>.<method>` |
| The shape of a request body | `gws schema <service>.<resource>.<method> --resolve-refs` |

A raw API call takes this shape. `--params` carries the path and query parameters, and `--json`
carries the request body:

```bash
gws <service> <resource> [sub-resource] <method> --params '<JSON>' --json '<JSON>'
```

A helper command starts with `+`, and `--help` labels it `[Helper]`. Use a helper when it covers
the job, because it takes plain flags rather than JSON.

## Rules

- **Confirm every write with the user first.** A write creates, changes, copies, shares, or
  deletes. That covers every `+write`, `+append`, and `+upload` helper. It also covers every
  `create`, `copy`, `update`, `batchUpdate`, `delete`, and `permissions` method.
- **Run a write with `--dry-run` first.** It prints the request without sending it. Show the user
  that request when you ask for confirmation.
- **Pass `fields` on every read.** It limits the response to what you need. Some methods fail
  without it, and their schema says so.
- **Add `trashed=false` to a Drive `q` query.** `drive files list` returns trashed files by default.
- **Wrap JSON and A1 ranges in single quotes.** The quotes keep `"` and `!` away from the shell.
- **Read stdout only.** The JSON result goes to stdout, and status lines such as the keyring
  backend go to stderr.
- **Never run `gws auth export`.** It prints the decrypted credentials.
- **Never run `gws generate-skills`.** It ignores `--help` and writes a skill directory per
  service into the working directory.
