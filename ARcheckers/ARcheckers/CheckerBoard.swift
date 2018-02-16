//
//  CheckerBoard.swift
//  ARcheckers
//
//  Created by Denis Malykh on 16.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import ARKit

class CheckerBoardCell : SCNNode {
    private(set) var i: Int = 0 // 0 - 8
    private(set) var j: Int = 0 // 0 - 8

    init(i: Int, j: Int) {
        self.i = i
        self.j = j

        let geom = SCNBox(width: cellSize, height: 0.03, length: cellSize, chamferRadius: 0)

        let mtrl = SCNMaterial()

        let clr = j % 2 == 0
            ? (i % 2 == 0 ? UIColor.black : UIColor.white)
            : (i % 2 == 0 ? UIColor.white : UIColor.black)
        mtrl.diffuse.contents = clr
        geom.materials = [mtrl]

        super.init()

        self.geometry = geom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CheckerBoard : SCNNode {

    private var cells: [CheckerBoardCell] = []

    override init() {
        for j in 0...8 {
            for i in 0...8 {
                let cell = CheckerBoardCell(i: i, j: j)
                cell.position = SCNVector3(
                    -0.2 + CGFloat(i) * cellSize,
                    0,
                    -0.2 + CGFloat(j) * cellSize
                )

                cells.append(cell)
            }
        }

        super.init()

        for cell in cells {
            addChildNode(cell)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

private let cellSize = CGFloat(0.05)
