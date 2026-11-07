<div align="center">
  <img src="https://raw.githubusercontent.com/Ethan-cat-a/Nova-OS/main/assets/nova-icon.png" alt="Nova OS Apple-logo icon" width="160" />
  <h1>Nova OS for Mac</h1>
  <p><strong>Your Nova workspace, with the whole web one tab away.</strong></p>
  <p>
    <img src="https://img.shields.io/badge/macOS-13%2B-5967e8?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 13 or later" />
    <img src="https://img.shields.io/badge/Apple_Silicon-Intel-7654df?style=for-the-badge" alt="Apple Silicon and Intel" />
    <img src="https://img.shields.io/badge/version-1.1.5-172146?style=for-the-badge" alt="Version 1.1.5" />
  </p>
  <p>
    <a href="https://raw.githubusercontent.com/Ethan-cat-a/Nova-OS/main/downloads/Nova%20OS%20Installer.pkg"><strong>↓ Download Nova OS 1.1.5 for Mac</strong></a>
    &nbsp; · &nbsp;
    <a href="https://nova-os-browser.vercel.app/">Open the web version</a>
  </p>
</div>

---

Nova OS for Mac brings the live Nova OS site into a native macOS window and includes a built-in browser for everyday websites.

## A calmer way to browse

| Nova start page | Web search | Tabbed browsing |
| --- | --- | --- |
| A custom Nova dashboard for every new tab | Search with Nova from the address bar | Keep sites open together in Nova-themed tabs |
| Quick links to Nova OS, YouTube, GitHub, and Wikipedia | Website addresses automatically use HTTPS | Open pop-up links in a new tab |

Nova remembers up to 25 open tabs and restores them the next time you launch it. Inactive tabs wait to load until you select them, so reopening a session doesn't start every site at once. Save and remove bookmarks with the star in the address bar, then open them from the **Bookmarks** menu.

The browser uses macOS WebKit and includes back, forward, reload, and Nova OS home controls, a thin page-loading indicator, and familiar Mac shortcuts. It does not require Google Chrome. Nova Search includes All, Images, Videos, and News views and uses the Nova OS search service, which currently provides results from Bing.

Search results stay in memory for five minutes. Results for searches in open tabs are also saved with the session, so those pages can reopen immediately after you restart Nova. A new, uncached search still depends on the search service and your connection.

- `⌘T` — new tab
- `⌘W` — close tab
- `⌘L` — search or enter an address
- `⌘R` — reload

The **Nova OS** app menu includes the start page, new tab, and update controls. The **Bookmarks** menu lists saved sites and opens a bookmark manager to remove them.

## Automatic updates

Nova OS checks for updates daily and installs signed releases with Sparkle. Existing installations can choose **Nova OS → Check for Updates…** to get version 1.1.5; fresh installations can use the package below. Later signed releases install automatically.

## Install

1. Download **Nova OS 1.1.5 for Mac** above.
2. Open `Nova OS Installer.pkg` and follow the macOS Installer steps.
3. Find **Nova OS** in `/Applications`.

The app requires macOS 13 or later and an internet connection. It loads the live Vercel site, so that site and its APIs are not available offline. This package is ad-hoc signed and not notarized; macOS may ask you to approve it in **System Settings → Privacy & Security**.

## Build from source

On a Mac with Xcode Command Line Tools installed:

```sh
./build.sh
```

The script creates `dist/Nova OS.app`, `dist/Nova OS Installer.pkg`, a signed Sparkle update archive under `updates/`, and its appcast. The first build requires network access to resolve Sparkle.

The Sparkle signing private key lives in the ignored `.secrets/` directory and is never included in Git. Keep a secure backup of that key: future update archives must use the matching key. The matching public key is embedded in `Info.plist`.
