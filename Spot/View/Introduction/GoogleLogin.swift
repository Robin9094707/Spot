//
//  GoogleLogin.swift
//  Spot
//
//  Created by Leon Böttger on 10.12.24.
//

import LUI
import SwiftUI
import WebKit

struct GoogleLoginWebView: UIViewRepresentable {
    class Coordinator: NSObject {
        var parent: GoogleLoginWebView
        var timer: Timer?

        init(parent: GoogleLoginWebView) {
            self.parent = parent
        }

        func startCookieCheck(webView _: WKWebView) {
            // Set up a periodic timer to check cookies
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let cookieStore = WKWebsiteDataStore.default().httpCookieStore
                cookieStore.getAllCookies { cookies in
                    if let oauthTokenCookie = cookies.first(where: { $0.name == "oauth_token" }) {
                        // Stop the timer and notify the parent
                        self.timer?.invalidate()
                        self.timer = nil

                        let parentReference = self.parent

                        Task {
                            await generateAasToken(oauthToken: oauthTokenCookie.value)

                            DispatchQueue.main.async {
                                parentReference.shouldClose = true
                            }
                        }
                    }
                }
            }
        }

        func stopCookieCheck() {
            timer?.invalidate()
            timer = nil
        }
    }

    let url: URL
    @Binding var shouldClose: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        context.coordinator.startCookieCheck(webView: webView)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_: WKWebView, context _: Context) {}

    static func dismantleUIView(_: WKWebView, coordinator: Coordinator) {
        // Clean up resources and stop the timer
        coordinator.stopCookieCheck()
    }
}

struct GoogleLoginView: View {
    @State private var shouldCloseWebView = false
    @State private var finished = false

    var body: some View {
        NavigationSubView(header: "", supportsScrolling: false, backgroundShown: false) {
            ZStack {
                GoogleLoginWebView(url: URL(string: "https://accounts.google.com/EmbeddedSetup")!,
                                   shouldClose: $shouldCloseWebView)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .modifier(LinkTo(content: { IntroductionDoneView() }, isActive: $shouldCloseWebView))
    }
}

func generateAasToken(oauthToken: String) async {
    let username = TokenManager.sharedInstance.username

    guard let androidId = PushReceiver.sharedInstance.getAndroidId() else {
        showAlert(title: "An Error Occurred", message: "Your device was unable to connect to Firebase. Please try again later.")

        // Try another time
        PushReceiver.sharedInstance.signOut()
        return
    }

    PlayServicesOAuth.requestAASToken(email: username ?? "", oauthToken: oauthToken, androidID: String(androidId)) { result in
        switch result {
        case let .success(authResponse):
            if let aasToken = authResponse["Token"] {
                if let email = authResponse["Email"] {
                    DispatchQueue.main.async {
                        TokenManager.sharedInstance.username = email
                    }
                }

                DispatchQueue.main.async {
                    TokenManager.sharedInstance.aasToken = aasToken
                }
            } else {
                showAlert(title: "An Error Occurred", message: "An error occurred while logging you in. Please try again later.")
            }

        case let .failure(error):
            showAlert(title: "An Error Occurred", message: "An error occurred while logging you in. Please try again later.")
        }
    }
}
