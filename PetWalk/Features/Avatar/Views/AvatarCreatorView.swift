//
//  AvatarCreatorView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI
import WebKit

/// Ready Player Me 头像创建器视图
struct AvatarCreatorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var avatarManager = AvatarManager.shared
    @ObservedObject var webViewPreloader = WebViewPreloader.shared
    
    // 回调：头像创建完成
    var onAvatarCreated: ((String) -> Void)?
    
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSavingAvatar = false
    
    // 检查是否有预热的 WebView 可用
    private var hasPreloadedWebView: Bool {
        webViewPreloader.isPreloaded
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // WebView - 优先使用预热的版本
                ReadyPlayerMeWebView(
                    url: avatarManager.avatarCreatorURL,
                    isLoading: $isLoading,
                    usePreloadedIfAvailable: true,
                    onAvatarExported: { avatarURL in
                        handleAvatarExported(avatarURL)
                    },
                    onError: { error in
                        errorMessage = error
                        showError = true
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                
                // 加载指示器
                if isLoading || isSavingAvatar {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(isSavingAvatar ? "正在保存头像..." : (hasPreloadedWebView ? "正在准备..." : "正在加载头像编辑器..."))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(30)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
            }
            .navigationTitle("创建头像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        // 触发重新预热
                        WebViewPreloader.shared.refreshPreload()
                        dismiss()
                    }
                    .disabled(isSavingAvatar)
                }
            }
            .alert("加载失败", isPresented: $showError) {
                Button("重试") {
                    // 重新加载 WebView
                }
                Button("取消", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(errorMessage)
            }
        }
        .interactiveDismissDisabled(isSavingAvatar)
        .onDisappear {
            // 视图消失时触发重新预热
            WebViewPreloader.shared.refreshPreload()
        }
    }
    
    private func handleAvatarExported(_ avatarURL: String) {
        print("AvatarCreatorView: 开始保存头像 - \(avatarURL)")
        
        // 显示保存中状态
        isSavingAvatar = true
        
        // 保存头像 (异步下载)
        Task {
            await avatarManager.saveAvatarURLAsync(avatarURL)
            
            // 等待图片下载完成
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5秒延迟确保 UI 更新
            
            await MainActor.run {
                isSavingAvatar = false
                
                // 回调
                onAvatarCreated?(avatarURL)
                
                // 关闭视图
                dismiss()
            }
        }
    }
}

// MARK: - Ready Player Me WebView 封装
struct ReadyPlayerMeWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    var usePreloadedIfAvailable: Bool = false
    var onAvatarExported: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        // 尝试使用预热的 WebView
        if usePreloadedIfAvailable, let preloadedWebView = WebViewPreloader.shared.getPreloadedWebView() {
            print("AvatarCreatorView: 使用预热的 WebView")
            
            // 添加消息处理器到预热的 WebView
            preloadedWebView.configuration.userContentController.add(context.coordinator, name: "readyPlayerMe")
            preloadedWebView.navigationDelegate = context.coordinator
            
            // 注入 JavaScript（因为预热时没有注入）
            injectJavaScript(into: preloadedWebView)
            
            // 预热的 WebView 已经加载完成
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            return preloadedWebView
        }
        
        // 没有预热的 WebView，创建新的
        print("AvatarCreatorView: 创建新的 WebView")
        
        let configuration = WKWebViewConfiguration()
        
        // 启用 JavaScript
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // 允许内联媒体播放
        configuration.allowsInlineMediaPlayback = true
        
        // 添加消息处理器
        configuration.userContentController.add(context.coordinator, name: "readyPlayerMe")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        
        // 加载 Ready Player Me
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 无需更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - JavaScript 注入
    
    private func injectJavaScript(into webView: WKWebView) {
        // 改进的 JavaScript 消息监听，支持多种格式
        let js = """
        (function() {
            // 避免重复注入
            if (window.__rpmListenerAdded) return;
            window.__rpmListenerAdded = true;
            
            console.log('PetWalk: 开始监听 Ready Player Me 消息');
            
            // 监听所有 postMessage 消息
            window.addEventListener('message', function(event) {
                console.log('PetWalk: 收到消息', typeof event.data, event.data);
                
                // 情况1: 直接是 GLB URL 字符串
                if (typeof event.data === 'string') {
                    // 检查是否是 GLB URL
                    if (event.data.includes('.glb') || event.data.includes('models.readyplayer.me')) {
                        console.log('PetWalk: 检测到头像 URL (字符串)');
                        window.webkit.messageHandlers.readyPlayerMe.postMessage(JSON.stringify({
                            source: 'readyplayerme',
                            eventName: 'v1.avatar.exported',
                            data: { url: event.data }
                        }));
                        return;
                    }
                    
                    // 尝试解析为 JSON
                    try {
                        var json = JSON.parse(event.data);
                        if (json.source === 'readyplayerme') {
                            console.log('PetWalk: 检测到 RPM JSON 消息');
                            window.webkit.messageHandlers.readyPlayerMe.postMessage(event.data);
                        }
                    } catch (e) {
                        // 不是有效的 JSON，忽略
                    }
                }
                // 情况2: 已经是对象
                else if (typeof event.data === 'object' && event.data !== null) {
                    // Ready Player Me 标准格式
                    if (event.data.source === 'readyplayerme') {
                        console.log('PetWalk: 检测到 RPM 对象消息');
                        window.webkit.messageHandlers.readyPlayerMe.postMessage(JSON.stringify(event.data));
                        return;
                    }
                    
                    // 检查是否有 url 字段
                    if (event.data.url && (event.data.url.includes('.glb') || event.data.url.includes('models.readyplayer.me'))) {
                        console.log('PetWalk: 检测到头像 URL (对象)');
                        window.webkit.messageHandlers.readyPlayerMe.postMessage(JSON.stringify({
                            source: 'readyplayerme',
                            eventName: 'v1.avatar.exported',
                            data: { url: event.data.url }
                        }));
                        return;
                    }
                    
                    // 检查 data 字段
                    if (event.data.data && event.data.data.url) {
                        var url = event.data.data.url;
                        if (url.includes('.glb') || url.includes('models.readyplayer.me')) {
                            console.log('PetWalk: 检测到头像 URL (嵌套)');
                            window.webkit.messageHandlers.readyPlayerMe.postMessage(JSON.stringify({
                                source: 'readyplayerme',
                                eventName: 'v1.avatar.exported',
                                data: { url: url }
                            }));
                        }
                    }
                }
            }, false);
            
            // 订阅 Ready Player Me 事件
            setTimeout(function() {
                console.log('PetWalk: 发送订阅请求');
                window.postMessage(JSON.stringify({
                    target: 'readyplayerme',
                    type: 'subscribe',
                    eventName: 'v1.**'
                }), '*');
            }, 1000);
        })();
        """
        
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("AvatarCreatorView: JavaScript 注入失败 - \(error)")
            } else {
                print("AvatarCreatorView: JavaScript 注入成功")
            }
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ReadyPlayerMeWebView
        private var hasExported = false  // 防止重复触发
        
        init(_ parent: ReadyPlayerMeWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            
            // 注入 JavaScript 来监听 Ready Player Me 的消息
            parent.injectJavaScript(into: webView)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.onError?(error.localizedDescription)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.onError?(error.localizedDescription)
            }
        }
        
        // 处理 URL 变化 - 有些版本的 RPM 会通过 URL 传递结果
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url?.absoluteString {
                // 检查 URL 是否包含头像信息
                if url.contains(".glb") && url.contains("models.readyplayer.me") && !hasExported {
                    print("AvatarCreatorView: 从 URL 检测到头像 - \(url)")
                    hasExported = true
                    DispatchQueue.main.async {
                        self.parent.onAvatarExported?(url)
                    }
                }
            }
            decisionHandler(.allow)
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "readyPlayerMe" else { return }
            
            print("AvatarCreatorView: 收到原始消息 - \(message.body)")
            
            // 尝试解析消息
            var json: [String: Any]?
            
            if let messageBody = message.body as? String {
                if let data = messageBody.data(using: .utf8) {
                    json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                }
            } else if let dict = message.body as? [String: Any] {
                json = dict
            }
            
            guard let parsedJson = json else {
                print("AvatarCreatorView: 无法解析消息")
                return
            }
            
            print("AvatarCreatorView: 解析后的消息 - \(parsedJson)")
            
            // 防止重复触发
            guard !hasExported else {
                print("AvatarCreatorView: 已经导出过头像，忽略重复消息")
                return
            }
            
            // 提取头像 URL
            var avatarURL: String?
            
            // 检查 eventName
            if let eventName = parsedJson["eventName"] as? String {
                switch eventName {
                case "v1.avatar.exported":
                    if let eventData = parsedJson["data"] as? [String: Any] {
                        avatarURL = eventData["url"] as? String
                    }
                    
                case "v1.user.set":
                    print("AvatarCreatorView: 用户已登录")
                    
                case "v1.frame.ready":
                    print("AvatarCreatorView: Frame 已准备好")
                    
                default:
                    print("AvatarCreatorView: 事件 - \(eventName)")
                }
            }
            
            // 直接从 data.url 提取
            if avatarURL == nil, let data = parsedJson["data"] as? [String: Any] {
                avatarURL = data["url"] as? String
            }
            
            // 直接从 url 字段提取
            if avatarURL == nil {
                avatarURL = parsedJson["url"] as? String
            }
            
            // 触发回调
            if let url = avatarURL, url.contains("models.readyplayer.me") || url.contains(".glb") {
                print("AvatarCreatorView: 成功提取头像 URL - \(url)")
                hasExported = true
                DispatchQueue.main.async {
                    self.parent.onAvatarExported?(url)
                }
            }
        }
    }
}

#Preview {
    AvatarCreatorView()
}
