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

    func start()
    func send(data: Data, to peer: MCPeerID)
}
