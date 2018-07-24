//
//  ARGameJoinConnector.swift
//  ARcheckers
//
//  Created by Denis Malykh on 19.07.2018.
//  Copyright © 2018 Yandex. All rights reserved.
//

import Foundation
import MultipeerConnectivity

final class ARGameJoinConnector : NSObject, ARGameConnector {
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcBrowser: MCBrowserViewController?

    weak var delegate: ARGameConnectorDelegate? = nil

    private var alreadyStarted = false

    func start(in vc: UIViewController) {
        guard !alreadyStarted else {
            return
        }

        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self

        let mcBrowser = MCBrowserViewController(serviceType: "ARCheckers", session: mcSession)
        mcBrowser.delegate = self
        vc.present(mcBrowser, animated: true)
        self.mcBrowser = mcBrowser

        alreadyStarted = true
    }

    func send(data: Data, to peer: MCPeerID) {
        do {
            try mcSession.send(data, toPeers: [peer], with: .reliable)
        } catch {
            delegate?.didDisconnected(from: peer)
        }
    }

    private func finishBrowser(_ completion: (() -> Void)?) {
        mcBrowser?.dismiss(animated: true, completion: completion)
        mcBrowser = nil
    }

    private func finishBrowserAndPresenter() {
        guard let browser = mcBrowser else {
            return
        }

        let presenter = browser.presentingViewController
        browser.dismiss(animated: true) { [presenter] in
            presenter?.dismiss(animated: true, completion: nil)
        }
    }
}

extension ARGameJoinConnector : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            onMainThread { [weak self] in
                self?.finishBrowser { [weak self] in
                    self?.delegate?.didConnected(to: peerID)
                }
            }

        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")

        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            onMainThread { [delegate] in
                delegate?.didDisconnected(from: peerID)
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        onMainThread { [delegate] in
            delegate?.didReceive(data: data, from: peerID)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("receive input stream")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("start receiving resource")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("finish receiving resource")
    }
}

extension ARGameJoinConnector : MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        finishBrowserAndPresenter()
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        finishBrowserAndPresenter()
    }
}
