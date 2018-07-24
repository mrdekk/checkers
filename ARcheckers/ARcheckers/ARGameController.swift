//
//  ARGameController.swift
//  ARcheckers
//
//  Created by Denis Malykh on 13.07.2018.
//  Copyright © 2018 Yandex. All rights reserved.
//

import UIKit
import ARKit
import MultipeerConnectivity

protocol ARGameControllerDelegate : class {
    func hit(_ hit: SCNHitTestResult)
}

final class ARGameController {
    private let noticeLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        return lbl
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setTitle("Close", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.titleEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        return btn
    }()

    private let arSceneView: ARSCNView = {
        let scene = ARSCNView(frame: .zero)
        return scene
    }()

    private(set) var board: CheckerBoard?
    private var boards: [UUID: Board] = [:]

    weak var delegate: ARGameControllerDelegate?

    var session: ARSession {
        return arSceneView.session
    }

    init() {
        // super.init()

        let rec = UITapGestureRecognizer(target: self, action: #selector(didTap))
        arSceneView.addGestureRecognizer(rec)
    }

    func placeViews(into vc: ARGameViewController) {
        vc.view.addSubview(arSceneView)
        vc.view.addSubview(closeButton)
        vc.view.addSubview(noticeLabel)
    }

    func layout(bounds: CGRect, safeArea: UIEdgeInsets) {
        arSceneView.frame = bounds
        closeButton.frame = CGRect(
            x: bounds.width - closeButton.intrinsicContentSize.width - 16.0,
            y: safeArea.top + 16.0,
            width: closeButton.intrinsicContentSize.width,
            height: closeButton.intrinsicContentSize.height
        )

        let availableWidth = bounds.width - 2.0 * 16.0 - 8.0 - closeButton.intrinsicContentSize.width
        let lsize = noticeLabel.systemLayoutSizeFitting(
            CGSize(
                width: availableWidth,
                height: UILayoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        noticeLabel.frame = CGRect(
            x: 16.0,
            y: safeArea.top + 16.0,
            width: availableWidth,
            height: lsize.height
        )
    }

    func bind(to vc: ARGameViewController) {
        self.arSceneView.delegate = vc
        self.arSceneView.session.delegate = vc
    }

    func show(notice: String) {
        noticeLabel.text = notice
        noticeLabel.superview?.setNeedsLayout()
    }

    // MARK: - Board management

    func addBoard(_ board: Board, with identifier: UUID) {
        boards[identifier] = board
    }

    func board(for identifier: UUID) -> Board? {
        return boards[identifier]
    }

    func removeBoard(with identifier: UUID) {
        boards[identifier] = nil
    }

    // MARKL: - Checkerboard

    func placeCheckerboard(at pos: SCNVector3) {
        let cb = CheckerBoard()
        cb.position = pos
        arSceneView.scene.rootNode.addChildNode(cb)

        self.board = cb
    }

    // MARK: - World Tracking

    @available(iOS 12, *)
    func setupWorldTracking(worldMap: ARWorldMap?) {
        let conf = ARWorldTrackingConfiguration()
        conf.planeDetection = .horizontal
        conf.initialWorldMap = worldMap

        runWorldTracking(conf: conf, containsWorldMap: worldMap != nil)
    }

    func setupWorldTrackingLegacy() {
        let conf = ARWorldTrackingConfiguration()
        conf.planeDetection = .horizontal

        runWorldTracking(conf: conf, containsWorldMap: false)
    }

    func pauseWorldTracking() {
        arSceneView.session.pause()
    }

    private func runWorldTracking(conf: ARWorldTrackingConfiguration, containsWorldMap: Bool) {
        if containsWorldMap {
            arSceneView.session.run(conf, options: [.resetTracking, .removeExistingAnchors])
        } else {
            arSceneView.session.run(conf)
        }

        arSceneView.showsStatistics = true
        arSceneView.autoenablesDefaultLighting = true
        arSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }

    // MARK: - Event Handlers

    @objc func didTap(_ rec: UITapGestureRecognizer) {
        let pt = rec.location(in: rec.view)
        guard let hit = arSceneView.hitTest(pt).first else {
            return
        }

        delegate?.hit(hit)
    }
}
