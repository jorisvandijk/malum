import AppKit
import WebKit

/// The web app's one window: the site in a web view, titled by the page. Links to other sites open
/// in the default browser.
@MainActor
final class WebAppWindow: NSWindow {
    /// How wide the window starts before the window manager places it.
    private static let startWidth = 1200
    /// How high the window starts.
    private static let startHeight = 800
    /// The size the window starts at.
    private static let startSize = CGSize(width: startWidth, height: startHeight)

    /// Shows the page.
    private let web: WKWebView
    /// The host the web app is for; pages elsewhere open in the browser.
    private let host: String?
    /// Watches the page's title for the window's.
    private var titleWatch: NSKeyValueObservation?

    /// Opens `site` in a window named `name` until the page gives its own title.
    init(site: URL, name: String) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        web = WKWebView(frame: CGRect(origin: .zero, size: Self.startSize), configuration: configuration)
        host = site.host()
        super.init(
            contentRect: CGRect(origin: .zero, size: Self.startSize),
            styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        title = name
        isReleasedWhenClosed = false
        contentView = web
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true
        titleWatch = web.observe(\.title) { [weak self] web, _ in
            MainActor.assumeIsolated { self?.showTitle(of: web, or: name) }
        }
        center()
        web.load(URLRequest(url: site))
    }

    /// Not used: the window is only built in code.
    required init?(coder: NSCoder) {
        nil
    }

    /// Loads the page again, for cmd+R.
    @objc func reload(_ sender: Any?) {
        web.reload()
    }

    /// Goes to the page before, for cmd+[.
    @objc func goBack(_ sender: Any?) {
        web.goBack()
    }

    /// Goes to the page after, for cmd+].
    @objc func goForward(_ sender: Any?) {
        web.goForward()
    }

    /// Titles the window by `web`'s page, or `name` when the page has no title.
    private func showTitle(of web: WKWebView, or name: String) {
        guard let page = web.title, !page.isEmpty else {
            title = name
            return
        }
        title = page
    }

    /// Whether `url` is on another site than the web app's, so it belongs in the browser.
    private func isElsewhere(_ url: URL) -> Bool {
        guard let host, let other = url.host() else { return false }
        return other != host
    }
}

// MARK: - WKNavigationDelegate

extension WebAppWindow: WKNavigationDelegate {
    /// Sends a link to another site to the default browser, and loads the rest here.
    func webView(
        _ webView: WKWebView, decidePolicyFor action: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let url = action.request.url, action.navigationType == .linkActivated, isElsewhere(url) else {
            return .allow
        }
        NSWorkspace.shared.open(url)
        return .cancel
    }
}

// MARK: - WKUIDelegate

extension WebAppWindow: WKUIDelegate {
    /// Loads a link meant for a new window in this one, or in the browser when it's another site.
    func webView(
        _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
        for action: WKNavigationAction, windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = action.request.url else { return nil }
        guard !isElsewhere(url) else {
            NSWorkspace.shared.open(url)
            return nil
        }
        webView.load(action.request)
        return nil
    }
}
