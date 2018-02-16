//
//  ViewController.swift
//  Checkers
//
//  Created by Denis Malykh on 28.01.18.
//  Copyright © 2018 MrDekk. All rights reserved.
//

import UIKit
import ARKit

enum GameMode {
    case initializing
    case start
}

class ViewController: UIViewController {

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
        switch mode {
        case .initializing: hitTestAndPlaceCheckerboard(in: rec)
        case .start: break
        }
    }

    private func hitTestAndPlaceCheckerboard(in rec: UITapGestureRecognizer) {
        let pt = rec.location(in: rec.view)
        guard let hit = sceneView.hitTest(pt).first else {
            return
        }

        let hitpos = hit.worldCoordinates

        let cb = CheckerBoard()
        cb.position = hitpos
        sceneView.scene.rootNode.addChildNode(cb)

        self.checkerboard = cb

        mode = .start
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
