//
//  Board.swift
//  Checkers
//
//  Created by Denis Malykh on 28.01.18.
//  Copyright © 2018 MrDekk. All rights reserved.
//

import Foundation
import ARKit

class Board : SCNNode {

    private(set) var anchor: ARPlaneAnchor
    private(set) var planeGeometry: SCNPlane? = nil

    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()

        let geom = SCNPlane(
            width: CGFloat(anchor.extent.x),
            height: CGFloat(anchor.extent.z)
        )
        self.planeGeometry = geom

        let mtrl = SCNMaterial()
//        let img = UIImage(named: "board")
//        mtrl.diffuse.contents = img
        let clr = UIColor.cyan.withAlphaComponent(0.25)
        mtrl.diffuse.contents = clr
        geom.materials = [mtrl]

        let node = SCNNode(geometry: geom)
        node.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        node.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)

        updateTexture()
        addChildNode(node)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func update(_ anchor: ARPlaneAnchor) {
        planeGeometry?.width = CGFloat(anchor.extent.x)
        planeGeometry?.height = CGFloat(anchor.extent.z)

        position = SCNVector3(anchor.center.x, 0.0, anchor.center.z)
        updateTexture()
    }

    private func updateTexture() {
        let w = planeGeometry?.width ?? 0
        let h = planeGeometry?.height ?? 0

        if let mtrl = planeGeometry?.materials.first {
            mtrl.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(w), Float(h), 1)
            mtrl.diffuse.wrapS = .repeat
            mtrl.diffuse.wrapT = .repeat
        }
    }
}
