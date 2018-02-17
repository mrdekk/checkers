//
//  Connector.swift
//  ARcheckers
//
//  Created by Denis Malykh on 17.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ConnectorDelegate1 : class {
    func didConnected(to peer: MCPeerID)
}

protocol ConnectorDelegate2 : class {
    func didDisconnected(from peer: MCPeerID)
    func didReceive(data: Data, from peer: MCPeerID)
}

class Connector : NSObject {
    static let shared = Connector()

    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var mcBrowser: MCBrowserViewController?

    weak var delegate1: ConnectorDelegate1? = nil
    weak var delegate2: ConnectorDelegate2? = nil

    func start() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }

    func host() {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ARCheckers", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }

    func join(in vc: UIViewController) {
        let mcBrowser = MCBrowserViewController(serviceType: "ARCheckers", session: mcSession)
        mcBrowser.delegate = self
        vc.present(mcBrowser, animated: true)
        self.mcBrowser = mcBrowser
    }

    func send(data: Data, to peer: MCPeerID) {
        do {
            try mcSession.send(data, toPeers: [peer], with: .reliable)
        } catch {
            delegate2?.didDisconnected(from: peer)
        }
    }
}

extension Connector : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            if let mcb = mcBrowser {
                mcb.dismiss(animated: true, completion: { [weak self] in
                    guard let sself = self else { return }
                    sself.mcBrowser = nil
                    sself.delegate1?.didConnected(to: peerID)
                })
            } else {
                delegate1?.didConnected(to: peerID)
            }

        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")

        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            delegate2?.didDisconnected(from: peerID)
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        delegate2?.didReceive(data: data, from: peerID)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }
}

extension Connector : MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        mcBrowser?.dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        mcBrowser?.dismiss(animated: true)
    }
}
