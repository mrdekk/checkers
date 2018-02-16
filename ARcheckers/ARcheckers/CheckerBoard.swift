//
//  CheckerBoard.swift
//  ARcheckers
//
//  Created by Denis Malykh on 16.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import ARKit

class CheckerBoard : SCNNode {

    private let node: SCNNode

    override init() {
        let geom = SCNBox(width: 0.4, height: 0.4, length: 0.03, chamferRadius: 0.01)

        let mtrl = SCNMaterial()

        let clr = UIColor.red
        mtrl.diffuse.contents = clr
        geom.materials = [mtrl]

        node = SCNNode(geometry: geom)
        node.position = SCNVector3(0, 0, 0)
        node.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)

        super.init()
        
        addChildNode(node)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
