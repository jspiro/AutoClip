---
name: release
description: Use when bumping the AutoClip release version and publishing a new release — analyzes git history since the last tag to determine SemVer bump level, drafts release notes, updates Info.plist, commits, tags, and pushes to trigger CI.
---

# Release AutoClip

## Overview

Analyze commits since the last tag → decide SemVer bump → update `Info.plist` → commit + tag + push.
Pushing a `v*` tag triggers `.github/workflows/release.yml` (build, sign, notarize, GitHub Release, Sparkle appcast).

## Step 0 — Verify branch and sync state

```bash
# Must be on main
git branch --show-current

# Must be up-to-date with remote
git fetch origin
git status -sb   # should show "## main...origin/main" with no ahead/behind
```

**Stop and fix before continuing if:**
- Not on `main` — switch or merge first
- Behind `origin/main` — pull first (`git pull --ff-only`)
- Ahead with unpushed commits — push first (confirm with user)
- Uncommitted changes — stash or commit first

## Step 1 — Gather history since last release

```bash
# Find last tag
LAST=$(git describe --tags --abbrev=0)
echo "Last release: $LAST"

# Show commits since then
git log "$LAST"..HEAD --oneline
```

## Step 2 — Decide SemVer bump

| Change type | Bump |
|---|---|
| Breaking change, incompatible behavior | **major** |
| New feature, new setting, new menu item | **minor** |
| Bug fix, copy change, refactor, dependency update | **patch** |

Read each commit. Pick the highest-severity bump that applies.

## Step 3 — Draft release notes

Group commits into sections. Use plain English, not commit hashes.

```
### What's New
- <feature>

### Bug Fixes
- <fix>

### Other Changes
- <dep update, refactor, etc.>
```

Omit sections with no entries. Omit trivial commits (typo, whitespace).

Show the drafted notes to the user and confirm before proceeding.

## Step 4 — Compute new version

Read current values from `AutoClip/Info.plist`:
```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" AutoClip/Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" AutoClip/Info.plist
```

Apply bump to `CFBundleShortVersionString` (semver).
Increment `CFBundleVersion` by 1 (integer build number).

Show the user: current → new versions. Confirm before writing.

## Step 5 — Update Info.plist

```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString <NEW_VERSION>" AutoClip/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion <NEW_BUILD>" AutoClip/Info.plist
```

## Step 6 — Commit, tag, push

```bash
git add AutoClip/Info.plist
git commit -m "Bump to v<NEW_VERSION>"
git tag "v<NEW_VERSION>"
git push origin main --tags
```

**The tag push triggers CI.** The workflow enforces that the tag matches `CFBundleShortVersionString` — mismatches fail the build.

## Checklist

- [ ] Reviewed all commits since last tag
- [ ] SemVer bump level confirmed with user
- [ ] Release notes drafted and confirmed with user
- [ ] New version + build number confirmed with user
- [ ] `Info.plist` updated
- [ ] Committed on `main` (not a feature branch)
- [ ] Tag pushed — CI workflow triggered

## Common Mistakes

- **Tag/plist mismatch** — CI will fail. Always set plist first, then tag.
- **Forgetting `--tags`** — `git push origin main` alone does not push the tag.
- **Wrong branch** — releases must go from `main`.
