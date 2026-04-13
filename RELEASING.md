# RELEASING.md

This file is the release source of truth for OpenCue.

If you are updating versions, building a release candidate, packaging a DMG, or preparing a GitHub release, follow this file instead of guessing.

## Release Goal

Today OpenCue supports a source-first release flow:

- update version numbers
- build the app locally
- package a polished local DMG
- test the installed app from `/Applications`
- tag the release in git

This is not yet a notarized public distribution pipeline. If you need Developer ID signing and notarization later, add that as a new section here instead of replacing the current local workflow.

## Versioning Rules

OpenCue currently uses:

- `MARKETING_VERSION`: user-facing version, for example `1.0.0`
- `CURRENT_PROJECT_VERSION`: build number, for example `1`

Both live in [`OpenCue/OpenCue.xcodeproj/project.pbxproj`](./OpenCue/OpenCue.xcodeproj/project.pbxproj).

Current values:

- `MARKETING_VERSION = 1.0.0`
- `CURRENT_PROJECT_VERSION = 1`

Use these rules:

- bug fix only: `1.0.0 -> 1.0.1`
- new backward-compatible feature: `1.0.0 -> 1.1.0`
- breaking or major product change: `1.0.0 -> 2.0.0`
- every release build increments `CURRENT_PROJECT_VERSION` by `1`

## How To Update The Version

Preferred path:

1. Open `OpenCue.xcodeproj` in Xcode.
2. Select the `OpenCue` target.
3. In `General`, update:
   - `Version` -> `MARKETING_VERSION`
   - `Build` -> `CURRENT_PROJECT_VERSION`

You can also update the project file directly if needed, but Xcode is safer.

The About panel reads the version from the app bundle now, so you do not need to hardcode version strings in source code.

## Release Checklist

1. Make sure the branch is clean.
2. Update `MARKETING_VERSION`.
3. Increment `CURRENT_PROJECT_VERSION`.
4. Review `README.md` if user-facing behavior changed.
5. Review `doc/local-build-and-use.md` if install or test flow changed.
6. Build the app:

```bash
./scripts/build-local-release.sh
```

7. Package the DMG:

```bash
./scripts/make-local-dmg.sh
```

8. Test the actual installed app:
   - open the DMG
   - drag `OpenCue.app` into `Applications`
   - eject the DMG
   - launch `/Applications/OpenCue.app`
9. Validate the key product flows:
   - note creation and editing
   - play / pause / reset
   - scroll speed behavior
   - overlay controls
   - hotkeys
   - capture behavior with the specific recording tools you care about
10. Commit the version bump and release notes changes.
11. Create a git tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Update the tag to the real release version.

## Clean Install Test

Use this exact order when you want to test the DMG flow without polluting the result:

1. Quit `OpenCue`.
2. Delete `/Applications/OpenCue.app`.
3. Eject any mounted `OpenCue` DMG volume.
4. Open `build/OpenCue-local.dmg`.
5. Drag `OpenCue.app` into `Applications`.
6. Wait for the copy to finish.
7. Eject the DMG.
8. Launch `/Applications/OpenCue.app`.

Do not run the app from `/Volumes/OpenCue/OpenCue.app` when testing the installed experience.

## Output Artifacts

Local build output:

```text
build/local/DerivedData/Build/Products/Release/OpenCue.app
```

Local DMG output:

```text
build/OpenCue-local.dmg
```

## Agent Rules

If an agent is asked to do release work, it must:

1. Read this file first.
2. Keep `README.md`, `AGENTS.md`, and `CLAUDE.md` aligned with the actual release process.
3. Avoid claiming notarized public distribution unless that pipeline is actually implemented and tested.
4. Treat capture invisibility as a test requirement, not a blanket guarantee.
