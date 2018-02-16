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

    var k: Int {
        return j * 8 + i
    }

    var isGlowing: Bool = false {
        didSet {
            guard let geom = geometry, let mtrl = geom.materials.first else { return }
            mtrl.fillMode = isGlowing ? .lines : .fill
        }
    }
    
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

struct Move {
    typealias Step = (i: Int, j: Int, took: Int?)
    let steps: [Step]
    init(steps: [Step]) {
        self.steps = steps
    }

    init(i: Int, j: Int, took: Int?) {
        self.init(steps: [(i: i, j: j, took: took)])
    }

    var destination: Step? {
        return steps.last
    }

    func merged(with move: Move) -> Move {
        return Move(steps: steps + move.steps)
    }
}

class CheckerBoard : SCNNode {

    private var cells: [Int: CheckerBoardCell] = [:]
    private var whiteCheckers : [Int: Checker] = [:]
    private var blackCheckers : [Int: Checker] = [:]

    private var taken: Checker? = nil {
        willSet {
            taken?.isGlowing = false
        }
        didSet {
            taken?.isGlowing = true
        }
    }
    private var moves: [Move] = []

    public func highlight(moves: [Move]) {
        let dest = moves.allowed
        for (pos, cell) in cells {
            cell.isGlowing = dest.contains(pos)
        }
    }

    public func took(_ checker: Checker) -> [Move] {
        taken = checker
        moves = taken.flatMap {
            search($0, i: $0.i, j: $0.j, takes: false, blocked: Set<Int>())
        } ?? []
        return moves
    }

    public func place(_ cell: CheckerBoardCell) -> Bool {
        let dest = moves.allowed
        guard dest.contains(cell.j * 8 + cell.i) else {
            return false
        }

        let pmove = moves.first { (move) -> Bool in
            guard let dest = move.destination else { return false }
            return dest.i == cell.i && dest.j == cell.j
        }
        if let taken = taken, let move = pmove {
            let pso = taken.j * 8 + taken.i
            let psn = cell.j * 8 + cell.i

            taken.i = cell.i
            taken.j = cell.j

            switch taken.side {
            case .white:
                whiteCheckers[pso] = nil
                whiteCheckers[psn] = taken

            case .black:
                blackCheckers[pso] = nil
                blackCheckers[psn] = taken
            }

            let actions: [SCNAction] = move.steps.flatMap {
                if let took = $0.took {
                    let tj = took / 8
                    let ti = took % 8
                    let seq: [SCNAction] = [
                        SCNAction.move(
                            to: placeCells(i: ti, j: tj, y: 2 * checkerY),
                            duration: 0.3
                        ),
                        SCNAction.run({ [weak self] _ in
                            guard let sself = self else { return }
                            if let ch = sself.whiteCheckers[took] {
                                ch.removeFromParentNode()
                                sself.whiteCheckers[took] = nil
                            }
                            if let ch = sself.blackCheckers[took] {
                                ch.removeFromParentNode()
                                sself.blackCheckers[took] = nil
                            }
                        }),
                        SCNAction.move(
                            to: placeCells(i: $0.i, j: $0.j, y: checkerY),
                            duration: 0.3
                        )
                    ]
                    return SCNAction.sequence(seq)
                } else {
                    return SCNAction.move(
                        to: placeCells(i: $0.i, j: $0.j, y: checkerY),
                        duration: 0.3
                    )
                }
            }
            if !actions.isEmpty {
                let sequence = SCNAction.sequence(actions)
                taken.runAction(sequence)
            }
            
            self.taken = nil
            highlight(moves: [])
            return true
        }

        return false
    }

    func isWin(side: Checker.Side) -> Bool {
        switch side {
        case .white:
            if blackCheckers.isEmpty {
                return true
            }
            let moves = blackCheckers.values.flatMap {
                search($0, i: $0.i, j: $0.j, takes: false, blocked: Set<Int>())
            }
            return moves.isEmpty

        case .black:
            if whiteCheckers.isEmpty {
                return true
            }
            let moves = whiteCheckers.values.flatMap {
                search($0, i: $0.i, j: $0.j, takes: false, blocked: Set<Int>())
            }
            return moves.isEmpty
        }
    }

    private func placeCells(i: Int, j: Int, y: CGFloat = 0) -> SCNVector3{
        return SCNVector3(
            -0.5*boardSize + CGFloat(i) * cellSize,
            y,
            0.5*boardSize - CGFloat(j) * cellSize
        )
    }

    private func isEmptyAt(i: Int, j: Int) -> Checker.Side? {
        guard i >= 0, i < 8, j >= 0, j < 8 else { return nil }
        let psx = j * 8 + i
        if whiteCheckers[psx] != nil {
            return .white
        }
        if blackCheckers[psx] != nil {
            return .black
        }
        return nil
    }

    private func search(_ checker: Checker, i: Int, j: Int, takes: Bool, blocked: Set<Int>) -> [Move] {
        var res = [Move]()

        if !takes {
            switch checker.side {
            case .white:
                if i - 1 >= 0, j + 1 < 8, isEmptyAt(i: i - 1, j: j + 1) == nil {
                    res.append(Move(i: i - 1, j: j + 1, took: nil))
                }
                if i + 1 < 8, j + 1 < 8, isEmptyAt(i: i + 1, j: j + 1) == nil {
                    res.append(Move(i: i + 1, j: j + 1, took: nil))
                }

            case .black:
                if i - 1 >= 0, j - 1 >= 0, isEmptyAt(i: i - 1, j: j - 1) == nil {
                    res.append(Move(i: i - 1, j: j - 1, took: nil))
                }
                if i + 1 < 8, j - 1 >= 0, isEmptyAt(i: i + 1, j: j - 1) == nil {
                    res.append(Move(i: i + 1, j: j - 1, took: nil))
                }
            }
        }

        let nblock = blocked.union([j * 8 + i])

        // NOTE: down left
        if i - 1 >= 0, j - 1 >= 0, let e = isEmptyAt(i: i - 1, j: j - 1), checker.side != e {
            // possible take
            if i - 2 >= 0, j - 2 >= 0, isEmptyAt(i: i - 2, j: j - 2) == nil, !blocked.contains((j - 2) * 8 + i - 2) {
                let curr = Move(i: i - 2, j: j - 2, took: (j - 1) * 8 + i - 1)
                let subst = search(checker, i: i - 2, j: j - 2, takes: true, blocked: nblock)

                res.append(curr)
                res.append(contentsOf: subst.map { curr.merged(with: $0) })
            }
        }

        // NOTE: down right
        if i + 1 < 8, j - 1 >= 0, let e = isEmptyAt(i: i + 1, j: j - 1), checker.side != e {
            if i + 2 < 8, j - 2 >= 0, isEmptyAt(i: i + 2, j: j - 2) == nil, !blocked.contains((j - 2) * 8 + i + 2) {
                let curr = Move(i: i + 2, j: j - 2, took: (j - 1) * 8 + i + 1)
                let subst = search(checker, i: i + 2, j: j - 2, takes: true, blocked: nblock)

                res.append(curr)
                res.append(contentsOf: subst.map { curr.merged(with: $0) })
            }
        }

        // NOTE: up left
        if i - 1 >= 0, j + 1 < 8, let e = isEmptyAt(i: i - 1, j: j + 1), checker.side != e {
            if i - 2 >= 0, j + 2 < 8, isEmptyAt(i: i - 2, j: j + 2) == nil, !blocked.contains((j + 2) * 8 + i - 2) {
                let curr = Move(i: i - 2, j: j + 2, took: (j + 1) * 8 + i - 1)
                let subst = search(checker, i: i - 2, j: j + 2, takes: true, blocked: nblock)

                res.append(curr)
                res.append(contentsOf: subst.map { curr.merged(with: $0) })
            }
        }

        // NOTE: up right
        if i + 1 < 8, j + 1 < 8, let e = isEmptyAt(i: i + 1, j: j + 1), checker.side != e {
            if i + 2 < 8, j + 2 < 8, isEmptyAt(i: i + 2, j: j + 2) == nil, !blocked.contains((j + 2) * 8 + i + 2) {
                let curr = Move(i: i + 2, j: j + 2, took: (j + 1) * 8 + i + 1)
                let subst = search(checker, i: i + 2, j: j + 2, takes: true, blocked: nblock)

                res.append(curr)
                res.append(contentsOf: subst.map { curr.merged(with: $0) })
            }
        }

        return res
    }
    
    override init() {
        super.init()
        for j in 0..<8 {
            for i in 0..<8 {
                let cell = CheckerBoardCell(i: i, j: j)
                cell.position = placeCells(i: i, j:j)
                cells[j * 8 + i] = cell
                addChildNode(cell)
                
                if (j < 3 && cell.isBlack){
                    let checker = Checker(side:.white, i: i, j: j)
                    checker.position = placeCells(i: i, j: j, y: checkerY)
                    whiteCheckers[j * 8 + i] = checker
                    addChildNode(checker)
                }
                
                if (j > 4 && cell.isBlack){
                    let checker = Checker(side:.black, i: i, j: j)
                    checker.position = placeCells(i: i, j: j, y: checkerY)
                    blackCheckers[j * 8 + i] = checker
                    addChildNode(checker)
                }
                
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

private extension Sequence where Iterator.Element == Move {
    var allowed: Set<Int> {
        return Set(self.flatMap {
            guard let dest = $0.destination else { return nil }
            return dest.j * 8 + dest.i
        })
    }
}

private let cellSize = CGFloat(0.05)
private let boardSize = CGFloat(0.4)
private let cellHeight = CGFloat(0.03)
private let checkerY = cellHeight - 0.01
