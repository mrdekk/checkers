//
//  InitialVC.swift
//  ARcheckers
//
//  Created by user on 17.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class InitialVC: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!

    fileprivate var peerId: MCPeerID? = nil
    fileprivate var isHost: Bool = false

    @IBAction func startNow(_ sender: UIButton) {
        let vc = ARGameViewController(isHost: true)
        present(vc, animated: true, completion: nil)
//        isHost = true
//        Connector.shared.host()
    }
    
    @IBAction func joinNow(_ sender: UIButton) {
        let vc = ARGameViewController(isHost: false)
        present(vc, animated: true, completion: nil)
//        isHost = false
//        Connector.shared.join(in: self)
    }

    @IBAction func justPlay(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showARScene", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Connector.shared.start()
        Connector.shared.delegate1 = self
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showARScene"){
            guard let destVC  = segue.destination as? ViewController else {
                return
            }
            destVC.isHost = isHost
            destVC.peerId = peerId
            Connector.shared.delegate2 = destVC
        }
    }
}

extension InitialVC : ConnectorDelegate1 {
    func didConnected(to peer: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let sself = self else { return }
            sself.peerId = peer
            sself.performSegue(withIdentifier: "showARScene", sender: self)
        }
    }
}
