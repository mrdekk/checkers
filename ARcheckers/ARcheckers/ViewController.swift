//
//  ViewController.swift
//  Checkers
//
//  Created by Denis Malykh on 28.01.18.
//  Copyright © 2018 MrDekk. All rights reserved.
//

import UIKit
import ARKit
import GameKit

enum GameMode {
    case initializing
    case black
    case white
}

class ViewController: UIViewController, GKLocalPlayerListener {

    @IBOutlet weak var closeButton: UIButton!
    
    @IBAction func closeNow(_ sender: UIButton) {
        self.dismiss(animated: true) {
            //clear gameCenterSession
        }
    }
    
    public var match : GKTurnBasedMatch? = nil
    
    private var mode: GameMode = .initializing

    private var checkerboard: CheckerBoard? = nil

    @IBOutlet private weak var sceneView: ARSCNView! {
        didSet {
            sceneView.delegate = self

            let rec = UITapGestureRecognizer(target: self, action: #selector(didTap))
            sceneView.addGestureRecognizer(rec)
        }
    }

    private var boards: [UUID: Board] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let conf = ARWorldTrackingConfiguration()
        conf.planeDetection = .horizontal
        sceneView.session.run(conf)

        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @objc func didTap(_ rec: UITapGestureRecognizer) {
        let pt = rec.location(in: rec.view)
        guard let hit = sceneView.hitTest(pt).first else {
            return
        }

        switch mode {
        case .initializing: hitTestAndPlaceCheckerboard(hit)
        case .white: hitTestChecker(side: .white, hit: hit)
        case .black: hitTestChecker(side: .black, hit: hit)
        }
    }

    private func hitTestAndPlaceCheckerboard(_ hit: SCNHitTestResult) {
        let hitpos = hit.worldCoordinates

        let cb = CheckerBoard()
        cb.position = hitpos
        sceneView.scene.rootNode.addChildNode(cb)

        self.checkerboard = cb

        mode = .white
        let participant = match?.participants
        let msgReady = [String : Any]()
        let packet = try! JSONSerialization.data(withJSONObject: msgReady, options:[])
        match?.endTurn(withNextParticipants: [participant!.last!], turnTimeout: 1000, match: packet, completionHandler: { (_) in
            // End of the turn
        })
    }

    private func hitTestChecker(side: Checker.Side, hit: SCNHitTestResult) {
        switch hit.node {
        case let checker as Checker:
            if let cb = checkerboard, checker.side == side {
                let moves = cb.took(checker)
                cb.highlight(moves: moves)
            }

        case let cell as CheckerBoardCell:
            if let cb = checkerboard, cb.place(cell) {
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

        default:
            break
        }
    }
}

extension ViewController : ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let a = anchor as? ARPlaneAnchor {
            let b = Board(anchor: a)
            boards[anchor.identifier] = b
            node.addChildNode(b)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let b = boards[anchor.identifier], let a = anchor as? ARPlaneAnchor {
            b.update(a)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        boards[anchor.identifier] = nil
    }
}
