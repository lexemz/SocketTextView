//
//  Websocket.swift
//  RealTimeTextView
//
//  Created by Igor Buzykin on 11.04.2023.
//

import Foundation

protocol WebSocketDelegate: AnyObject {
	func webSocketDidConnect(_ webSocket: Websocket)
	func webSocketDidDisconnect(_ webSocket: Websocket)
	func webSocket(_ webSocket: Websocket, didReceiveString string: String)
	func webSocket(_ webSocket: Websocket, didReceiveData data: Data)
}

final class Websocket: NSObject {
	weak var delegate: WebSocketDelegate?
	var isConnected: Bool = false

	private let url: URL
	private var socket: URLSessionWebSocketTask?
	private var urlSession: URLSession?

	init(url: URL) {
		self.url = url
		super.init()
	}

	deinit {
		print("NativeSocket has been replaced on StarscreamSocket")
	}

	func connect() {
		let urlSession = URLSession(
			configuration: .default,
			delegate: self,
			delegateQueue: nil
		)
		self.urlSession = urlSession
		socket = urlSession.webSocketTask(with: url)
		socket?.resume()
		receiveMessage()
	}

	func disconnect() {
		socket?.cancel(with: .goingAway, reason: nil)
		socket = nil
		urlSession?.invalidateAndCancel()
		urlSession = nil
	}

	func send(_ string: String) {
		socket?.send(.string(string)) { error in
			guard let error else { return }
			let errorDescription = error.localizedDescription
			print("Sending the message failed! Error: \(errorDescription)")
		}
	}

	func send(_ data: Data) {
		socket?.send(.data(data)) { error in
			guard let error else { return }
			let errorDescription = error.localizedDescription
			print("Sending the message failed! Error: \(errorDescription)")
		}
	}
}

// MARK: - URLSessionWebSocketDelegate

extension Websocket: URLSessionWebSocketDelegate {
	func urlSession(
		_: URLSession,
		webSocketTask _: URLSessionWebSocketTask,
		didOpenWithProtocol _: String?
	) {
		isConnected = true
		delegate?.webSocketDidConnect(self)
	}

	func urlSession(
		_: URLSession,
		webSocketTask _: URLSessionWebSocketTask,
		didCloseWith _: URLSessionWebSocketTask.CloseCode,
		reason _: Data?
	) {
		isConnected = false
		delegate?.webSocketDidDisconnect(self)
	}
}

// MARK: - Private extension

private extension Websocket {
	func receiveMessage() {
		socket?.receive { [weak self] message in
			guard let self else { return }
			switch message {
			case let .success(message):
				switch message {
				case let .data(recivedData):
					self.delegate?.webSocket(self, didReceiveData: recivedData)
				case let .string(recivedString):
					self.delegate?.webSocket(self, didReceiveString: recivedString)
				default:
					print("WebSocket did receive Unknown Type!")
				}
				self.receiveMessage()
			case .failure:
				self.disconnect()
			}
		}
	}
}
