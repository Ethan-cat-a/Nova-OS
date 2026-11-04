# Nova OS for Mac

A small native macOS browser app for the Nova OS deployment at `https://nova-os-browser.vercel.app/`.

## What it does

- Opens the live Nova OS desktop in a native WebKit window.
- Provides multiple tabs, back/forward, reload, and a home button.
- Searches Google when text is entered in the address bar; URLs open in the current tab.
- Opens `target=_blank` links in a new in-app tab.
- Keeps website storage in the app's own persistent WebKit data store shared across tabs.
- Adds keyboard shortcuts: `⌘T` new tab, `⌘W` close tab, `⌘L` address/search, and `⌘R` reload.
- Supports links to external websites in the same browser window.

The app requires an internet connection and uses the current Vercel deployment. It does not bundle an offline copy of the website or its API routes.

## Build

Run `./build.sh`. The script builds a universal Apple Silicon and Intel app bundle at `../../outputs/Nova OS.app` and creates an ad hoc local code signature. The app has not been notarized for distribution.
