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
    public var i: Int
    public var j: Int
    public var k: Int {
        return j * 8 + i
    }

    var isGlowing: Bool = false {
        didSet {
            guard let geom = geometry, let mtrl = geom.materials.first else { return }
            mtrl.fillMode = isGlowing ? .lines : .fill
        }
    }
    
    init(side : Side, i: Int, j: Int) {
        self.side = side
        self.i = i
        self.j = j

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

private let checkerSize = CGFloat(0.04)
