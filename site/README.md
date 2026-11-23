# NOVA OS — official Mac browser website

The official, standalone marketing/download website for **NOVA OS for macOS**.

- **Host:** Vercel (`nova-os` project)
- **Domain:** `nova-os-browser.vercel.app` (live, no external DNS required)
- **GitHub:** `Ethan-cat-a/Nova-OS/site`
- **Release download:** [NOVA OS 1.2.0 installer](https://github.com/Ethan-cat-a/Nova-OS/releases/download/v1.2.0/Nova-OS-Installer.pkg)

This site uses semantic HTML, CSS, and plain JavaScript. It includes accessible mobile navigation, light/dark/automatic appearance preferences, reduced-motion support, scroll reveals, an interactive **concept preview**, and real release/download links.

## Edit and deploy

Edit files in this directory and push to `main`; the linked Vercel project will deploy from the `site/` root directory.

The preview is illustrative, not a web implementation of the native WKWebView browser or a live AI service. It intentionally does not claim to perform actual AI searches.

## Updating for a new release

Update the installer link, release notes link, displayed version numbers, and README when the next macOS package is verified and published.

## Live search and legacy compatibility

The product preview's search form opens `search.html?q=...`, which renders live
results from `/api/search` for All, Images, Videos, and News. The page uses
safe DOM construction and validated HTTP(S) result links, with a Google fallback
if the provider is temporarily unavailable.

`vercel.json` forwards `/api/search` and `/api/research` to the retained
`nova-os-legacy.vercel.app` search service. **Do not delete or protect that
legacy deployment without replacing these routes.** NOVA OS macOS 1.2.0 also
uses the public `https://nova-os-browser.vercel.app/api/search` endpoint, so
keeping this route working is required for existing installed Mac clients.

When deploying to Vercel, ensure the public `nova-os-browser.vercel.app` alias
points to the latest verified release. That alias is not currently managed as
a project domain under the new `nova-os` project, so it may require an alias
update after production deployment until the domain is moved in Vercel.
