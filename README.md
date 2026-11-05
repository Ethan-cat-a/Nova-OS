<div align="center">
  <h1>Nova OS for Mac</h1>
  <p><strong>Your Nova OS desktop, in a tabbed Mac browser.</strong></p>
  <p>
    <a href="https://nova-os-browser.vercel.app/">Open Nova OS</a>
    &nbsp;·&nbsp; Native macOS app
    &nbsp;·&nbsp; Apple Silicon + Intel
  </p>
  <p><a href="https://raw.githubusercontent.com/Ethan-cat-a/Nova-OS/main/downloads/Nova%20OS%20Installer.pkg"><strong>↓ Download for Mac</strong></a></p>
</div>

---

Nova OS for Mac wraps the live Nova OS site in a focused macOS window and adds a simple browser for the rest of the web. Searches go to Google, while websites open right in the app.

## At a glance

| Search | Browse | Stay organized |
| --- | --- | --- |
| Search Google from the address bar | Open websites in the current tab | Keep multiple pages open in tabs |
| Paste a URL to go straight there | Open new-window links in a new tab | Use familiar Mac keyboard shortcuts |

### Included

- Back, forward, reload, and Nova OS home controls
- Persistent website data shared between tabs
- `⌘T` new tab · `⌘W` close tab · `⌘L` search or address · `⌘R` reload
- Universal app for Apple Silicon and Intel Macs

## Install

Download **Nova OS Installer.pkg** using the button above, then open it and follow the macOS Installer steps. It places **Nova OS** in `/Applications`. You can also create the installer yourself with the build script below.

The packaged build requires macOS 13 or later and an internet connection. It loads the live Vercel site; the website and its API routes are not bundled for offline use.

## Build from source

On a Mac with Xcode Command Line Tools installed:

```sh
./build.sh
```

The script creates `dist/Nova OS.app` and `dist/Nova OS Installer.pkg`. To choose a different app bundle location, pass it as the first argument:

```sh
./build.sh "$PWD/outputs/Nova OS.app"
```

The app has an ad hoc signature; the installer is unsigned, and neither is notarized. macOS may ask you to approve installation or first launch in **System Settings → Privacy & Security**.
