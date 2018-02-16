//
//  CheckerBoard.swift
//  ARcheckers
//
//  Created by Denis Malykh on 16.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import ARKit



class CheckerBoardCell : SCNNode {
    let i: Int // 0 - 8
    let j: Int // 0 - 8
    let isBlack : Bool
    
    init(i: Int, j: Int) {
        self.i = i
        self.j = j
        
        let geom = SCNBox(width: cellSize, height: cellHeight, length: cellSize, chamferRadius: 0)

        let mtrl = SCNMaterial()

        isBlack = j % 2 == 0
            ? (i % 2 == 0 ? true : false)
            : (i % 2 == 0 ? false : true)
        
        mtrl.diffuse.contents = isBlack
            ? UIColor(white: 0.25, alpha: 1.0)
            : UIColor(white: 0.75, alpha: 1.0)
        
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

    private var taken: Checker? = nil {
        willSet {
            taken?.isGlowing = false
        }
        didSet {
            taken?.isGlowing = true
        }
    }

    public func took(_ checker: Checker) {
        taken = checker
    }

    public func place(_ cell: CheckerBoardCell) -> Bool {
        if let taken = taken {
            taken.i = cell.i
            taken.j = cell.j

            let moveAction = SCNAction.move(
                to: placeCells(i: cell.i, j: cell.j, y: cellHeight),
                duration: 0.3
            )
            taken.runAction(moveAction)
            
            self.taken = nil
            return true
        }

        return false
    }
    
    private func placeCells(i: Int, j: Int, y: CGFloat = 0) -> SCNVector3{
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
                    let checker = Checker(side:.white, i: i, j: j)
                    checker.position = placeCells(i: i, j: j, y: cellHeight - 0.01)
                    whiteCheckers.append(checker)
                    addChildNode(checker)
                }
                
                if (j > 4 && cell.isBlack){
                    let checker = Checker(side:.black, i: i, j: j)
                    checker.position = placeCells(i: i, j: j, y: cellHeight - 0.01)
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
