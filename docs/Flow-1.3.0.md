# NOVA OS 1.3.0 Flow — implementation, tests and release gates

**Status:** Published as a manual-install release on November 24, 2026. Automated Mac tests and universal signing checks passed; full hands-on GUI QA was not performed here.
**Repo:** `Ethan-cat-a/Nova-OS`, `feature/flow-1.3`.
**Platform:** Swift 5.9+, AppKit, WebKit, macOS 13+, universal Apple silicon/Intel.
**Previous stable version:** 1.2.0 Orbit (build 10); preserved for rollback.

## Feature scope and architecture

1. **OmniSearch** (Command-K): extend the existing native `OrbitCommandPaletteController`.
   `FlowOmniRank` provides deterministic local ranking of tabs, bookmarks,
   history, Spaces, and browser commands. Accept an explicit URL or arbitrary
   text as a web search using the existing `NovaNavigation.resolve` route;
   do not send local browsing history to an external autocomplete service.
   Limit UI results to seven.
2. **Spaces**: `FlowState`/`FlowStore` serialize up to 8 named workspaces
   and 40 tabs per workspace under `NovaOS.FlowSpaces.v1`.
   Only the active Space owns live WKWebViews; inactive Spaces hold URL/search
   and tab metadata, which are loaded lazily upon switching. The first launch
   after upgrading imports the prior `NovaOS.savedSession.v1` into My Space.
   The original session is also written as an extra rollback fallback.
   Tab snapshots contain IDs, titles, kind, URL/query and pinned status;
   neither page contents nor screenshots are persisted.
3. **Visual Tab Gallery** (Command-Shift-G): `FlowGalleryController`
   shows live, in-memory WKWebView snapshots for loaded pages.
   Unloaded pages show icons without generating requests. Selecting a card
   activates its corresponding tab. Gallery state is not persisted.
4. **Pinned and reorderable tabs**: `FlowDraggableTabButton` begins native
   Cocoa drag sessions with a tab UUID; `FrostTabStackView` handles drops.
   Pinned tabs form a stable group at the start of the strip; drag/drop
   cannot inadvertently cross the pin boundary. Context menu provides
   Pin/Unpin and Move Left/Right for accessibility and keyboard alternatives.
   Ordering is saved in each Space and restored after launch.
5. **Focus Reader** (Command-Shift-R): locally extracts text from the current
   http(s) WebKit page using read-only DOM access, then displays plain
   selectable text in a separate native reader window, with font sizing.
   No AI calls, arbitrary HTML execution, network calls, or persistent
   extracted content. The original page and history remain unchanged.
   Pages lacking sufficient article text show an explicit explanatory message.

## Files changed / added

| File | Implementation |
| --- | --- |
| `Sources/FlowState.swift` | Codable tab/Space snapshots; normalization, quotas, safety checks, pinned ordering, local rank |
| `Sources/FlowBrowserUI.swift` | Native tab drag source; visual gallery with WK snapshots; standalone plain-text reader |
| `Sources/NovaOSApp.swift` | Workspace lifecycle, legacy migration, tab strip integration, menu/shortcuts, OmniSearch, reader extraction |
| `Sources/OrbitBrowserTools.swift` | Reuses existing command palette/Find in Page; no destructive replacement |
| `Package.swift` | Registers both Flow sources in executable target and existing test suite |
| `Tests/NovaOSTests/FlowStateTests.swift` | Persistence, invalid URLs, ordering/pinning, corrupted data, ranking tests |
| `Info.plist` | Development version 1.3.0 / build 11; **branch only until release** |
| `.github/workflows/verify-macos.yml` | Mac CI tests, universal installer build, version/signature verification and short-lived beta artifact |
| `README.md` | Development status and beta feature list; stable 1.2.0 download unchanged |
| `docs/Flow-1.3.0.md` | Architecture and release checklist |

## Automated verification

- `swift test --disable-sandbox` with navigation and Flow unit tests.
- `NOVA_INSTALLER_ONLY=1 ./build.sh` on `macos-15` for arm64/x86_64.
- Verify installed bundle reports `CFBundleShortVersionString = 1.3.0`,
  that the package exists, and `codesign --verify --deep --strict` passes.
- Save the ad-hoc-signed beta installer as a short-lived workflow artifact;
  do not tag, notarize, or advertise it as an automatic update.

## Manual QA matrix (release blocker until completed)

- **Upgrade/migration:** install over 1.2.0; verify bookmarks, history,
  tabs and active tab restored. Kill mid-save and verify recovery.
- **Spaces:** create, rename, switch and delete Spaces; try empty, invalid and
  oversized saved state. Verify 8 Spaces / 40 tabs limit and persistence.
- **Tabs:** pin/unpin, drag left/right, reject cross-boundary drag, close and
  reopen, switch from OmniSearch, verify order after restart.
- **Gallery:** 1/10/30 tabs, loading and unloaded pages, failed snapshot,
  correct click target, no unexpected network traffic.
- **Reader:** articles, dynamic pages, inaccessible/empty pages, non-http
  pages and long text; verify original webpage stays open unchanged.
- **OmniSearch:** URLs, bare domains, search phrases, commands, bookmarks,
  history, duplicate titles, and Space switching. Escape/Return behavior.
- **Regression:** API `/api/search` all/images/videos/news, background
  downloads, permissions, back/forward, tab restoration, private data,
  light/dark mode, Reduce Motion, accessibility and memory over hours.
- **Platforms:** macOS 13 and most recent supported macOS, both Intel and
  Apple silicon. Confirm no native WebKit runtime exceptions.

## Release procedure

1. Open a PR from `feature/flow-1.3`, request review and require Mac CI green.
2. Run the manual QA matrix above with the beta installer on actual Macs.
3. Address all blockers in the feature branch and rerun CI.
4. Recover the **existing** Sparkle Ed25519 private key via GitHub Actions
   secrets, without committing it. Never rotate only the private signing
   key or publish unsigned Sparkle updates. Without the key, publish a
   **manual-only** installer and explicitly state this.
5. Merge after approval. The publish workflow triggers for `Info.plist`
   on main and creates `v1.3.0`; ensure it runs once and inspect the
   resulting installer before changing download links.
6. Update `site/index.html`, project README and NOVA Technologies product
   link *only after* the release artifact has passed smoke tests.
7. Preserve the `nova-os-browser.vercel.app` alias and the proxy rewrites
   for `/api/search` and `/api/research`; verify them immediately
   before/after deployment. Do not delete the legacy search backend yet.
8. Keep the 1.2.0 tag/package for rollback; if Flow fails, restore its
   installer link and halt the new distribution until fixed.

**Do not promise crash-free or automatic updates without the actual test
and signing evidence.**


### Post-audit fixes
- **Large-workspace data loss:** Flow now writes its full state atomically under Application Support, with a last-known-good backup and UserDefaults migration fallback. UserDefaults alone could silently reject a full 8 × 40 tab snapshot due to its 1 MB guard.
- **Cross-Space recovery:** recently closed tabs are kept in their originating Space for the current session.
- **Reader navigation race:** asynchronous text extraction does not display stale content after the source tab navigates away.
- **Search resilience:** native search first uses the project's stable Vercel domain, and falls back to the public NOVA OS alias if an endpoint is temporarily unavailable.
- **Save errors:** state-write failures are surfaced instead of discarded.
- **Tests:** full-quota save, corrupted primary restore, legacy migration.

## Public release verification

- GitHub Release: https://github.com/Ethan-cat-a/Nova-OS/releases/tag/v1.3.0
- Official installer: https://github.com/Ethan-cat-a/Nova-OS/releases/download/v1.3.0/Nova-OS-Installer.pkg
- macOS CI: all 20 tests passed and the universal x86_64/arm64 installer was built and ad-hoc signature verified.
- Sparkle auto-update feed remains unchanged because the original private key was absent from CI. Install manually; do not rotate the key.
- This release has not undergone full in-person graphical testing on physical Macs. Users should verify Spaces, drag/drop and Reader before relying on it for critical work.
