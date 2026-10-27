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
- `upstreams/` — provenance locks, one per mirrored suite (ignored by Beskar)

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
count are recorded in [`upstreams/compound-engineering.lock`](upstreams/compound-engineering.lock).

The `compound-engineering` profile lists the whole suite. Enable it in a
workspace with `beskar repo enable compound-engineering`.

Upstream skills reference plugin machinery (slash commands, subagents)
that a plain Beskar library does not install; the workflow guidance in
each `SKILL.md` stands on its own.

License text: [`LICENSES/compound-engineering-plugin.txt`](LICENSES/compound-engineering-plugin.txt).

## ponytail

The [Ponytail](https://github.com/DietrichGebert/ponytail) suite by
Dietrich Gebert, MIT licensed, imported verbatim: lazy senior dev mode —
the best code is the code you never wrote. The `ponytail` profile lists
the whole suite; enable it with `beskar repo enable ponytail`.

License text: [`LICENSES/ponytail.txt`](LICENSES/ponytail.txt).

## superpowers

The [Superpowers](https://github.com/obra/superpowers) suite by Jesse
Vincent (obra), MIT licensed, imported verbatim: an agentic skills
framework and software development methodology — brainstorming,
writing and executing plans, test-driven development, systematic
debugging, code review, and more. The `superpowers` profile lists the
whole suite; enable it with `beskar repo enable superpowers`.

License text: [`LICENSES/superpowers.txt`](LICENSES/superpowers.txt).

## Syncing with upstream

`scripts/sync-suite.sh SUITE` mirrors a suite from its upstream into
this repository: it validates every skill against Beskar's rules (name
grammar, `SKILL.md`, no symlinks), replaces `skills/` and the license
verbatim, regenerates the suite's profile, writes
`upstreams/SUITE.lock`, and commits. Run it in a working copy of this
repository (the Beskar-managed clone works fine), then push. Per-suite
wrappers keep the common case short:

```sh
scripts/sync-ponytail.sh --push               # default ref: main
scripts/sync-superpowers.sh --push            # same, other suites
scripts/sync-compound-engineering.sh --push
```

Adding a suite means adding its skills, a `profiles/SUITE.bsk`, an
entry in `sync-suite.sh`, and a thin wrapper. The script prints the
exact `beskar remote` commands each machine needs afterwards; new
upstream skills must be tracked explicitly, dropped ones released from
the profile, and `beskar remote sync ventrion` picks the result up.
This is a repository script on purpose — Beskar itself stays pull-only.
