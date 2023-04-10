//
//  ViewController.swift
//  RealTimeTextView
//
//  Created by Igor Buzykin on 11.04.2023.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet var textView: UITextView!

	private var websocket: Websocket!

	override func viewDidLoad() {
		super.viewDidLoad()
		textView.delegate = self
		websocket = Websocket(url: URL(string: "ws://localhost:8080")!)
		websocket.delegate = self
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		websocket.connect()
	}
}

// MARK: - UITextViewDelegate

extension ViewController: UITextViewDelegate {
	func textViewDidChange(_ textView: UITextView) {
		guard let text = textView.text else { return }
		websocket.send(text)
	}
}

// MARK: - WebSocketDelegate

extension ViewController: WebSocketDelegate {
	func webSocketDidConnect(_ webSocket: Websocket) {
		print("connect")
	}

	func webSocketDidDisconnect(_ webSocket: Websocket) {
		print("disconnect")
	}

	func webSocket(_ webSocket: Websocket, didReceiveString string: String) {
		DispatchQueue.main.async {
			self.textView.text = string
		}
	}

	func webSocket(_ webSocket: Websocket, didReceiveData data: Data) {
		print(data)
	}
}
