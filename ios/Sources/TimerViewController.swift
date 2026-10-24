import AVKit
import UIKit
import WebKit

@MainActor
final class TimerViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private let home = URL(string: Bundle.main.object(forInfoDictionaryKey: "AJDHomeURL") as? String ?? "https://studytimer.ajdapp.org/")!
    private var web: WKWebView!
    private let pip = NativeTimerPiP()
    private let preview = SampleBufferView()
    private let status = UILabel()
    private let floatButton = UIButton(type: .system)
    private var snapshot = TimerSnapshot.idle
    private var lifecycleObservers: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.websiteDataStore = .default()
        config.userContentController.add(WeakTimerHandler(self), name: "ajdTimer")
        config.userContentController.addUserScript(WKUserScript(source: Self.bridgeScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true

        floatButton.setTitle("Float Timer", for: .normal)
        floatButton.setImage(UIImage(systemName: "pip.enter"), for: .normal)
        floatButton.addTarget(self, action: #selector(startPiP), for: .touchUpInside)
        floatButton.accessibilityHint = "Open the current countdown above other apps"
        status.text = "Native Apple PiP · Start a timer below"
        status.font = .preferredFont(forTextStyle: .footnote)
        status.textColor = .secondaryLabel
        status.numberOfLines = 0
        let top = UIStackView(arrangedSubviews: [floatButton, status])
        top.axis = .horizontal; top.spacing = 12; top.alignment = .center
        top.isLayoutMarginsRelativeArrangement = true
        top.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        let stack = UIStackView(arrangedSubviews: [top, preview, web])
        stack.axis = .vertical; stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            preview.heightAnchor.constraint(equalToConstant: 112)
        ])
        pip.attach(to: preview.displayLayer)
        pip.onStatus = { [weak self] message in self?.status.text = message }
        lifecycleObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.web.evaluateJavaScript("document.dispatchEvent(new Event('visibilitychange'));window.dispatchEvent(new Event('focus'));", completionHandler: nil)
            }
        })
        web.load(URLRequest(url: home))
    }

    @objc private func startPiP() {
        guard snapshot.running, snapshot.end > Date().timeIntervalSince1970 else {
            status.text = "Start a timer below, then tap Float Timer."
            return
        }
        pip.start()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame,
              message.frameInfo.securityOrigin.protocol == "https",
              message.frameInfo.securityOrigin.host == home.host,
              let body = message.body as? [String: Any],
              let state = body["state"] as? [String: Any],
              let data = try? JSONSerialization.data(withJSONObject: state),
              let next = try? JSONDecoder().decode(TimerSnapshot.self, from: data),
              next.end.isFinite, next.remaining.isFinite,
              (0...86400).contains(next.remaining),
              (60...14400).contains(next.focusSeconds),
              (60...7200).contains(next.breakSeconds) else { return }
        snapshot = next
        pip.update(next)
        if body["action"] as? String == "start" { startPiP() }
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        if url.scheme == "https", url.host == home.host { decisionHandler(.allow); return }
        decisionHandler(.cancel)
        if url.scheme == "https", action.targetFrame?.isMainFrame != false { UIApplication.shared.open(url) }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        status.text = "Could not load the tracker. Check your connection and reopen the app."
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "Tracker", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Tracker", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    deinit { lifecycleObservers.forEach(NotificationCenter.default.removeObserver) }

    private static let bridgeScript = #"""
    (()=>{
      const allowed=['studytimer.ajdapp.org','tracker.ajdapp.org'];
      if(location.protocol!=='https:'||!allowed.includes(location.hostname))return;
      const read=(key,fallback)=>{try{return JSON.parse(localStorage.getItem(key)||'null')||fallback}catch{return fallback}};
      function send(action='update'){
        const study=location.hostname==='studytimer.ajdapp.org';
        let state={running:false,end:0,remaining:0,mode:'focus',title:'Start a timer',focusSeconds:1500,breakSeconds:300,autoStart:false,study};
        if(study){
          const t=read('study-tracker-clock',{}),s=read('study-tracker-settings',{});
          Object.assign(state,{running:!!t.running,end:Number(t.ends||0)/1000,remaining:Number(t.left||0),mode:t.mode||'focus',title:t.mode==='break'?'Break time':'Study time',focusSeconds:Number(s.focus||25)*60,breakSeconds:Number(s.break||5)*60,autoStart:!!s.auto});
        }else if(location.pathname.includes('kitt')){
          const vehicles=read('kitt-break-tracker-v1',[]);
          const v=Array.isArray(vehicles)?vehicles.find(v=>v.active&&Number(v.active.end)>Date.now()):null;
          if(v)Object.assign(state,{running:true,end:Number(v.active.end)/1000,title:'Kitt_'+v.number+' · '+v.active.label});
        }else{
          const t=read('breakTracker_state',{}),end=Date.parse(t.target_end_time||'');
          Object.assign(state,{running:Number.isFinite(end)&&end>Date.now(),end:Number.isFinite(end)?end/1000:0,title:t.active_break_name||'Start a break'});
        }
        if(document.visibilityState==='visible'||action==='start')window.webkit.messageHandlers.ajdTimer.postMessage({action,state});
      }
      document.addEventListener('click',e=>{
        if(e.target.closest('#pip,#float,[onclick="openFloatingTimer()"]')){
          e.preventDefault();e.stopImmediatePropagation();send('start');
        }
      },true);
      setInterval(()=>send(),500);send();
    })();
    """#
}

@MainActor
private final class WeakTimerHandler: NSObject, WKScriptMessageHandler {
    weak var target: TimerViewController?
    init(_ target: TimerViewController) { self.target = target }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
