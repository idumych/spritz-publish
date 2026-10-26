---
name: spritz-publish
description: Publish or update one of idumych's GitHub apps (Haiku .hpkg) on Spritz Depot (spritzdepot.desktoponfire.com), the Haiku app catalog. Use when the user asks to publish, list, add or update an app on Spritz Depot / "the depot" / "the repo" / the house bàcaro, or to bump a pinned version there.
---

# Publishing to Spritz Depot

Spritz Depot doesn't host binaries. It indexes a small YAML file (a "cichéto") that points at the author's GitHub release. With an empty `bacaro`, Spritz Depot keeps the cichéto in its own house bàcaro, which is what we use.

The login token is baked in at `~/.claude/skills/spritz-publish/token` (a JWT, gitignored, never committed). `publish.sh` refuses to run once it has expired (exp 2026-11-01). If it has expired, ask the user to log in on the site, run `localStorage.spritz_token` in the browser console and save the result to that file. Never print the token or put it in a payload.

## Steps

1. **Gather facts with `gh`** for `idumych/<repo>`:
   - Repo description and license.
   - Latest release assets: is there an `*-x86_64.hpkg`?
   - `haiku-app.env`: `APP_NAME`, `APP_CMD`, `SUMMARY`, `VERSION`, `REVISION`, `DESKTOP_CATEGORIES`.
   - `packaging/description.txt`.
   - The README's screenshot paths.
   - An icon. Usually `packaging/appimage/icon.png`; otherwise look under `share/icons/`.
2. **Check the catalog** for name clashes: `curl -s "https://spritzdepot.desktoponfire.com/?q=<name>" | grep -oE 'href="/app/[^"]*"'`. If HaikuPorts already has a *different* app under the same name (e.g. `repo.haikuports.vlc`), leave `haikuports` empty. Filling it in sends users to the HaikuPorts build. Do tell the user when the hpkg package name collides.
3. **Write a payload JSON** in the scratchpad (fields below). Pick the source like this:
   - **`github-latest`** when the *latest* release has the hpkg. It is preferred because later releases appear automatically.
   - **`pinned`** when the latest release has no hpkg (e.g. Ringbinder's latest releases are AppImage or web only). Pin the newest release that has one. Get the sha256 from `gh release view <tag> --json assets` (`digest`).
4. **Dry run:** `~/.claude/skills/spritz-publish/publish.sh <payload.json> yaml`. You get HTTP 200 and the YAML. A 422 means the cichéto is invalid; the response includes the reason.
5. **Check the URLs:** every icon and screenshot URL, and pinned artifact URLs, should return 200 (`curl -sIL -o /dev/null -w '%{http_code}'`).
6. **Publish:** `publish.sh <payload.json> publish`. Expect `{"status":"live","app_url":"/app/<id>"}`. A pinned source can take a minute or more because the server fetches and hashes the file, so run it with a long timeout or in the background.
7. **Verify** the page at `https://spritzdepot.desktoponfire.com<app_url>` and report the link.

**Updating** an existing app: run `publish.sh x get <id>` to fetch the current cichéto. Then POST the full payload again with the same `id`; it replaces the old one. A `github-latest` app needs no update for new releases.

## Payload (POST body, all strings unless noted)

```json
{
  "id": "io.github.idumych.<app>",
  "name": "<App>",
  "summary": "one line",
  "description": "paragraphs separated by \n\n",
  "bacaro": "",
  "homepage": "https://github.com/idumych/<repo>",
  "license": "MIT | GPL-2.0 | GPL-3.0 ...",
  "icon": "https://raw.githubusercontent.com/idumych/<repo>/main/<path>.png",
  "categories": "comma-separated",
  "author_name": "idumych", "author_contact": "https://github.com/idumych", "packager_name": "idumych",
  "haikuports": "",
  "screenshots": "raw URL\nraw URL",
  "version": "<VERSION>-<REVISION>",
  "kind": "hpkg",
  "source": "github-latest",
  "repo": "idumych/<repo>", "match": "<cmd>-*-{arch}.hpkg", "architectures": "x86_64", "prerelease": false
}
```

For `pinned`, drop `repo`, `match`, `architectures` and `prerelease`, and add:
`"source": "pinned", "artifacts": [{"arch": "x86_64", "url": "<release asset URL>", "sha256": "<hex>"}]`

- **IDs:** use `io.github.idumych.<lowercase app name, no hyphens>`. An ID is permanent, and the first publisher owns the prefix.
- **Categories:** audio, business, development, education, fonts, games, graphics, internetandnetwork, productivity, scienceandmathematics, systemandutilities, video.

## Published so far

| App | ID | Source |
|---|---|---|
| VLC Reborn | `io.github.idumych.vlcreborn` | github-latest |
| Sheath | `io.github.idumych.sheath` | github-latest |
| Folio | `io.github.idumych.folio` | github-latest |
| Ringbinder | `io.github.idumych.ringbinder` | pinned to v1.1.0 hpkg, since later releases have no hpkg |
