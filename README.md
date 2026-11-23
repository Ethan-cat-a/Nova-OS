<div align="center">
  <img src="https://raw.githubusercontent.com/Ethan-cat-a/Nova-OS/main/assets/nova-icon.png" alt="Nova OS Apple-logo icon" width="160" />
  <h1>Nova OS for Mac</h1>
  <p><strong>Your Nova workspace, with the whole web one tab away.</strong></p>
  <p>
    <img src="https://img.shields.io/badge/macOS-13%2B-5967e8?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 13 or later" />
    <img src="https://img.shields.io/badge/Apple_Silicon-Intel-7654df?style=for-the-badge" alt="Apple Silicon and Intel" />
    <img src="https://img.shields.io/badge/version-1.2.0-172146?style=for-the-badge" alt="Version 1.1.7" />
  </p>
  <p>
    <a href="https://github.com/Ethan-cat-a/Nova-OS/releases/download/v1.2.0/Nova-OS-Installer.pkg"><strong>↓ Download Nova OS 1.2.0 Orbit for Mac</strong></a>
    &nbsp; · &nbsp;
    <a href="https://nova-os-browser.vercel.app/">Open the web version</a>
    &nbsp; · &nbsp;
    <a href="https://nova-browser-frost.vercel.app/">NOVA Frost website</a>
  </p>
</div>

---

Nova OS for Mac brings the live Nova OS site into a native macOS window and includes a built-in browser for everyday websites.

## NOVA Orbit — new in 1.2.0

Orbit adds the Command-K palette for tabs, bookmarks, history and actions; WebKit Find in Page
(Command-F); Command-Shift-T tab recovery; and Command-1 through Command-9 tab switching.
AI Overviews can be disabled from the app menu, and the Nova Research message handler
is now correctly registered for search results. The new-tab dashboard uses the orbital-star
brand.

Orbit was compiled for Apple silicon and Intel and its navigation tests pass.
Sparkle requires the original Ed25519 signing key; without it, installation is manual.
Private windows and pinned/drag-reordered tabs remain future improvements.

## Nova Frost — new in 1.1.7

The new macOS appearance follows system Light and Dark Mode. Native translucent toolbar surfaces, refined tab selection, an updated search page, and a quieter new-tab dashboard give Nova OS a more Apple-inspired look.

## A calmer way to browse

| Nova start page | Web search | Tabbed browsing |
| --- | --- | --- |
| A custom Nova dashboard for every new tab | Search with Nova from the address bar | Keep sites open together in Nova-themed tabs |
| Quick links to Nova OS, YouTube, GitHub, and Wikipedia | Website addresses automatically use HTTPS | Open pop-up links in a new tab |

Nova remembers up to 25 open tabs and restores them the next time you launch it. Inactive tabs wait to load until you select them, so reopening a session doesn't start every site at once. Save and remove bookmarks with the star in the address bar, then open them from the **Bookmarks** menu.

The address bar suggests recent pages, searches, and bookmarks as you type. The **History** menu keeps the 100 most recent pages and searches on this Mac; clear it at any time from that menu.

The browser uses macOS WebKit and includes back, forward, reload, and Nova OS home controls, a thin page-loading indicator, and familiar Mac shortcuts. It does not require Google Chrome. Nova Search includes All, Images, Videos, and News views and uses the Nova OS search service, which currently provides results from Bing.

All-results searches include a Nova AI Overview with source links and a Google results link. Nova sends the search topic and up to five result snippets to the Nova AI service to create the overview. The **Downloads** button shows progress, opens completed files in Finder, and keeps them in your Downloads folder.

Search results stay in memory for five minutes. Results for searches in open tabs are also saved with the session, so those pages can reopen immediately after you restart Nova. A new, uncached search still depends on the search service and your connection.

- `⌘T` — new tab
- `⌘W` — close tab
- `⌘L` — search or enter an address
- `⌘R` — reload

The **Nova OS** app menu includes the start page, new tab, and update controls. The **Bookmarks** menu lists saved sites and opens a bookmark manager to remove them.

## Automatic updates

**Nova OS 1.2.0 requires manual installation unless the existing Sparkle signing key is configured for the release build.** The last signed automatic-update feed advertises 1.1.6. If the private key remains unavailable in CI, install Orbit using the 1.2.0 package above instead; do not reuse or replace the public key to sign an incompatible feed.

## Install

1. Download **Nova OS 1.2.0 Orbit for Mac** above.
2. Open `Nova-OS-Installer.pkg` and follow the macOS Installer steps.
3. Find **Nova OS** in `/Applications`.

The app requires macOS 13 or later and an internet connection. It loads the live Vercel site, so that site and its APIs are not available offline. This package is ad-hoc signed and not notarized; macOS may ask you to approve it in **System Settings → Privacy & Security**.

## Build from source

On a Mac with Xcode Command Line Tools installed:

```sh
./build.sh
```

With the existing Sparkle private key at `.secrets/sparkle-ed25519.private`, `./build.sh` creates `dist/Nova OS.app`, `dist/Nova-OS-Installer.pkg`, a signed update archive under `updates/`, and its appcast. To create a standalone installer without the Sparkle key, run `NOVA_INSTALLER_ONLY=1 ./build.sh` (no automatic-update package will be created). The first build requires network access to resolve Sparkle.

The Sparkle signing private key lives in the ignored `.secrets/` directory and is never included in Git. Keep a secure backup of that key: future update archives must use the matching key. The matching public key is embedded in `Info.plist`.
