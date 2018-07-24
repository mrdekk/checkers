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
    case relocalizeWorld(worldMap: Data?, checkerboardPosition: SCNVector3) // for join
    case notifySetupFinish // for join
    case awaitJoinedSetup // for host

    case white
    case black
}

final class ARGameViewController : UIViewController {
    private let controller: ARGameController

    private let isHost: Bool
    private let connector: ARGameConnector
    private var remoteID: MCPeerID?

    private var mode: ARGameMode {
        didSet {
            reportModeSet()
        }
    }

    init(isHost: Bool) {
        self.controller = ARGameController()
        self.isHost = isHost
        self.mode = isHost ? .initializeWorld : .awaitHostSetup
        self.connector = isHost ? ARGameHostConnector() : ARGameJoinConnector()

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

        if !isHost, case .awaitHostSetup = mode {
            connector.start(in: self)
        }

        controller.show(notice: "Track the world and place checkerboard")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controller.pauseWorldTracking()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        controller.layout(bounds: view.bounds, safeArea: view.safeAreaInsets)
    }

    // MARK: - Private

    private func reportModeSet() {
        switch mode {
        case .initializeWorld:
            controller.show(notice: "Initialize world mode")
            NSLog("Initialize world mode")

        case .preparingARWorld:
            controller.show(notice: "Preparing ARWorld for sending to peers")
            NSLog("Preparing ARWorld for sending to peers")

        case .awaitingConnection:
            controller.show(notice: "Awaiting peers connection")
            NSLog("Awaiting peers connection")

        case .setupJoined:
            controller.show(notice: "Setup joined peer")
            NSLog("Setup joined peer")

        case .awaitHostSetup:
            controller.show(notice: "Await host setup")
            NSLog("Await host setup")

        case .relocalizeWorld:
            controller.show(notice: "Relocalize world")
            NSLog("Relocalize world")

        case .notifySetupFinish:
            controller.show(notice: "Notify setup finished")
            NSLog("Notify setup finished")

        case .awaitJoinedSetup:
            controller.show(notice: "Await joined setup")
            NSLog("Await joined setup")

        case .white:
            controller.show(notice: "White turn")
            NSLog("White turn")

        case .black:
            controller.show(notice: "Black turn")
            NSLog("Black turn")
        }
    }

    private func placeCheckerboard(_ hit: SCNHitTestResult) {
        placeCheckerboard(at: hit.worldCoordinates)
    }

    private func placeCheckerboard(at pos: SCNVector3) {
        controller.placeCheckerboard(at: pos)

        mode = .preparingARWorld

        SVProgressHUD.show(withStatus: "Preparing ARWorld")

        if let frame = controller.session.currentFrame {
            tryToSendARWorldMap(frame)
        }
    }

    private func hitTestChecker(side: Checker.Side, hit: SCNHitTestResult) {
        switch hit.node {
        case let checker as Checker:
            if let cb = controller.board, checker.side == side {
                let moves = cb.took(checker)
                cb.highlight(moves: moves)

                let message = TookMessage(i: checker.i, j: checker.j)
                if let msg = try? JSONEncoder().encode(message), let peer = remoteID {
                    connector.send(data: msg, to: peer)
                }
            }

        case let cell as CheckerBoardCell:
            if let cb = controller.board, cb.place(cell) {
                switch mode {
                case .white:
                    if cb.isWin(side: .white) {
                        let alert = UIAlertController(title: "White Wins", message: "Hurray! White wins!", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        present(alert, animated: true, completion: nil)
                        // TODO: go back in VC
                    }
                    mode = .black

                case .black:
                    if cb.isWin(side: .black) {
                        let alert = UIAlertController(title: "Black Wins", message: "Hurray! Black wins!", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        present(alert, animated: true, completion: nil)
                        // TODO: go back in VC
                    }
                    mode = .white

                default: break
                }

                let message = PlaceMessage(i: cell.i, j: cell.j)
                if let msg = try? JSONEncoder().encode(message), let peer = remoteID {
                    connector.send(data: msg, to: peer)
                }
            }

        default:
            break
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

        connector.start(in: self)
    }

    private func finalizeRelocalizing(pos: SCNVector3) {
        controller.placeCheckerboard(at: pos)
        controller.show(notice: "Await host acknowledgement")
        mode = .notifySetupFinish

        let message = JoinSetupFinishedMessage(succeeded: true)
        if let peer = remoteID, let msg = try? JSONEncoder().encode(message) {
            connector.send(data: msg, to: peer)
        }
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
        if isHost, case .preparingARWorld = mode {
            tryToSendARWorldMap(frame)
            return
        }

        if !isHost, case let .relocalizeWorld(_, checkerboardPosition) = mode {
            if #available(iOS 12, *) {
                NSLog("mapping status: \(frame.worldMappingStatus)")
                switch frame.worldMappingStatus {
                case .mapped, .extending:
                   finalizeRelocalizing(pos: checkerboardPosition)

                case .limited, .notAvailable:
                    break
                }
            } else {
                finalizeRelocalizing(pos: checkerboardPosition)
            }
        }
    }
}

extension ARGameViewController : ARGameConnectorDelegate {
    func didConnected(to peer: MCPeerID) {
        remoteID = peer
        if isHost {
            if case let ARGameMode.awaitingConnection(message) = mode {
                do {
                    let msgd = try JSONEncoder().encode(message)
                    controller.show(notice: "Establishing joined device...")
                    mode = .setupJoined
                    connector.send(data: msgd, to: peer)
                } catch {
                    NSLog("Error setup joined \(error)")
                    dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    func didDisconnected(from peer: MCPeerID) {
        dismiss(animated: true, completion: nil)
    }

    func didReceive(data: Data, from peer: MCPeerID) {
        if isHost {
            switch mode {
            case .setupJoined:
                if let msg = try? JSONDecoder().decode(JoinSetupFinishedMessage.self, from: data), msg.succeeded {
                    controller.show(notice: "Game is started, await")
                    mode = .awaitJoinedSetup
                    let message = GameStartMessage(greeting: "White")
                    if let msg = try? JSONEncoder().encode(message) {
                        connector.send(data: msg, to: peer)
                    }
                }

            case .awaitJoinedSetup:
                if let _ = try? JSONDecoder().decode(GameStartMessage.self, from: data) {
                    controller.show(notice: "White turn")
                    mode = .white
                }

            default:
                break
            }
        } else {
            switch mode {
            case .awaitHostSetup:
                if let msg = try? JSONDecoder().decode(InitMessage.self, from: data),
                        let position = NSKeyedUnarchiver.unarchiveObject(with: msg.checkerboardPosition) as? SCNVector3 {                    
                    mode = .relocalizeWorld(worldMap: msg.worldMap, checkerboardPosition: position)
                    if #available(iOS 12, *),
                            let archivedMap = msg.worldMap,
                            let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: archivedMap) {
                        controller.setupWorldTracking(worldMap: worldMap)
                    } else {
                        controller.setupWorldTrackingLegacy()
                    }
                    controller.show(notice: "Relocalizing the world from host...")
                }

            case .notifySetupFinish:
                if let _ = try? JSONDecoder().decode(GameStartMessage.self, from: data) {
                    controller.show(notice: "Server is started, await its turn")
                    mode = .white
                    connector.send(data: data, to: peer)
                }

            default:
                break
            }
        }

        switch mode {
        case .white, .black:
            if let msg = try? JSONDecoder().decode(TookMessage.self, from: data) {
                if let cb = controller.board, let checker = cb.checkers[msg.j * 8 + msg.i] {
                    let moves = cb.took(checker)
                    cb.highlight(moves: moves)
                }
            }

            if let msg = try? JSONDecoder().decode(PlaceMessage.self, from: data) {
                if let cb = controller.board, let cell = cb.cells[msg.j * 8 + msg.i], cb.place(cell) {
                    switch mode {
                    case .white:
                        if cb.isWin(side: .white) {
                            let alert = UIAlertController(title: "White Wins", message: "Hurray! White wins!", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            present(alert, animated: true, completion: nil)
                            // TODO: go back in VC
                        }
                        mode = .black

                    case .black:
                        if cb.isWin(side: .black) {
                            let alert = UIAlertController(title: "Black Wins", message: "Hurray! Black wins!", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            present(alert, animated: true, completion: nil)
                            // TODO: go back in VC
                        }
                        mode = .white

                    default: break
                    }
                }
            }

        default:
            break
        }
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
                hitTestChecker(side: .white, hit: hit)
                break

            case .black:
                // NOTE: host is playing white !
                break
            }
        } else {
            switch mode {
            case .initializeWorld, .preparingARWorld, .awaitingConnection,
                 .setupJoined, .awaitHostSetup, .relocalizeWorld,
                 .notifySetupFinish, .awaitJoinedSetup:
                break

            case .white:
                // NOTE: join is playing black !
                break

            case .black:
                hitTestChecker(side: .black, hit: hit)
                break
            }
        }
    }
}
