//
//  InitialVC.swift
//  ARcheckers
//
//  Created by user on 17.02.18.
//  Copyright © 2018 Yandex. All rights reserved.
//

import UIKit
import GameKit

class InitialVC: UIViewController, GKGameCenterControllerDelegate, GKLocalPlayerListener, GKTurnBasedMatchmakerViewControllerDelegate    {
    
    
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!

    
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
    
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        viewController.dismiss(animated: true, completion:nil)
    }
    
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true, completion:nil)
    }
    
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match : GKTurnBasedMatch) {
        if (!gcMatchStarted){
            gcMatchStarted = true
            viewController.dismiss(animated: true, completion: {
                self.performSegue(withIdentifier: "showARScene", sender: match)
            })
        }
        //
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showARScene"){
            guard let destVC  = segue.destination as? ViewController else {
                return
            }
            guard let match = sender as? GKTurnBasedMatch else {
                return
            }
            destVC.match = match
        }
    }
//    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFindHostedPlayers players : Array) {
//
//    }
    
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
        gcMatchRequest.minPlayers = 2
        gcMatchRequest.maxPlayers = 2
        gcMatchRequest.inviteMessage = "Hello, Let's play checkers"
        let gcVC = GKTurnBasedMatchmakerViewController.init(matchRequest: gcMatchRequest)
        gcVC.showExistingMatches = true
        gcVC.turnBasedMatchmakerDelegate = self
        present(gcVC, animated: true, completion: nil)
        
    }
    

}
