# How to land mergeable PRs fast (without spamming)

## Rules that raise merge rate

1. **One concern per PR** — never mix docs + refactor + feature.
2. **Prefer &lt;50 lines** when possible.
3. **Match the repo’s style** — read 5 nearby files before editing.
4. **Claim the issue** if the project asks you to.
5. **Link `Fixes #123`** in the PR body.
6. **Pass CI locally** before opening the PR.
7. **Skip abandoned issues** (no maintainer reply in a long time, stale labels).

## Good first PR types

- Documentation typos / broken links / missing examples
- Test coverage for an existing function
- Accessibility labels
- Dependency bump only when the project welcomes it
- Small, clearly reproducible bugfixes

## Bad first PR types

- Large refactors
- New features nobody asked for
- Drive-by formatting of entire files
- AI-generated walls of unrelated changes

## Evidence Anthropic cares about

Search proof (replace username):

```
is:pr is:merged author:YOUR_USER -user:YOUR_USER merged:>=2025-07-22
```

Run `npm run count-prs` from this repo to print the count and search URL.
