//
//  ARGameHostConnector.swift
//  ARcheckers
//
//  Created by Denis Malykh on 16.07.2018.
//  Copyright © 2018 Yandex. All rights reserved.
//

import Foundation
import MultipeerConnectivity

final class ARGameHostConnector : NSObject, ARGameConnector {

    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!

    weak var delegate: ARGameConnectorDelegate? = nil

    func start() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self

        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ARCheckers", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }

    func send(data: Data, to peer: MCPeerID) {
        do {
            try mcSession.send(data, toPeers: [peer], with: .reliable)
        } catch {
            delegate?.didDisconnected(from: peer)
        }
    }
}

extension ARGameHostConnector : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            delegate?.didConnected(to: peerID)

        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")

        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            delegate?.didDisconnected(from: peerID)
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        delegate?.didReceive(data: data, from: peerID)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }
}
