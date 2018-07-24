//
//  ARGameConnector.swift
//  ARcheckers
//
//  Created by Denis Malykh on 16.07.2018.
//  Copyright © 2018 Yandex. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ARGameConnectorDelegate : class {
    func didConnected(to peer: MCPeerID)
    func didDisconnected(from peer: MCPeerID)

    func didReceive(data: Data, from peer: MCPeerID)
}

protocol ARGameConnector : class {
    weak var delegate: ARGameConnectorDelegate? { set get }

    func start(in vc: UIViewController)
    func send(data: Data, to peer: MCPeerID)
}

func onMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}
