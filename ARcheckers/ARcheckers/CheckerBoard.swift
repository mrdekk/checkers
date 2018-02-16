//
//  CheckerBoard.swift
//  ARcheckers
//
//  Created by Denis Malykh on 16.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import ARKit



class CheckerBoardCell : SCNNode {
    private let i: Int // 0 - 8
    private let j: Int // 0 - 8
    public let isBlack : Bool
    
    init(i: Int, j: Int) {
        self.i = i
        self.j = j
        
        let geom = SCNBox(width: cellSize, height: cellHeight, length: cellSize, chamferRadius: 0)

        let mtrl = SCNMaterial()

        isBlack = j % 2 == 0
            ? (i % 2 == 0 ? true : false)
            : (i % 2 == 0 ? false : true)
        
        mtrl.diffuse.contents = isBlack ? UIColor.black : UIColor.white
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
    private var whiteCheckers : [Checker] = []
    private var blackCheckers : [Checker] = []
    
    
    func placeCells(i : Int, j: Int, y: CGFloat = 0) -> SCNVector3{
        return SCNVector3(
            -0.5*boardSize + CGFloat(i) * cellSize,
            y,
            -0.5*boardSize + CGFloat(j) * cellSize
        )
    }
    
    override init() {
        super.init()
        for j in 0...8 {
            for i in 0...8 {
                let cell = CheckerBoardCell(i: i, j: j)
                cell.position = placeCells(i: i, j:j)
                cells.append(cell)
                addChildNode(cell)
                
                if (j < 3 && cell.isBlack){
                    let checker = Checker(side:.white)
                    checker.position = placeCells(i: i, j:j, y:cellHeight-0.01)
//                    print(checker.pivot)
                    whiteCheckers.append(checker)
                    addChildNode(checker)
                }
                
                if (j > 4 && cell.isBlack){
                    let checker = Checker(side:.black)
                    checker.position = placeCells(i: i, j:j, y:cellHeight-0.01)
                    blackCheckers.append(checker)
                    addChildNode(checker)
                }
                
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

private let cellSize = CGFloat(0.05)
private let boardSize = CGFloat(0.4)
private let cellHeight = CGFloat(0.03)
