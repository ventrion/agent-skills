# agent-skills

A Beskar skill collection: skills published for Beskar libraries to
track. Machines subscribe once and receive changes on every sync:

```sh
beskar remote add ventrion git@github.com:ventrion/agent-skills.git --yes
```

Layout follows the Beskar collection format (`docs/COLLECTIONS.md` in
[ventrion/beskar](https://github.com/ventrion/beskar)):

- `skills/` — one directory per skill, each with a `SKILL.md`
- `profiles/` — named setups that import on every sync
- `LICENSES/` — third-party license texts (ignored by Beskar)

## Editing this collection

This repository has no separate authoring checkout. Work in the clone
Beskar manages, commit, and push:

```sh
beskar remote where ventrion   # prints the clone path
cd "$(beskar remote where ventrion)" && git switch main
# edit, then:
git commit -am "..." && git push origin main
beskar remote sync ventrion    # on every machine, including this one
```

Sync fetches and detaches the clone at the pushed commit; uncommitted
changes make the checkout fail rather than being discarded.

## compound-engineering

The [Compound Engineering](https://github.com/everyinc/compound-engineering-plugin)
suite by Every Inc., MIT licensed, imported verbatim: skills that
structure agent work as a loop — brainstorm, plan, build, review,
capture learnings. The pinned upstream revision, import date and skill
count are recorded in [`upstream.lock`](upstream.lock).

The `compound-engineering` profile lists the whole suite. Enable it in a
workspace with `beskar repo enable compound-engineering`.

Upstream skills reference plugin machinery (slash commands, subagents)
that a plain Beskar library does not install; the workflow guidance in
each `SKILL.md` stands on its own.

License text: [`LICENSES/compound-engineering-plugin.txt`](LICENSES/compound-engineering-plugin.txt).

## Syncing with upstream

`scripts/sync-compound-engineering.sh` mirrors the suite from upstream
into this repository: it validates every skill against Beskar's rules
(name grammar, `SKILL.md`, no symlinks), replaces `skills/` and the
license verbatim, regenerates the `compound-engineering` profile, writes
`upstream.lock`, and commits. Run it in a working copy of this
repository (the Beskar-managed clone works fine), then push:

```sh
scripts/sync-compound-engineering.sh --push   # default ref: main
```

The script prints the exact `beskar remote` commands each machine needs
afterwards; new upstream skills must be tracked explicitly, dropped
ones released from the profile, and `beskar remote sync ventrion`
picks the result up. This is a repository script on purpose — Beskar
itself stays pull-only.
