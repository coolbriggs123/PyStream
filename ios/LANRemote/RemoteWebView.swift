
import SwiftUI
import WebKit
import UIKit

struct RemoteWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        container.clipsToBounds = true

        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        configuration.userContentController.add(
            context.coordinator,
            name: "pystreamKeyboard"
        )

        let webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black

        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        webView.allowsBackForwardNavigationGestures = false

        container.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(
                equalTo: container.leadingAnchor
            ),
            webView.trailingAnchor.constraint(
                equalTo: container.trailingAnchor
            ),
            webView.topAnchor.constraint(
                equalTo: container.topAnchor
            ),
            webView.bottomAnchor.constraint(
                equalTo: container.bottomAnchor
            )
        ])

        let keyboardField = UITextField(frame: .zero)

        keyboardField.delegate = context.coordinator
        keyboardField.autocorrectionType = .yes
        keyboardField.spellCheckingType = .yes
        keyboardField.autocapitalizationType = .sentences
        keyboardField.keyboardAppearance = .dark
        keyboardField.returnKeyType = .default

        keyboardField.textColor = .clear
        keyboardField.tintColor = .clear
        keyboardField.backgroundColor = .clear
        keyboardField.alpha = 0.01

        container.addSubview(keyboardField)

        keyboardField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            keyboardField.leadingAnchor.constraint(
                equalTo: container.leadingAnchor
            ),
            keyboardField.bottomAnchor.constraint(
                equalTo: container.bottomAnchor
            ),
            keyboardField.widthAnchor.constraint(
                equalToConstant: 1
            ),
            keyboardField.heightAnchor.constraint(
                equalToConstant: 1
            )
        ])

        context.coordinator.webView = webView
        context.coordinator.keyboardField = keyboardField

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20

        webView.load(request)

        return container
    }

    func updateUIView(
        _ container: UIView,
        context: Context
    ) {
        guard
            let webView = context.coordinator.webView,
            webView.url != url
        else {
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        webView.load(request)
    }

    static func dismantleUIView(
        _ container: UIView,
        coordinator: Coordinator
    ) {
        coordinator.keyboardField?.resignFirstResponder()

        coordinator.webView?
            .configuration
            .userContentController
            .removeScriptMessageHandler(
                forName: "pystreamKeyboard"
            )

        coordinator.webView = nil
        coordinator.keyboardField = nil
    }

    final class Coordinator: NSObject,
                             WKNavigationDelegate,
                             WKScriptMessageHandler,
                             UITextFieldDelegate {

        weak var webView: WKWebView?
        weak var keyboardField: UITextField?

        // JavaScript reports whether Windows has an editable
        // control focused. Only then is the native keyboard shown.

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard
                message.name == "pystreamKeyboard",
                let body = message.body as? [String: Any],
                let visible = body["visible"] as? Bool
            else {
                return
            }

            DispatchQueue.main.async {
                guard let field = self.keyboardField else {
                    return
                }

                if visible {
                    if !field.isFirstResponder {
                        field.becomeFirstResponder()
                    }
                } else {
                    if field.isFirstResponder {
                        field.resignFirstResponder()
                    }

                    field.text = ""
                }
            }
        }

        // Forward typed characters to the Windows host.

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {

            if string == "\n" {
                sendToWebView([
                    "key": "ENTER"
                ])

                DispatchQueue.main.async {
                    textField.text = ""
                }

                return false
            }

            if string.isEmpty {
                if range.length > 0 {
                    for _ in 0..<range.length {
                        sendToWebView([
                            "key": "BACKSPACE"
                        ])
                    }
                }

                DispatchQueue.main.async {
                    textField.text = ""
                }

                return false
            }

            sendToWebView([
                "text": string
            ])

            DispatchQueue.main.async {
                textField.text = ""
            }

            return false
        }

        private func sendToWebView(
            _ payload: [String: String]
        ) {
            guard let webView else {
                return
            }

            guard
                let data = try? JSONSerialization.data(
                    withJSONObject: payload
                ),
                let json = String(
                    data: data,
                    encoding: .utf8
                )
            else {
                return
            }

            let script = """
            window.dispatchEvent(
                new CustomEvent("pystream-native-text", {
                    detail: \(json)
                })
            );
            """

            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    print(
                        "[PyStream] Keyboard bridge error:",
                        error
                    )
                }
            }
        }
    }
}
