import AppKit
import Sparkle
import WebKit

private enum NovaOS {
    static let homeURL = URL(string: "https://nova-os-browser.vercel.app/")!
    static let appName = "Nova OS"
    static let newTabHTML = #"""
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <link rel="preconnect" href="https://nova-os-browser.vercel.app" crossorigin>
      <title>New Tab — Nova OS</title>
      <style>
        :root { color-scheme: dark; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif; }
        * { box-sizing: border-box; }
        body { margin: 0; min-height: 100vh; color: #f4f6ff; background: radial-gradient(ellipse at 50% -25%, #4057a459, transparent 53%), radial-gradient(ellipse at 95% 90%, #7152a91c, transparent 40%), #0c1120; display: grid; place-items: center; padding: 42px 24px; }
        main { width: min(720px, 100%); text-align: center; margin-top: -3vh; }
        .brand { display: inline-flex; align-items: center; gap: 10px; color: #c9d1ec; font-size: 11px; font-weight: 700; letter-spacing: .16em; text-transform: uppercase; }
        .mark { width: 38px; height: 38px; border-radius: 13px; display: grid; place-items: center; color: white; background: linear-gradient(145deg,#85a9ff,#8164dc); box-shadow: 0 8px 26px #665ae344; font-size: 20px; }
        h1 { margin: 24px 0 8px; font-size: clamp(34px, 5vw, 48px); line-height: 1.1; letter-spacing: -.045em; font-weight: 680; }
        .subtitle { margin: 0; color: #a1acc8; font-size: 14px; }
        form { margin: 31px auto 0; height: 58px; display: flex; align-items: center; gap: 13px; padding: 0 7px 0 18px; max-width: 660px; border-radius: 18px; background: #1c253b; border: 1px solid #96a8d63d; box-shadow: 0 18px 42px #0003; }
        form:focus-within { border-color: #a39bff; box-shadow: 0 0 0 4px #8d83ff24, 0 18px 42px #0003; }
        .search-icon { color: #a5b1ed; font-size: 20px; }
        input { flex: 1; min-width: 0; border: 0; outline: 0; background: transparent; color: white; font: inherit; font-size: 16px; }
        input::placeholder { color: #9da4bd; }
        button { border: 0; border-radius: 12px; padding: 12px 17px; color: white; background: linear-gradient(135deg,#728fff,#8b6ce2); font: inherit; font-size: 13px; font-weight: 650; cursor: pointer; }
        button:hover { filter: brightness(1.12); }
        .section-label { margin: 38px 0 14px; color: #8793b1; font-size: 10px; letter-spacing: .16em; text-transform: uppercase; font-weight: 700; }
        .links { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; text-align: left; }
        .link { display:flex; align-items:center; gap:10px; padding:13px; min-width:0; border-radius:15px; color:#f2f4ff; text-decoration:none; background:#ffffff09; border:1px solid #d5dcff18; transition:background .18s,border-color .18s; }
        .link:hover { background:#ffffff12; border-color:#a9baff55; }
        .link-icon { flex:none; width:34px; height:34px; border-radius:11px; display:grid; place-items:center; background:#879ffb26; color:#b6c3ff; font-weight:750; font-size:15px; }
        .link strong { display:block; font-size:12px; font-weight:650; overflow:hidden; text-overflow:ellipsis; }
        .link small { display:block; margin-top:4px; color:#8e9ab8; font-size:10px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        footer { margin-top:40px; color:#7d89a5; font-size:11px; }
        @media (max-width: 560px) { .links { grid-template-columns: repeat(2, 1fr); } form { height: 56px; } button { padding: 11px 13px; } }
      </style>
    </head>
    <body>
      <main>
        <div class="brand"><span class="mark">✦</span> Nova OS</div>
        <h1>Explore with Nova.</h1>
        <p class="subtitle">Search the web, or pick up somewhere new.</p>
        <form id="search"><span class="search-icon">⌕</span><input id="query" aria-label="Search Nova or enter a website" autofocus placeholder="Search Nova or enter a website" autocomplete="off"><button type="submit">Search</button></form>
        <p class="section-label">Quick links</p>
        <div class="links">
          <a class="link" href="https://nova-os-browser.vercel.app/"><span class="link-icon">✦</span><span><strong>Nova OS</strong><small>Workspace</small></span></a>
          <a class="link" href="https://www.youtube.com/"><span class="link-icon">▶</span><span><strong>YouTube</strong><small>Watch</small></span></a>
          <a class="link" href="https://github.com/"><span class="link-icon">⌘</span><span><strong>GitHub</strong><small>Build</small></span></a>
          <a class="link" href="https://en.wikipedia.org/"><span class="link-icon">W</span><span><strong>Wikipedia</strong><small>Discover</small></span></a>
        </div>
        <footer>⌘ L to search · ⌘ T for another tab</footer>
      </main>
      <script>
        document.getElementById('search').addEventListener('submit', event => {
          event.preventDefault();
          const query = document.getElementById('query').value.trim();
          if (!query) return;
          window.webkit.messageHandlers.novaNavigate.postMessage(query);
        });
      </script>
    </body>
    </html>
    """#

    private static func javascriptLiteral(_ value: Any, fallback: String) -> String {
        let encoded = (try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? fallback
        return encoded.replacingOccurrences(of: "<", with: "\\u003c")
            .replacingOccurrences(of: ">", with: "\\u003e")
            .replacingOccurrences(of: "&", with: "\\u0026")
    }

    static func searchHTML(query: String, cached: [String: Any] = [:]) -> String {
        guard let queryMarker = searchPage.range(of: "__NOVA_QUERY__"),
              let cacheMarker = searchPage.range(of: "__NOVA_CACHED__"),
              queryMarker.upperBound <= cacheMarker.lowerBound else { return searchPage }
        return String(searchPage[..<queryMarker.lowerBound])
            + javascriptLiteral(query, fallback: "\"\"")
            + String(searchPage[queryMarker.upperBound..<cacheMarker.lowerBound])
            + javascriptLiteral(cached, fallback: "{}")
            + String(searchPage[cacheMarker.upperBound...])
    }

    static let searchPage = #"""
    <!doctype html>
    <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Nova Search</title><style>
    :root{color-scheme:dark;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif}
    *{box-sizing:border-box}body{margin:0;min-height:100vh;color:#f2f4ff;background:radial-gradient(ellipse at 95% -10%,#5443a035,transparent 38%),#0d1222}
    header{position:sticky;top:0;z-index:2;background:#11172a;border-bottom:1px solid #c7d2ff1a}
    .top{max-width:1180px;margin:auto;display:flex;align-items:center;gap:26px;padding:24px 34px 12px}.brand{display:flex;align-items:center;gap:10px;white-space:nowrap;font-size:13px;font-weight:760;letter-spacing:.13em;color:#e4e6ff}.mark{display:grid;place-items:center;width:34px;height:34px;border-radius:12px;color:#fff;font-size:20px;background:linear-gradient(140deg,#719eff,#9c6bea);box-shadow:0 7px 22px #776eff55}
    form{display:flex;align-items:center;gap:12px;flex:1;max-width:720px;padding:7px 8px 7px 18px;border:1px solid #aabaff30;border-radius:22px;background:#ffffff0d;box-shadow:0 8px 30px #0003}form:focus-within{border-color:#a499ff;box-shadow:0 0 0 3px #8b80ff22}
    .search-icon{color:#a8b3e5;font-size:19px}input{flex:1;min-width:0;color:#fff;background:transparent;border:0;outline:0;font:inherit;font-size:15px}button{font:inherit;cursor:pointer}.submit{border:0;border-radius:15px;padding:10px 17px;background:linear-gradient(120deg,#718dff,#956ce9);color:white;font-weight:650}
    nav{max-width:1180px;margin:auto;padding:0 34px 0 175px;display:flex;gap:8px;overflow:auto}nav button{position:relative;border:0;background:transparent;color:#9ba8c9;padding:15px 17px;font-size:13px;white-space:nowrap}nav button:hover{color:#fff}nav button[aria-selected="true"]{color:#c6baff;font-weight:650}nav button[aria-selected="true"]:after{content:"";position:absolute;height:3px;bottom:0;left:12px;right:12px;background:linear-gradient(90deg,#7ca8ff,#c294ff);border-radius:3px}
    main{max-width:1180px;margin:auto;padding:27px 34px 90px 175px}.summary{color:#8996b6;font-size:12px;margin:0 0 26px}#results{max-width:760px}.result{display:block;padding:0 0 26px;margin-bottom:22px;color:inherit;text-decoration:none;border-bottom:1px solid #b1bfff12}.result:hover .title{text-decoration:underline}
    .site{display:flex;align-items:center;gap:10px;color:#b7c1dc;font-size:12px;overflow-wrap:anywhere}.site-icon{display:grid;place-items:center;width:29px;height:29px;flex:none;border-radius:10px;color:#e1dcff;background:linear-gradient(140deg,#465987,#5e477d);font-weight:700}.title{font-size:20px;line-height:1.3;font-weight:600;margin:9px 0 6px;color:#adbdff}.snippet{color:#aab5ce;font-size:14px;line-height:1.55;margin:0}.status{color:#aab3ce;line-height:1.6;padding:16px 0}.provider{margin-top:30px;color:#7f89a7;font-size:11px}
    #results.grid{max-width:950px;display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:18px}#results.grid .result{padding:0;margin:0;border:0}#results.grid img{width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:16px;background:#ffffff0a}#results.grid .title{font-size:14px;line-height:1.4;margin:7px 0}#results.grid .site{font-size:11px}#results.grid .site-icon{width:22px;height:22px;border-radius:7px}
    #results.videos .result{display:flex;gap:18px;align-items:flex-start}#results.videos img{width:180px;aspect-ratio:16/9;object-fit:cover;border-radius:14px;background:#ffffff0a}#results.videos .details{flex:1;min-width:0}
    @media(max-width:650px){.top{padding:18px 16px 10px;gap:12px;flex-wrap:wrap}.brand{width:100%}form{width:100%}nav{padding:0 12px}nav button{padding:14px 12px}main{padding:24px 18px 60px}#results.videos img{width:110px}}
    </style></head><body><header><div class="top"><div class="brand"><span class="mark">✦</span>NOVA</div><form id="search"><span class="search-icon">⌕</span><input id="query" aria-label="Search Nova or enter a website" placeholder="Search Nova or enter a website"><button class="submit">Search</button></form></div>
    <nav aria-label="Search categories"><button type="button" data-type="all" aria-selected="true">✦ &nbsp;All</button><button type="button" data-type="images" aria-selected="false">▧ &nbsp;Images</button><button type="button" data-type="videos" aria-selected="false">▷ &nbsp;Videos</button><button type="button" data-type="news" aria-selected="false">▤ &nbsp;News</button></nav></header>
    <main><p class="summary" id="summary">Searching with Nova…</p><section id="results" aria-live="polite"></section><p class="provider" id="provider"></p></main>
    <script>
    const query=__NOVA_QUERY__, field=document.getElementById('query'), results=document.getElementById('results');field.value=query;
    document.getElementById('search').addEventListener('submit',event=>{event.preventDefault();const value=field.value.trim();if(value) window.webkit.messageHandlers.novaNavigate.postMessage(value)});
    const summary=document.getElementById('summary'),provider=document.getElementById('provider');let sequence=0,activeRequest=null;const searchCache=new Map(Object.entries(__NOVA_CACHED__));
    function status(message){results.replaceChildren();const p=document.createElement('p');p.className='status';p.textContent=message;results.append(p)}
    function webURL(value){try{const url=new URL(value);return ['https:','http:'].includes(url.protocol)?url:null}catch{return null}}
    function video(item){const raw=String(item.snippet||'').match(/\]\((https?:\/\/[^)\s]+)\)/);const candidate=webURL(raw?raw[1]:item.url);if(!candidate)return null;
      const host=candidate.hostname.toLowerCase(), direct=/(^|\.)(youtube\.com|youtu\.be|vimeo\.com|dailymotion\.com|tiktok\.com)$/.test(host), player=/(^|\.)bing\.com$/.test(host)&&candidate.pathname.startsWith('/videos/');
      if(!direct&&!player)return null;if(player)candidate.protocol='https:';
      const thumb=webURL(item.imageUrl||item.url);if(thumb&&/(^|\.)mm\.bing\.net$/.test(thumb.hostname))thumb.protocol='https:';
      return {url:candidate,thumb:thumb&&thumb.href!==candidate.href?thumb:null,title:String(item.title||'Video').replace(/^!\[Image\s*\d*:\s*/i,'')};}
    function addResult(item,type){const clip=type==='videos'?video(item):null,url=type==='videos'?clip?.url:webURL(item.url);if(!url)return false;
      const image=type==='images'?webURL(item.imageUrl):(clip?.thumb||null);if(type==='images'&&!image)return false;
      const link=document.createElement('a');link.className='result';link.href=url.href;
      if(image){const img=document.createElement('img');img.src=image.href;img.alt='';img.loading='lazy';img.referrerPolicy='no-referrer';link.append(img)}
      const details=document.createElement('div');details.className='details';const site=document.createElement('div');site.className='site';
      const icon=document.createElement('span');icon.className='site-icon';icon.textContent=url.hostname.replace(/^www\./,'').charAt(0).toUpperCase();
      const host=document.createElement('span');host.textContent=url.hostname;site.append(icon,host);
      const title=document.createElement('div');title.className='title';title.textContent=clip?.title||item.title||url.hostname;
      const snippet=document.createElement('p');snippet.className='snippet';snippet.textContent=type==='videos'?'':String(item.snippet||'').replace(/\[[^\]]+\]\([^)]+\)/g,'');
      details.append(site,title,snippet);link.append(details);results.append(link);return true;}
    async function search(type){const current=++sequence;if(activeRequest)activeRequest.abort();document.querySelectorAll('nav button').forEach(button=>button.setAttribute('aria-selected',String(button.dataset.type===type)));
      results.className=type==='images'?'grid':type==='videos'?'videos':'';provider.textContent='';summary.textContent='Searching '+(type==='all'?'the web':type)+' for “'+query+'”…';status('Looking for results…');
      try{let data;const cached=searchCache.get(type);if(cached&&Date.now()-cached.time<300000){data=cached.data;activeRequest=null}else{activeRequest=new AbortController();const response=await fetch('https://nova-os-browser.vercel.app/api/search?q='+encodeURIComponent(query)+'&type='+encodeURIComponent(type),{cache:'no-store',signal:activeRequest.signal});if(!response.ok)throw new Error('Search unavailable');data=await response.json();if(current!==sequence)return;searchCache.set(type,{time:Date.now(),data});window.webkit?.messageHandlers?.novaCache?.postMessage({query,type,data});activeRequest=null}if(current!==sequence)return;
        results.replaceChildren();let count=0;for(const item of (Array.isArray(data.results)?data.results:[]))if(addResult(item,type))count++;
        summary.textContent=(count?count+' results':'No results')+' for “'+query+'”';if(!count)status('No '+(type==='all'?'web':type)+' results found. Try another search.');
        if(type==='videos'){const more=document.createElement('a');more.className='result';more.href='https://www.youtube.com/results?search_query='+encodeURIComponent(query);const label=document.createElement('span');label.className='title';label.textContent='Browse videos on YouTube ↗';more.append(label);results.append(more)}
        if(data.provider)provider.textContent='Results provided by '+data.provider;
      }catch(error){if(current===sequence&&error.name!=='AbortError'){activeRequest=null;summary.textContent='Search unavailable';status('Nova Search could not connect. Check your internet connection and try again.')}}}
    document.querySelectorAll('nav button').forEach(button=>button.addEventListener('click',()=>search(button.dataset.type)));search('all');
    </script></body></html>
    """#
}

@MainActor
@main
private struct NovaOSMacApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}

@MainActor
private final class BrowserTab {
    let id: UUID
    let webView: WKWebView
    let button: NSButton
    let closeButton: NSButton
    let itemView: NSStackView
    var progressObservation: NSKeyValueObservation?
    var titleObservation: NSKeyValueObservation?
    var isInternalPage = false
    var hasLoaded = false
    var sessionEntry: SessionEntry

    init(id: UUID, webView: WKWebView, button: NSButton, closeButton: NSButton, itemView: NSStackView, sessionEntry: SessionEntry) {
        self.id = id
        self.webView = webView
        self.button = button
        self.closeButton = closeButton
        self.itemView = itemView
        self.sessionEntry = sessionEntry
    }
}

private struct SessionEntry: Codable {
    enum Kind: String, Codable { case home, search, website }
    var kind: Kind
    var value: String?
    var cached: [SavedSearchResult] = []
}

private struct SavedSearchResult: Codable {
    var type: String
    var data: Data
    var savedAt: Date
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private struct SavedSession: Codable {
        var tabs: [SessionEntry]
        var selectedIndex: Int
    }
    private struct Bookmark: Codable {
        var id: UUID
        var title: String
        var url: String
    }
    private struct SearchKey: Hashable { let query: String; let type: String }
    private struct CachedSearch { let data: [String: Any]; let time: Date }
    private static let sessionDefaultsKey = "NovaOS.savedSession.v1"
    private static let bookmarksDefaultsKey = "NovaOS.bookmarks.v1"
    private var window: NSWindow!
    private var tabBar: NSStackView!
    private var contentHost: NSView!
    private var addressField: NSSearchField!
    private var progressIndicator: NSProgressIndicator!
    private var backButton: NSButton!
    private var forwardButton: NSButton!
    private var reloadButton: NSButton!
    private var bookmarkButton: NSButton!
    private var bookmarksMenu: NSMenu!
    private var tabs: [BrowserTab] = []
    private var selectedTabID: UUID?
    private var updaterController: SPUStandardUpdaterController!
    private var recentSearches: [SearchKey: CachedSearch] = [:]
    private var bookmarks: [Bookmark] = []
    private var pendingSessionSave: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        loadBookmarks()
        configureMenu()
        createWindow()
        restoreSession()
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveSession()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func createWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1360, height: 860),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = NovaOS.appName
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(srgbRed: 0.055, green: 0.065, blue: 0.13, alpha: 1)
        window.minSize = NSSize(width: 820, height: 600)
        window.center()

        tabBar = NSStackView()
        tabBar.orientation = .horizontal
        tabBar.alignment = .centerY
        tabBar.distribution = .fill
        tabBar.spacing = 5
        tabBar.edgeInsets = NSEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)

        let tabScrollView = NSScrollView()
        tabScrollView.translatesAutoresizingMaskIntoConstraints = false
        tabScrollView.drawsBackground = false
        tabScrollView.hasHorizontalScroller = true
        tabScrollView.hasVerticalScroller = false
        tabScrollView.borderType = .noBorder

        let newTabButton = makeSymbolButton("plus", tooltip: "New Tab", action: #selector(newTab))
        let tabStrip = NSView()
        tabStrip.translatesAutoresizingMaskIntoConstraints = false
        tabStrip.wantsLayer = true
        tabStrip.layer?.backgroundColor = NSColor(srgbRed: 0.075, green: 0.085, blue: 0.155, alpha: 1).cgColor
        tabStrip.addSubview(tabScrollView)
        tabBar.addArrangedSubview(newTabButton)
        NSLayoutConstraint.activate([
            tabScrollView.leadingAnchor.constraint(equalTo: tabStrip.leadingAnchor, constant: 8),
            tabScrollView.trailingAnchor.constraint(equalTo: tabStrip.trailingAnchor, constant: -8),
            tabScrollView.centerYAnchor.constraint(equalTo: tabStrip.centerYAnchor),
            tabScrollView.heightAnchor.constraint(equalToConstant: 34),
            tabStrip.heightAnchor.constraint(equalToConstant: 40)
        ])

        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabScrollView.documentView = tabBar
        tabBar.heightAnchor.constraint(equalTo: tabScrollView.contentView.heightAnchor).isActive = true

        let navigationBar = makeNavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        let chrome = NSView()
        chrome.wantsLayer = true
        chrome.layer?.backgroundColor = NSColor(srgbRed: 0.095, green: 0.105, blue: 0.18, alpha: 1).cgColor
        chrome.translatesAutoresizingMaskIntoConstraints = false
        chrome.addSubview(tabStrip)
        chrome.addSubview(navigationBar)
        NSLayoutConstraint.activate([
            tabStrip.leadingAnchor.constraint(equalTo: chrome.leadingAnchor),
            tabStrip.trailingAnchor.constraint(equalTo: chrome.trailingAnchor),
            tabStrip.topAnchor.constraint(equalTo: chrome.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: chrome.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: chrome.trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: tabStrip.bottomAnchor),
            navigationBar.bottomAnchor.constraint(equalTo: chrome.bottomAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 54),
            chrome.heightAnchor.constraint(equalToConstant: 94)
        ])

        progressIndicator = NSProgressIndicator()
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 1
        progressIndicator.doubleValue = 0
        progressIndicator.isHidden = true

        contentHost = NSView()
        contentHost.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: NSRect(origin: .zero, size: window.contentLayoutRect.size))
        container.autoresizingMask = [.width, .height]
        container.addSubview(contentHost)
        container.addSubview(chrome)
        container.addSubview(progressIndicator)
        window.contentView = container
        NSLayoutConstraint.activate([
            chrome.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            chrome.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chrome.topAnchor.constraint(equalTo: container.topAnchor),
            contentHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentHost.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentHost.topAnchor.constraint(equalTo: chrome.bottomAnchor),
            contentHost.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            progressIndicator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            progressIndicator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            progressIndicator.topAnchor.constraint(equalTo: chrome.bottomAnchor),
            progressIndicator.heightAnchor.constraint(equalToConstant: 2)
        ])

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeNavigationBar() -> NSStackView {
        backButton = makeSymbolButton("chevron.backward", tooltip: "Back", action: #selector(goBack))
        forwardButton = makeSymbolButton("chevron.forward", tooltip: "Forward", action: #selector(goForward))
        reloadButton = makeSymbolButton("arrow.clockwise", tooltip: "Reload", action: #selector(reloadPage))
        let homeButton = makeSymbolButton("house", tooltip: "Nova OS Home", action: #selector(openHome))

        addressField = NSSearchField()
        addressField.translatesAutoresizingMaskIntoConstraints = false
        addressField.placeholderString = "Search Nova or enter a website"
        addressField.target = self
        addressField.action = #selector(navigateFromAddressField(_:))
        addressField.focusRingType = .default
        addressField.font = NSFont.systemFont(ofSize: 13.5, weight: .medium)
        addressField.toolTip = "Search Nova or enter a website address"
        addressField.isBordered = false
        addressField.drawsBackground = false
        bookmarkButton = makeSymbolButton("star", tooltip: "Bookmark this page", action: #selector(toggleCurrentBookmark))
        bookmarkButton.isEnabled = false
        let addressContainer = NSView()
        addressContainer.translatesAutoresizingMaskIntoConstraints = false
        addressContainer.wantsLayer = true
        addressContainer.layer?.cornerRadius = 11
        addressContainer.layer?.borderWidth = 1
        addressContainer.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor
        addressContainer.layer?.backgroundColor = NSColor(srgbRed: 0.14, green: 0.16, blue: 0.24, alpha: 1).cgColor
        addressContainer.addSubview(addressField)
        addressContainer.addSubview(bookmarkButton)
        NSLayoutConstraint.activate([
            addressContainer.heightAnchor.constraint(equalToConstant: 34),
            addressField.leadingAnchor.constraint(equalTo: addressContainer.leadingAnchor, constant: 8),
            addressField.trailingAnchor.constraint(equalTo: bookmarkButton.leadingAnchor, constant: -4),
            addressField.centerYAnchor.constraint(equalTo: addressContainer.centerYAnchor),
            addressField.heightAnchor.constraint(equalToConstant: 23),
            bookmarkButton.trailingAnchor.constraint(equalTo: addressContainer.trailingAnchor, constant: -4),
            bookmarkButton.centerYAnchor.constraint(equalTo: addressContainer.centerYAnchor)
        ])

        let brand = NSTextField(labelWithString: "✦  NOVA")
        brand.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        brand.textColor = NSColor(srgbRed: 0.75, green: 0.73, blue: 1, alpha: 1)
        brand.setContentHuggingPriority(.required, for: .horizontal)

        let bar = NSStackView(views: [brand, backButton, forwardButton, reloadButton, homeButton, addressContainer])
        bar.orientation = .horizontal
        bar.alignment = .centerY
        bar.distribution = .fill
        bar.spacing = 8
        bar.edgeInsets = NSEdgeInsets(top: 9, left: 14, bottom: 9, right: 14)
        addressContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return bar
    }

    private func makeSymbolButton(_ symbol: String, tooltip: String, action: Selector) -> NSButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
        let button = NSButton(image: image ?? NSImage(), target: self, action: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .toolbar
        button.isBordered = false
        button.contentTintColor = NSColor(srgbRed: 0.75, green: 0.78, blue: 0.96, alpha: 1)
        button.toolTip = tooltip
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return button
    }

    private func createTab(
        entry: SessionEntry = SessionEntry(kind: .home, value: nil),
        select: Bool = true,
        loadImmediately: Bool = true
    ) -> BrowserTab {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController.add(self, name: "novaNavigate")
        configuration.userContentController.add(self, name: "novaCache")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        let id = UUID()
        let tabButton = NSButton(title: "New Tab", target: self, action: #selector(selectTabFromButton(_:)))
        tabButton.identifier = NSUserInterfaceItemIdentifier(id.uuidString)
        tabButton.bezelStyle = .toolbar
        tabButton.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "Nova tab")
        tabButton.imagePosition = .imageLeading
        tabButton.alignment = .left
        tabButton.lineBreakMode = .byTruncatingTail
        tabButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tabButton.translatesAutoresizingMaskIntoConstraints = false
        tabButton.widthAnchor.constraint(equalToConstant: 178).isActive = true

        let closeButton = NSButton(title: "×", target: self, action: #selector(closeTabFromButton(_:)))
        closeButton.identifier = NSUserInterfaceItemIdentifier(id.uuidString)
        closeButton.bezelStyle = .inline
        closeButton.font = NSFont.systemFont(ofSize: 16)
        closeButton.setContentHuggingPriority(.required, for: .horizontal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.widthAnchor.constraint(equalToConstant: 24).isActive = true

        let itemView = NSStackView(views: [tabButton, closeButton])
        itemView.orientation = .horizontal
        itemView.alignment = .centerY
        itemView.distribution = .fill
        itemView.spacing = 2
        itemView.translatesAutoresizingMaskIntoConstraints = false
        itemView.widthAnchor.constraint(equalToConstant: 208).isActive = true
        itemView.heightAnchor.constraint(equalToConstant: 29).isActive = true

        let tab = BrowserTab(id: id, webView: webView, button: tabButton, closeButton: closeButton, itemView: itemView, sessionEntry: entry)
        tab.isInternalPage = entry.kind != .website
        tab.progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async { self?.updateProgress(for: webView) }
        }
        tab.titleObservation = webView.observe(\.title, options: [.new]) { [weak self, weak tab] _, _ in
            DispatchQueue.main.async {
                if let tab { self?.updateTab(tab) }
            }
        }
        itemView.identifier = NSUserInterfaceItemIdentifier(id.uuidString)
        itemView.wantsLayer = true
        tabs.append(tab)
        tabBar.insertArrangedSubview(itemView, at: max(0, tabBar.arrangedSubviews.count - 1))

        if select { selectTab(tab) }
        else if loadImmediately { loadTabIfNeeded(tab) }
        scheduleSessionSave()
        return tab
    }

    private func selectTab(_ tab: BrowserTab) {
        selectedTabID = tab.id
        loadTabIfNeeded(tab)
        contentHost.subviews.forEach { $0.removeFromSuperview() }
        tab.webView.translatesAutoresizingMaskIntoConstraints = false
        contentHost.addSubview(tab.webView)
        NSLayoutConstraint.activate([
            tab.webView.leadingAnchor.constraint(equalTo: contentHost.leadingAnchor),
            tab.webView.trailingAnchor.constraint(equalTo: contentHost.trailingAnchor),
            tab.webView.topAnchor.constraint(equalTo: contentHost.topAnchor),
            tab.webView.bottomAnchor.constraint(equalTo: contentHost.bottomAnchor)
        ])
        addressField.stringValue = displayAddress(for: tab.webView)
        progressIndicator.doubleValue = tab.webView.estimatedProgress
        progressIndicator.isHidden = !tab.webView.isLoading
        updateNavigationButtons()
        updateTab(tab)
        scheduleSessionSave()
    }

    private func loadTabIfNeeded(_ tab: BrowserTab) {
        guard !tab.hasLoaded else { return }
        tab.hasLoaded = true
        switch tab.sessionEntry.kind {
        case .home:
            tab.isInternalPage = true
            tab.webView.loadHTMLString(NovaOS.newTabHTML, baseURL: nil)
        case .search:
            let query = tab.sessionEntry.value ?? ""
            tab.isInternalPage = true
            tab.webView.loadHTMLString(NovaOS.searchHTML(query: query, cached: cachedResults(for: query)), baseURL: nil)
        case .website:
            guard let rawURL = tab.sessionEntry.value, let url = URL(string: rawURL),
                  ["https", "http"].contains(url.scheme?.lowercased() ?? "") else {
                tab.sessionEntry = SessionEntry(kind: .home, value: nil)
                tab.isInternalPage = true
                tab.webView.loadHTMLString(NovaOS.newTabHTML, baseURL: nil)
                return
            }
            tab.isInternalPage = false
            tab.webView.load(URLRequest(url: url))
        }
    }

    private var selectedTab: BrowserTab? {
        tabs.first { $0.id == selectedTabID }
    }

    private func tab(for webView: WKWebView) -> BrowserTab? {
        tabs.first { $0.webView === webView }
    }

    private func tab(id: String?) -> BrowserTab? {
        guard let id, let uuid = UUID(uuidString: id) else { return nil }
        return tabs.first { $0.id == uuid }
    }

    private func updateTab(_ tab: BrowserTab) {
        let pageTitle = tab.webView.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let host = tab.webView.url?.host
        let title = (pageTitle?.isEmpty == false ? pageTitle : nil) ?? host ?? "New Tab"
        let tabTitle = title == "New Tab — Nova OS" ? "New Tab" : title
        tab.button.title = tabTitle.count > 28 ? String(tabTitle.prefix(27)) + "…" : tabTitle
        tab.button.toolTip = tab.webView.url?.absoluteString ?? title
        if tab.id == selectedTabID {
            window.title = title == NovaOS.appName || title.hasSuffix(" — \(NovaOS.appName)") ? title : "\(title) — \(NovaOS.appName)"
            addressField.stringValue = displayAddress(for: tab.webView)
            updateNavigationButtons()
            updateBookmarkButton()
        }
        updateTabStyles()
    }

    private func displayAddress(for webView: WKWebView) -> String {
        guard let url = webView.url, url.scheme != "about" else { return "" }
        return url.absoluteString
    }

    private func updateNavigationButtons() {
        backButton?.isEnabled = selectedTab?.webView.canGoBack ?? false
        forwardButton?.isEnabled = selectedTab?.webView.canGoForward ?? false
        reloadButton?.image = NSImage(systemSymbolName: selectedTab?.webView.isLoading == true ? "xmark" : "arrow.clockwise", accessibilityDescription: "Reload")
    }

    private func updateTabStyles() {
        for tab in tabs {
            let selected = tab.id == selectedTabID
            tab.itemView.layer?.cornerRadius = 10
            tab.itemView.layer?.borderWidth = 1
            tab.itemView.layer?.borderColor = (selected
                ? NSColor(srgbRed: 0.62, green: 0.57, blue: 1, alpha: 0.55)
                : NSColor.white.withAlphaComponent(0.05)).cgColor
            tab.itemView.layer?.backgroundColor = (selected
                ? NSColor(srgbRed: 0.37, green: 0.32, blue: 0.67, alpha: 0.7)
                : NSColor.white.withAlphaComponent(0.045)).cgColor
            tab.button.font = NSFont.systemFont(ofSize: 12, weight: selected ? .semibold : .medium)
            tab.button.isBordered = false
            tab.button.contentTintColor = selected ? .white : NSColor(srgbRed: 0.72, green: 0.75, blue: 0.9, alpha: 1)
            tab.closeButton.contentTintColor = NSColor(srgbRed: 0.75, green: 0.76, blue: 0.9, alpha: 1)
        }
    }

    private func updateProgress(for webView: WKWebView) {
        guard let tab = tab(for: webView), tab.id == selectedTabID else { return }
        progressIndicator.doubleValue = webView.estimatedProgress
        progressIndicator.isHidden = !webView.isLoading
    }

    private func navigate(_ text: String, in tab: BrowserTab) {
        guard let destination = NovaNavigation.resolve(text) else { return }
        switch destination {
        case .search(let input):
            tab.sessionEntry = SessionEntry(kind: .search, value: input)
            tab.isInternalPage = true
            tab.webView.loadHTMLString(NovaOS.searchHTML(query: input, cached: cachedResults(for: input)), baseURL: nil)
        case .website(let url):
            tab.sessionEntry = SessionEntry(kind: .website, value: url.absoluteString)
            tab.isInternalPage = false
            if tab.id == selectedTabID { addressField.stringValue = url.absoluteString }
            tab.webView.load(URLRequest(url: url))
        }
        tab.hasLoaded = true
        scheduleSessionSave()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let webView = message.webView,
              let tab = tab(for: webView), tab.isInternalPage else { return }
        if message.name == "novaNavigate", let input = message.body as? String {
            navigate(input, in: tab)
        } else if message.name == "novaCache", let body = message.body as? [String: Any],
                  let query = body["query"] as? String, let type = body["type"] as? String,
                  let data = body["data"] as? [String: Any] {
            rememberResults(data, query: query, type: type)
            scheduleSessionSave()
        }
    }

    private func cachedResults(for query: String) -> [String: Any] {
        let now = Date()
        recentSearches = recentSearches.filter { now.timeIntervalSince($0.value.time) < 300 }
        var entries: [String: Any] = [:]
        for (key, value) in recentSearches where key.query == query {
            entries[key.type] = ["time": value.time.timeIntervalSince1970 * 1000, "data": value.data]
        }
        return entries
    }

    private func rememberResults(_ data: [String: Any], query: String, type: String) {
        guard !query.isEmpty, query.utf8.count <= 2048,
              ["all", "images", "videos", "news"].contains(type),
              let results = data["results"] as? [Any], !results.isEmpty,
              JSONSerialization.isValidJSONObject(data),
              let bytes = try? JSONSerialization.data(withJSONObject: data), bytes.count <= 256_000 else { return }
        let now = Date()
        recentSearches = recentSearches.filter { now.timeIntervalSince($0.value.time) < 300 }
        let key = SearchKey(query: query, type: type)
        if recentSearches.count >= 40, recentSearches[key] == nil,
           let oldest = recentSearches.min(by: { $0.value.time < $1.value.time })?.key {
            recentSearches.removeValue(forKey: oldest)
        }
        recentSearches[key] = CachedSearch(data: data, time: now)
    }

    private func restoreSession() {
        guard let data = UserDefaults.standard.data(forKey: Self.sessionDefaultsKey),
              let saved = try? JSONDecoder().decode(SavedSession.self, from: data), !saved.tabs.isEmpty else {
            _ = createTab()
            return
        }
        for originalEntry in saved.tabs {
            var entry = originalEntry
            switch entry.kind {
            case .home:
                entry.value = nil
                entry.cached = []
            case .search:
                guard let query = entry.value, !query.isEmpty, query.utf8.count <= 2048 else {
                    entry = SessionEntry(kind: .home, value: nil)
                    continue
                }
                entry.cached = entry.cached.filter { savedResult in
                    guard Date().timeIntervalSince(savedResult.savedAt) < 300,
                          ["all", "images", "videos", "news"].contains(savedResult.type),
                          savedResult.data.count <= 64_000,
                          let object = try? JSONSerialization.jsonObject(with: savedResult.data) as? [String: Any],
                          let results = object["results"] as? [Any], !results.isEmpty else { return false }
                    recentSearches[SearchKey(query: query, type: savedResult.type)] = CachedSearch(
                        data: object,
                        time: savedResult.savedAt
                    )
                    return true
                }
            case .website:
                if let rawURL = entry.value, let url = URL(string: rawURL),
                   ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
                    entry.value = url.absoluteString
                } else {
                    entry = SessionEntry(kind: .home, value: nil)
                }
                entry.cached = []
            }
            _ = createTab(entry: entry, select: false, loadImmediately: false)
        }
        guard !tabs.isEmpty else {
            _ = createTab()
            return
        }
        let active = tabs[min(max(saved.selectedIndex, 0), tabs.count - 1)]
        selectTab(active)
    }

    private func scheduleSessionSave() {
        pendingSessionSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveSession() }
        pendingSessionSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
    }

    private func saveSession() {
        pendingSessionSave?.cancel()
        pendingSessionSave = nil
        guard !tabs.isEmpty else { return }
        let selectedID = selectedTabID
        let selectedOriginalIndex = tabs.firstIndex { $0.id == selectedID } ?? 0
        let start = max(0, tabs.count - 25)
        var retained = Array(tabs.suffix(25))
        if selectedOriginalIndex < start {
            retained[0] = tabs[selectedOriginalIndex]
        }
        let selectedIndex = retained.firstIndex { $0.id == selectedID } ?? 0
        let entries = retained.map { tab -> SessionEntry in
            var entry = tab.sessionEntry
            entry.cached = []
            if entry.kind == .search, let query = entry.value {
                entry.cached = recentSearches.compactMap { key, value in
                    guard key.query == query,
                          Date().timeIntervalSince(value.time) < 300,
                          let bytes = try? JSONSerialization.data(withJSONObject: value.data),
                          bytes.count <= 64_000 else { return nil }
                    return SavedSearchResult(type: key.type, data: bytes, savedAt: value.time)
                }
            }
            return entry
        }
        let state = SavedSession(tabs: entries, selectedIndex: selectedIndex)
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: Self.sessionDefaultsKey)
    }

    private func configureMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let aboutItem = NSMenuItem(title: "About Nova OS", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        let updateItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        updateItem.target = updaterController
        appMenu.addItem(updateItem)
        let appNewTabItem = NSMenuItem(title: "New Tab", action: #selector(newTab), keyEquivalent: "t")
        appNewTabItem.target = self
        appMenu.addItem(appNewTabItem)
        let homeItem = NSMenuItem(title: "Open Nova OS Home", action: #selector(openHome), keyEquivalent: "")
        homeItem.target = self
        appMenu.addItem(homeItem)
        appMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Nova OS", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        let newTabItem = NSMenuItem(title: "New Tab", action: #selector(newTab), keyEquivalent: "t")
        newTabItem.target = self
        fileMenu.addItem(newTabItem)
        fileMenu.addItem(NSMenuItem(title: "Close Tab", action: #selector(closeSelectedTab), keyEquivalent: "w"))
        let reloadItem = NSMenuItem(title: "Reload", action: #selector(reloadPage), keyEquivalent: "r")
        reloadItem.target = self
        fileMenu.addItem(reloadItem)
        let focusItem = NSMenuItem(title: "Search or Enter Address", action: #selector(focusAddress), keyEquivalent: "l")
        focusItem.target = self
        fileMenu.addItem(focusItem)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        let bookmarksItem = NSMenuItem(title: "Bookmarks", action: nil, keyEquivalent: "")
        bookmarksMenu = NSMenu(title: "Bookmarks")
        bookmarksMenu.delegate = self
        bookmarksItem.submenu = bookmarksMenu
        mainMenu.addItem(bookmarksItem)

        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: NSSelectorFromString("undo:"), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: NSSelectorFromString("redo:"), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === bookmarksMenu else { return }
        menu.removeAllItems()
        let addItem = NSMenuItem(title: isCurrentPageBookmarked ? "Remove Bookmark" : "Bookmark This Page", action: #selector(toggleCurrentBookmark), keyEquivalent: "d")
        addItem.target = self
        addItem.isEnabled = currentBookmarkURL != nil
        menu.addItem(addItem)
        if !bookmarks.isEmpty {
            menu.addItem(.separator())
            for bookmark in bookmarks.reversed() {
                let item = NSMenuItem(title: bookmark.title, action: #selector(openBookmark(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = bookmark.url
                item.toolTip = bookmark.url
                menu.addItem(item)
            }
            menu.addItem(.separator())
            let manageItem = NSMenuItem(title: "Manage Bookmarks…", action: #selector(manageBookmarks), keyEquivalent: "")
            manageItem.target = self
            menu.addItem(manageItem)
        }
    }

    private var currentBookmarkURL: URL? {
        guard let tab = selectedTab, !tab.isInternalPage, let url = tab.webView.url,
              ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }

    private var isCurrentPageBookmarked: Bool {
        guard let url = currentBookmarkURL else { return false }
        return bookmarks.contains { $0.url == url.absoluteString }
    }

    private func updateBookmarkButton() {
        let url = currentBookmarkURL
        bookmarkButton?.isEnabled = url != nil
        bookmarkButton?.image = NSImage(
            systemSymbolName: isCurrentPageBookmarked ? "star.fill" : "star",
            accessibilityDescription: isCurrentPageBookmarked ? "Remove bookmark" : "Bookmark this page"
        )
        bookmarkButton?.toolTip = isCurrentPageBookmarked ? "Remove bookmark" : "Bookmark this page"
        bookmarkButton?.contentTintColor = isCurrentPageBookmarked
            ? NSColor(srgbRed: 0.93, green: 0.79, blue: 1, alpha: 1)
            : NSColor(srgbRed: 0.75, green: 0.78, blue: 0.96, alpha: 1)
    }

    @objc private func toggleCurrentBookmark() {
        guard let tab = selectedTab, let url = currentBookmarkURL else { return }
        if let existing = bookmarks.firstIndex(where: { $0.url == url.absoluteString }) {
            bookmarks.remove(at: existing)
        } else {
            let title = tab.webView.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            bookmarks.append(Bookmark(
                id: UUID(),
                title: title.flatMap { $0.isEmpty ? nil : $0 } ?? url.host ?? url.absoluteString,
                url: url.absoluteString
            ))
        }
        saveBookmarks()
        updateBookmarkButton()
    }

    @objc private func openBookmark(_ sender: NSMenuItem) {
        guard let rawURL = sender.representedObject as? String, let tab = selectedTab else { return }
        navigate(rawURL, in: tab)
    }

    @objc private func manageBookmarks() {
        guard !bookmarks.isEmpty else { return }
        let chooser = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 320, height: 28), pullsDown: false)
        for bookmark in bookmarks {
            chooser.addItem(withTitle: bookmark.title)
            chooser.lastItem?.representedObject = bookmark.id.uuidString
        }
        let alert = NSAlert()
        alert.messageText = "Manage Nova Bookmarks"
        alert.informativeText = "Choose a bookmark to remove."
        alert.accessoryView = chooser
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn,
              let id = chooser.selectedItem?.representedObject as? String,
              let index = bookmarks.firstIndex(where: { $0.id.uuidString == id }) else { return }
        bookmarks.remove(at: index)
        saveBookmarks()
        updateBookmarkButton()
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarksDefaultsKey),
              let saved = try? JSONDecoder().decode([Bookmark].self, from: data) else { return }
        bookmarks = saved.filter { bookmark in
            guard let url = URL(string: bookmark.url) else { return false }
            return ["https", "http"].contains(url.scheme?.lowercased() ?? "")
        }
    }

    private func saveBookmarks() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        UserDefaults.standard.set(data, forKey: Self.bookmarksDefaultsKey)
    }

    @objc private func newTab() {
        _ = createTab()
    }

    @objc private func selectTabFromButton(_ sender: NSButton) {
        guard let tab = tab(id: sender.identifier?.rawValue) else { return }
        selectTab(tab)
    }

    @objc private func closeTabFromButton(_ sender: NSButton) {
        closeTab(id: sender.identifier?.rawValue)
    }

    @objc private func closeSelectedTab() {
        closeTab(id: selectedTabID?.uuidString)
    }

    private func closeTab(id: String?) {
        guard let tab = tab(id: id), let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        guard tabs.count > 1 else {
            tab.sessionEntry = SessionEntry(kind: .home, value: nil)
            tab.isInternalPage = true
            tab.hasLoaded = true
            tab.webView.loadHTMLString(NovaOS.newTabHTML, baseURL: nil)
            scheduleSessionSave()
            return
        }

        let wasSelected = tab.id == selectedTabID
        tab.itemView.removeFromSuperview()
        tab.webView.stopLoading()
        tabs.remove(at: index)
        if wasSelected {
            let nextTab = tabs[min(index, tabs.count - 1)]
            selectTab(nextTab)
        }
        scheduleSessionSave()
    }

    @objc private func goBack() {
        selectedTab?.webView.goBack()
    }

    @objc private func goForward() {
        selectedTab?.webView.goForward()
    }

    @objc private func reloadPage() {
        guard let webView = selectedTab?.webView else { return }
        if webView.isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
    }

    @objc private func openHome() {
        guard let tab = selectedTab else { return }
        tab.webView.load(URLRequest(url: NovaOS.homeURL))
    }

    @objc private func navigateFromAddressField(_ sender: NSSearchField) {
        guard let tab = selectedTab else { return }
        navigate(sender.stringValue, in: tab)
    }

    @objc private func focusAddress() {
        window.makeFirstResponder(addressField)
        addressField.selectText(nil)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: NovaOS.appName,
            .applicationVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            .version: "Mac app"
        ])
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateNavigationButtons()
        if let tab = tab(for: webView), tab.id == selectedTabID {
            reloadButton?.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Stop Loading")
            progressIndicator.alphaValue = 1
            progressIndicator.doubleValue = max(webView.estimatedProgress, 0.08)
            progressIndicator.isHidden = false
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let tab = tab(for: webView) else { return }
        if !tab.isInternalPage, let url = webView.url,
           ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
            tab.sessionEntry = SessionEntry(kind: .website, value: url.absoluteString)
            scheduleSessionSave()
        }
        updateTab(tab)
        updateNavigationButtons()
        if tab.id == selectedTabID {
            progressIndicator.doubleValue = 1
            progressIndicator.alphaValue = 1
            progressIndicator.isHidden = true
            progressIndicator.doubleValue = 0
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateNavigationButtons()
        if tab(for: webView)?.id == selectedTabID { progressIndicator.isHidden = true }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateNavigationButtons()
        if tab(for: webView)?.id == selectedTabID { progressIndicator.isHidden = true }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "http" || scheme == "https" {
            if navigationAction.targetFrame?.isMainFrame != false, let tab = tab(for: webView) {
                tab.isInternalPage = false
                tab.sessionEntry = SessionEntry(kind: .website, value: url.absoluteString)
                scheduleSessionSave()
            }
            decisionHandler(.allow)
        } else if scheme == "about" && url.absoluteString == "about:blank" {
            if navigationAction.targetFrame?.isMainFrame != false { tab(for: webView)?.isInternalPage = true }
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        return createTab().webView
    }
}
