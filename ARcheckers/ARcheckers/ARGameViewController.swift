//
//  ARGameViewController.swift
//  ARcheckers
//
//  Created by Denis Malykh on 13.07.2018.
//  Copyright © 2018 Yandex. All rights reserved.
//

import UIKit
import ARKit
import MultipeerConnectivity
import SVProgressHUD

enum ARGameMode {
    case initializeWorld // for host
    case preparingARWorld // for host
    case awaitingConnection(message: InitMessage) // for host
    case setupJoined // for host
    case awaitHostSetup // for join
    case relocalizeWorld // for join
    case notifySetupFinish // for join
    case awaitJoinedSetup // for host

    case white
    case black
}

final class ARGameViewController : UIViewController {
    private let controller: ARGameController

    private let isHost: Bool
    private let connector: ARGameConnector

    private var mode: ARGameMode

    init(isHost: Bool) {
        self.controller = ARGameController()
        self.isHost = isHost
        self.mode = isHost ? .initializeWorld : .awaitHostSetup
        self.connector = isHost ? ARGameHostConnector() : ARGameHostConnector()

        super.init(nibName: nil, bundle: nil)

        self.controller.bind(to: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        controller.placeViews(into: self)
        controller.delegate = self

        connector.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isHost, case .initializeWorld = mode {
            if #available(iOS 12, *) {
                controller.setupWorldTracking(worldMap: nil)
            } else {
                controller.setupWorldTrackingLegacy()
            }
        }

        controller.show(notice: "Track the world and place checkerboard")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controller.pauseWorldTracking()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        controller.layout(bounds: view.bounds)
    }

    // MARK: - Private

    private func placeCheckerboard(_ hit: SCNHitTestResult) {
        controller.placeCheckerboard(hit)

        mode = .preparingARWorld

        SVProgressHUD.show(withStatus: "Preparing ARWorld")

        if let frame = controller.session.currentFrame {
            tryToSendARWorldMap(frame)
        }
    }

    private func tryToSendARWorldMap(_ frame: ARFrame) {
        if #available(iOS 12.0, *) {
            switch frame.worldMappingStatus {
            case .notAvailable, .limited:
                controller.show(notice: "ARWorld map is bad for sending to peers")

            case .extending, .mapped:
                controller.session.getCurrentWorldMap { [weak self] (map, error) in
                    guard
                        let sself = self,
                        let map = map,
                        error == nil
                        else { return }

                    guard
                        let board = sself.controller.board,
                        let mapData = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true),
                        let posData = try? NSKeyedArchiver.archivedData(withRootObject: board.position, requiringSecureCoding: true)
                        else { return }

                    let msg = InitMessage(worldMap: mapData, checkerboardPosition: posData)
                    DispatchQueue.main.async { [weak self] in
                        self?.awaitConnections(message: msg)
                    }
                }
            }
        } else {
            if let board = controller.board, let posData = try? NSKeyedArchiver.archivedData(withRootObject: board.position, requiringSecureCoding: true) {
                awaitConnections(message: InitMessage(worldMap: nil, checkerboardPosition: posData))
            }
        }
    }

    private func awaitConnections(message: InitMessage) {
        controller.show(notice: "Awaiting connections")
        mode = .awaitingConnection(message: message)
        SVProgressHUD.dismiss()

        connector.start()
    }
}

extension ARGameViewController : ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let anchor = anchor as? ARPlaneAnchor {
            let board = Board(anchor: anchor)
            controller.addBoard(board, with: anchor.identifier)
            node.addChildNode(board)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let board = controller.board(for: anchor.identifier), let anchor = anchor as? ARPlaneAnchor {
            board.update(anchor)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        controller.removeBoard(with: anchor.identifier)
    }
}

extension ARGameViewController : ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isHost, case .preparingARWorld = mode else {
            return
        }

        tryToSendARWorldMap(frame)
    }
}

extension ARGameViewController : ARGameConnectorDelegate {
    func didConnected(to peer: MCPeerID) {
        if isHost {
            if case let ARGameMode.awaitingConnection(message) = mode,
                let msgd = try? JSONEncoder().encode(message) {
                connector.send(data: msgd, to: peer)
            }
        }
    }

    func didDisconnected(from peer: MCPeerID) {
        dismiss(animated: true, completion: nil)
    }

    func didReceive(data: Data, from peer: MCPeerID) {
        // TODO:
    }
}

private extension ARGameMode {
    func canGo(to newState: ARGameMode, isHost: Bool) -> Bool {
        if isHost {
            switch (self, newState) {
            case (.initializeWorld, .preparingARWorld),
                 (.preparingARWorld, .awaitingConnection),
                 (.awaitingConnection, .setupJoined),
                 (.setupJoined, .awaitJoinedSetup),
                 (.awaitJoinedSetup, .white),
                 (.white, .black),
                 (.black, .white):
                return true

            default:
                return false
            }
        } else {
            // joined
            switch (self, newState) {
            case (.awaitHostSetup, .relocalizeWorld),
                 (.relocalizeWorld, .notifySetupFinish),
                 (.notifySetupFinish, .white),
                 (.white, .black),
                 (.black, .white):
                return true

            default:
                return false
            }
        }
    }
}

extension ARGameViewController : ARGameControllerDelegate {
    func hit(_ hit: SCNHitTestResult) {
        if isHost {
            switch mode {
            case .initializeWorld:
                placeCheckerboard(hit)

            case .preparingARWorld:
                break

            case .awaitingConnection:
                // TODO:
                break

            case .setupJoined:
                // TODO:
                break

            case .awaitJoinedSetup:
                break

            case .awaitHostSetup, .relocalizeWorld, .notifySetupFinish:
                break

            case .white:
                // TODO:
                break
            case .black:
                // TODO:
                break
            }
        } else {
            // TODO:
        }
    }
}
