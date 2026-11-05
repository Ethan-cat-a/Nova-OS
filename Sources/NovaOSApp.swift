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
      <title>New Tab — Nova OS</title>
      <style>
        :root { color-scheme: dark; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif; }
        * { box-sizing: border-box; }
        body { margin: 0; min-height: 100vh; color: #f6f7ff; background: radial-gradient(ellipse at 50% -18%, rgba(89,105,255,.38), transparent 52%), radial-gradient(ellipse at 88% 72%, rgba(154,78,255,.15), transparent 40%), #0b0d18; display: grid; place-items: center; padding: 48px 24px; }
        main { width: min(760px, 100%); text-align: center; margin-top: -4vh; }
        .brand { display: inline-flex; align-items: center; gap: 10px; color: #c9d0ff; font-size: 13px; font-weight: 650; letter-spacing: .13em; text-transform: uppercase; }
        .mark { width: 29px; height: 29px; border-radius: 10px; display: grid; place-items: center; background: linear-gradient(145deg,#8ca0ff,#654bdf); box-shadow: 0 6px 24px #6155db55; font-size: 17px; }
        h1 { margin: 28px 0 8px; font-size: clamp(44px, 8vw, 68px); line-height: 1.02; letter-spacing: -.055em; font-weight: 690; }
        .subtitle { margin: 0; color: #a7aec9; font-size: 16px; }
        form { margin: 36px auto 0; height: 60px; display: flex; align-items: center; gap: 13px; padding: 0 8px 0 19px; max-width: 650px; border-radius: 19px; background: rgba(255,255,255,.075); border: 1px solid rgba(213,220,255,.18); box-shadow: 0 16px 48px rgba(0,0,0,.24), inset 0 1px rgba(255,255,255,.08); backdrop-filter: blur(18px); }
        form:focus-within { border-color: rgba(148,162,255,.72); box-shadow: 0 0 0 4px rgba(102,119,255,.14), 0 16px 48px rgba(0,0,0,.24); }
        .search-icon { color: #9ba7ff; font-size: 19px; }
        input { flex: 1; min-width: 0; border: 0; outline: 0; background: transparent; color: white; font: inherit; font-size: 16px; }
        input::placeholder { color: #9da4bd; }
        button { border: 0; border-radius: 13px; padding: 12px 18px; color: white; background: linear-gradient(135deg,#7288ff,#7653e4); font: inherit; font-size: 14px; font-weight: 650; cursor: pointer; }
        button:hover { filter: brightness(1.12); }
        .section-label { margin: 46px 0 16px; color: #8088a6; font-size: 11px; letter-spacing: .16em; text-transform: uppercase; font-weight: 650; }
        .links { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; text-align: left; }
        .link { padding: 16px; min-height: 92px; border-radius: 17px; color: #f3f4ff; text-decoration: none; background: rgba(255,255,255,.045); border: 1px solid rgba(213,220,255,.09); transition: .18s ease; }
        .link:hover { transform: translateY(-2px); background: rgba(255,255,255,.09); border-color: rgba(148,162,255,.32); }
        .link strong { display: block; font-size: 14px; font-weight: 620; }
        .link span { display: block; margin-top: 7px; color: #949bb5; font-size: 12px; }
        footer { margin-top: 45px; color: #686f8b; font-size: 12px; }
        @media (max-width: 560px) { .links { grid-template-columns: repeat(2, 1fr); } form { height: 56px; } button { padding: 11px 13px; } }
      </style>
    </head>
    <body>
      <main>
        <div class="brand"><span class="mark">✦</span> Nova OS</div>
        <h1>Explore with Nova.</h1>
        <p class="subtitle">Your space to search, discover, and find your way.</p>
        <form id="search"><span class="search-icon">✦</span><input id="query" aria-label="Search Nova or enter a website" autofocus placeholder="Search Nova or enter a website" autocomplete="off"><button type="submit">Search Nova</button></form>
        <p class="section-label">Quick links</p>
        <div class="links">
          <a class="link" href="https://nova-os-browser.vercel.app/"><strong>Nova OS</strong><span>Your workspace</span></a>
          <a class="link" href="https://www.youtube.com/"><strong>YouTube</strong><span>Watch something</span></a>
          <a class="link" href="https://github.com/"><strong>GitHub</strong><span>Build and explore</span></a>
          <a class="link" href="https://en.wikipedia.org/"><strong>Wikipedia</strong><span>Discover something</span></a>
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

    static func searchHTML(query: String) -> String {
        let encoded = (try? JSONSerialization.data(withJSONObject: query, options: [.fragmentsAllowed]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
        let safeQuery = encoded.replacingOccurrences(of: "<", with: "\\u003c")
            .replacingOccurrences(of: ">", with: "\\u003e")
            .replacingOccurrences(of: "&", with: "\\u0026")
        return searchPage.replacingOccurrences(of: "__NOVA_QUERY__", with: safeQuery)
    }

    static let searchPage = #"""
    <!doctype html>
    <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Nova Search</title><style>
    :root{color-scheme:dark;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif}
    *{box-sizing:border-box}body{margin:0;min-height:100vh;color:#f2f4ff;background:radial-gradient(ellipse at 95% -10%,#5443a035,transparent 38%),#0d1222}
    header{position:sticky;top:0;z-index:2;background:#11172aed;border-bottom:1px solid #c7d2ff1a;backdrop-filter:blur(24px)}
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
    const summary=document.getElementById('summary'),provider=document.getElementById('provider');let sequence=0;
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
    async function search(type){const current=++sequence;document.querySelectorAll('nav button').forEach(button=>button.setAttribute('aria-selected',String(button.dataset.type===type)));
      results.className=type==='images'?'grid':type==='videos'?'videos':'';provider.textContent='';summary.textContent='Searching '+(type==='all'?'the web':type)+' for “'+query+'”…';status('Looking for results…');
      try{const response=await fetch('https://nova-os-browser.vercel.app/api/search?q='+encodeURIComponent(query)+'&type='+encodeURIComponent(type),{cache:'no-store'});if(!response.ok)throw new Error('Search unavailable');const data=await response.json();if(current!==sequence)return;
        results.replaceChildren();let count=0;for(const item of (Array.isArray(data.results)?data.results:[]))if(addResult(item,type))count++;
        summary.textContent=(count?count+' results':'No results')+' for “'+query+'”';if(!count)status('No '+(type==='all'?'web':type)+' results found. Try another search.');
        if(type==='videos'){const more=document.createElement('a');more.className='result';more.href='https://www.youtube.com/results?search_query='+encodeURIComponent(query);const label=document.createElement('span');label.className='title';label.textContent='Browse videos on YouTube ↗';more.append(label);results.append(more)}
        if(data.provider)provider.textContent='Results provided by '+data.provider;
      }catch{if(current===sequence){summary.textContent='Search unavailable';status('Nova Search could not connect. Check your internet connection and try again.')}}}
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

    init(id: UUID, webView: WKWebView, button: NSButton, closeButton: NSButton, itemView: NSStackView) {
        self.id = id
        self.webView = webView
        self.button = button
        self.closeButton = closeButton
        self.itemView = itemView
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private var window: NSWindow!
    private var tabBar: NSStackView!
    private var contentHost: NSView!
    private var addressField: NSSearchField!
    private var progressIndicator: NSProgressIndicator!
    private var backButton: NSButton!
    private var forwardButton: NSButton!
    private var reloadButton: NSButton!
    private var tabs: [BrowserTab] = []
    private var selectedTabID: UUID?
    private var updaterController: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        configureMenu()
        createWindow()
        _ = createTab(initialURL: nil)
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
        tabBar.edgeInsets = NSEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)

        let tabScrollView = NSScrollView()
        tabScrollView.translatesAutoresizingMaskIntoConstraints = false
        tabScrollView.drawsBackground = false
        tabScrollView.hasHorizontalScroller = true
        tabScrollView.hasVerticalScroller = false
        tabScrollView.borderType = .noBorder

        let newTabButton = makeSymbolButton("plus", tooltip: "New Tab", action: #selector(newTab))
        let tabStrip = NSVisualEffectView()
        tabStrip.translatesAutoresizingMaskIntoConstraints = false
        tabStrip.material = .titlebar
        tabStrip.blendingMode = .withinWindow
        tabStrip.state = .followsWindowActiveState
        tabStrip.wantsLayer = true
        tabStrip.layer?.backgroundColor = NSColor(srgbRed: 0.075, green: 0.085, blue: 0.17, alpha: 0.9).cgColor
        tabStrip.addSubview(tabScrollView)
        tabStrip.addSubview(newTabButton)
        NSLayoutConstraint.activate([
            tabScrollView.leadingAnchor.constraint(equalTo: tabStrip.leadingAnchor, constant: 8),
            tabScrollView.trailingAnchor.constraint(equalTo: newTabButton.leadingAnchor, constant: -8),
            tabScrollView.centerYAnchor.constraint(equalTo: tabStrip.centerYAnchor),
            tabScrollView.heightAnchor.constraint(equalToConstant: 31),
            newTabButton.trailingAnchor.constraint(equalTo: tabStrip.trailingAnchor, constant: -10),
            newTabButton.centerYAnchor.constraint(equalTo: tabStrip.centerYAnchor),
            newTabButton.widthAnchor.constraint(equalToConstant: 28),
            newTabButton.heightAnchor.constraint(equalToConstant: 28),
            tabStrip.heightAnchor.constraint(equalToConstant: 40)
        ])

        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabScrollView.documentView = tabBar
        tabBar.heightAnchor.constraint(equalTo: tabScrollView.contentView.heightAnchor).isActive = true
        tabBar.widthAnchor.constraint(greaterThanOrEqualTo: tabScrollView.contentView.widthAnchor).isActive = true

        let navigationBar = makeNavigationBar()
        let chromeStack = NSStackView(views: [tabStrip, navigationBar])
        chromeStack.orientation = .vertical
        chromeStack.alignment = .width
        chromeStack.distribution = .fill
        chromeStack.spacing = 0
        chromeStack.translatesAutoresizingMaskIntoConstraints = false

        let chrome = NSVisualEffectView()
        chrome.material = .titlebar
        chrome.blendingMode = .withinWindow
        chrome.state = .followsWindowActiveState
        chrome.wantsLayer = true
        chrome.layer?.backgroundColor = NSColor(srgbRed: 0.065, green: 0.075, blue: 0.15, alpha: 0.93).cgColor
        chrome.translatesAutoresizingMaskIntoConstraints = false
        chrome.addSubview(chromeStack)
        NSLayoutConstraint.activate([
            chromeStack.leadingAnchor.constraint(equalTo: chrome.leadingAnchor),
            chromeStack.trailingAnchor.constraint(equalTo: chrome.trailingAnchor),
            chromeStack.topAnchor.constraint(equalTo: chrome.topAnchor),
            chromeStack.bottomAnchor.constraint(equalTo: chrome.bottomAnchor),
            chrome.heightAnchor.constraint(equalToConstant: 95)
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

        let root = NSStackView(views: [chrome, progressIndicator, contentHost])
        root.orientation = .vertical
        root.alignment = .width
        root.distribution = .fill
        root.spacing = 0
        root.translatesAutoresizingMaskIntoConstraints = false
        root.setHuggingPriority(.defaultLow, for: .vertical)
        navigationBar.heightAnchor.constraint(equalToConstant: 54).isActive = true
        progressIndicator.heightAnchor.constraint(equalToConstant: 2).isActive = true
        contentHost.setContentHuggingPriority(.defaultLow, for: .vertical)

        let container = NSView()
        container.addSubview(root)
        window.contentView = container
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            root.topAnchor.constraint(equalTo: container.topAnchor),
            root.bottomAnchor.constraint(equalTo: container.bottomAnchor)
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

        let brand = NSTextField(labelWithString: "✦  NOVA")
        brand.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        brand.textColor = NSColor(srgbRed: 0.75, green: 0.73, blue: 1, alpha: 1)
        brand.setContentHuggingPriority(.required, for: .horizontal)

        let bar = NSStackView(views: [brand, backButton, forwardButton, reloadButton, homeButton, addressField])
        bar.orientation = .horizontal
        bar.alignment = .centerY
        bar.distribution = .fill
        bar.spacing = 8
        bar.edgeInsets = NSEdgeInsets(top: 9, left: 14, bottom: 9, right: 14)
        addressField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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

    private func createTab(initialURL: URL?, select: Bool = true) -> BrowserTab {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController.add(self, name: "novaNavigate")
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

        let tab = BrowserTab(id: id, webView: webView, button: tabButton, closeButton: closeButton, itemView: itemView)
        tab.isInternalPage = initialURL == nil
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
        tabBar.addArrangedSubview(itemView)

        if select { selectTab(tab) }
        if let initialURL {
            webView.load(URLRequest(url: initialURL))
        } else {
            webView.loadHTMLString(NovaOS.newTabHTML, baseURL: nil)
        }
        return tab
    }

    private func selectTab(_ tab: BrowserTab) {
        selectedTabID = tab.id
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
        tab.button.title = title.count > 28 ? String(title.prefix(27)) + "…" : title
        tab.button.toolTip = tab.webView.url?.absoluteString ?? title
        if tab.id == selectedTabID {
            window.title = title == NovaOS.appName ? NovaOS.appName : "\(title) — \(NovaOS.appName)"
            addressField.stringValue = displayAddress(for: tab.webView)
            updateNavigationButtons()
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
            tab.isInternalPage = true
            tab.webView.loadHTMLString(NovaOS.searchHTML(query: input), baseURL: nil)
        case .website(let url):
            tab.isInternalPage = false
            if tab.id == selectedTabID { addressField.stringValue = url.absoluteString }
            tab.webView.load(URLRequest(url: url))
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "novaNavigate", message.frameInfo.isMainFrame,
              let webView = message.webView, let tab = tab(for: webView), tab.isInternalPage,
              let input = message.body as? String else { return }
        navigate(input, in: tab)
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

    @objc private func newTab() {
        _ = createTab(initialURL: nil)
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
            tab.webView.load(URLRequest(url: NovaOS.homeURL))
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
            if navigationAction.targetFrame?.isMainFrame != false { tab(for: webView)?.isInternalPage = false }
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
        return createTab(initialURL: nil).webView
    }
}
