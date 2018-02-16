//
//  Checker.swift
//  ARcheckers
//
//  Created by user on 16.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import ARKit

class Checker: SCNNode {

    public let isWhite = true
    
    
    override init() {
        super.init()
        let geom = SCNCylinder(radius: 0.02, height: 0.01)
        
        let mtrl = SCNMaterial()
        
        let clr = isWhite ? UIColor.white : UIColor.black
        mtrl.diffuse.contents = clr
        geom.materials = [mtrl]

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
