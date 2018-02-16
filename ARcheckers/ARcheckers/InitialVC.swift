//
//  InitialVC.swift
//  ARcheckers
//
//  Created by user on 17.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import UIKit
import GameKit

class InitialVC: UIViewController, GKGameCenterControllerDelegate, GKLocalPlayerListener, GKMatchmakerViewControllerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    
    public var gcMatch : GKMatch? = nil
    
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    var gcMatchStarted = false
    
    var score = 0
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "com.leaderboard.checkerAR"
    
    @IBAction func startNow(_ sender: UIButton) {
        createMatch()
    }
    
    @IBAction func joinNow(_ sender: UIButton) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Call the GC authentication controller
        authenticateLocalPlayer()
        // Do any additional setup after loading the view.
    }

    // MARK: - AUTHENTICATE LOCAL PLAYER
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil {
                        print(error)
                    } else {
                        self.gcDefaultLeaderBoard = leaderboardIdentifer!
                    }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error)
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {

    }
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true, completion:nil)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true, completion:nil)
    }
    
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match : GKMatch) {
        gcMatch = match
//        match.delegate = self
        if (!gcMatchStarted && gcMatch?.expectedPlayerCount == 0){
            gcMatchStarted = true
            viewController.dismiss(animated: true, completion: {
                self.performSegue(withIdentifier: "showARScene", sender: self)
            })
        }
        //
    }
    
    // MARK: - OPEN GAME CENTER LEADERBOARD
    func checkGCLeaderboard() {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = LEADERBOARD_ID
        present(gcVC, animated: true, completion: nil)
    }

    func createMatch() {
        let gcMatchRequest = GKMatchRequest.init()
        gcMatchRequest.defaultNumberOfPlayers = 2
        gcMatchRequest.inviteMessage = "Hello, Let's play checkers"
        guard let gcVC = GKMatchmakerViewController.init(matchRequest: gcMatchRequest) else {
            return
        }
        gcVC.matchmakerDelegate = self
        present(gcVC, animated: true, completion: nil)
        
    }
    

}
