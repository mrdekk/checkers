//
//  Checker.swift
//  ARcheckers
//
//  Created by user on 16.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import ARKit

class Checker: SCNNode {

    enum Side {
        case white
        case black
        
    }
    
    public let side : Side
    private let checkerSize = CGFloat(0.04)
    
    init(side : Side) {
        self.side = side
        super.init()
        let geom = SCNCylinder(radius: checkerSize/2, height: 0.01)
        
        let mtrl = SCNMaterial()
        
        let clr = side == .white ? UIColor.white : UIColor.black
        mtrl.diffuse.contents = clr
        geom.materials = [mtrl]
        self.geometry = geom
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
