//
//  HUDNode.swift
//  SpaceRun
//
//  Created by Pope, Drewry on 5/10/17.
//  Copyright © 2017 assignmentInClass5 Drew Pope. All rights reserved.
//

import SpriteKit

class HUDNode: SKNode {
    
    //Create a heads-up-display that will hold all of our display areas
    //once the node is added to the scene, we'll tell it to lay out its child
    //nodes. The child nodes will not contain labels as we will use the blank
    //nodes as group containers and lay out the label nodesinside of them.
    // We will left-align the score and right-align the elapsed game time.
    // Eventually a count-down timer will be added for powerups and a health
    // bar for ship health.
    private let HealthGroupName = "healthGroup"
    private let HealthValueName = "healthValue"
    
    private let ScoreGroupName = "scoreGroup"
    private let ScoreValueName = "scoreValue"
    
    private let ElapsedGroupName = "elapsedGroup"
    private let ElapsedValueName = "elapsedValue"
    private let TimerActionName = "elapsedGameTimer"
    
    private let PowerupGroupName = "powerupGroup"
    private let PowerupValueName = "powerupValue"
    private let PowerupTimerActionName = "showPowerupTimer"
    
    var elapsedTime: TimeInterval = 0/0
    var score: Int = 0
    
    lazy private var scoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    lazy private var timeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    override init() {
        super.init()
    
        // build an empty sk node and name it so that
        // we can get a reference to it later
        let scoreGroup = SKNode()
        scoreGroup.name = ScoreGroupName
        
        let scoreTitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreTitle.fontSize = 12.0
        scoreTitle.fontColor = SKColor.white
        scoreTitle.horizontalAlignmentMode = .left
        scoreTitle.verticalAlignmentMode = .bottom
        scoreTitle.text = "SCORE"
        scoreTitle.position = CGPoint(x:0.0, y: 4.0)
        scoreGroup.addChild(scoreTitle)
        
        let scoreValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreValue.fontSize = 20.0
        scoreValue.fontColor = SKColor.white
        scoreValue.horizontalAlignmentMode = .left
        scoreValue.verticalAlignmentMode = .top
        scoreValue.name = ScoreValueName
        scoreValue.text = "0"
        scoreValue.position = CGPoint(x:0.0, y: -4.0)
        scoreGroup.addChild(scoreValue)
        
        // Add scoreGroup as child of our HUD node
        addChild(scoreGroup)

// --------------
    
        // build an empty sk node and name it so that
        // we can get a reference to it later
        let elapsedGroup = SKNode()
        elapsedGroup.name = ElapsedGroupName
        
        let elapsedTitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        elapsedTitle.fontSize = 12.0
        elapsedTitle.fontColor = SKColor.white
        elapsedTitle.horizontalAlignmentMode = .center
        elapsedTitle.verticalAlignmentMode = .bottom
        elapsedTitle.text = "TIME"
        elapsedTitle.position = CGPoint(x:0.0, y: 4.0)
        elapsedGroup.addChild(elapsedTitle)
        
        let elapsedValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        elapsedValue.fontSize = 20.0
        elapsedValue.fontColor = SKColor.white
        elapsedValue.horizontalAlignmentMode = .center
        elapsedValue.verticalAlignmentMode = .top
        elapsedValue.name = ElapsedValueName
        elapsedValue.text = "0.0s"
        elapsedValue.position = CGPoint(x:0.0, y: -4.0)
        elapsedGroup.addChild(elapsedValue)
        
        // Add elapsedGroup as child of our HUD node
        addChild(elapsedGroup)
        // --------------
        
        // build an empty sk node and name it so that
        // we can get a reference to it later
        let powerupGroup = SKNode()
        powerupGroup.name = PowerupGroupName
        
        let powerupTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        powerupTitle.fontSize = 14.0
        powerupTitle.fontColor = SKColor.red
        powerupTitle.verticalAlignmentMode = .bottom
        powerupTitle.text = "Power-up!"
        powerupTitle.position = CGPoint(x:0.0, y: 4.0)
        powerupGroup.addChild(powerupTitle)
        
        //set up actions to make power-down time pulse
        powerupTitle.run(SKAction.repeatForever(SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.3), SKAction.scale(to: 1.0, duration: 0.3)])))
        
        let powerupValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        powerupValue.fontSize = 20.0
        powerupValue.fontColor = SKColor.red
        powerupValue.verticalAlignmentMode = .top
        powerupValue.name = PowerupValueName
        powerupValue.text = "0.0s left"
        powerupValue.position = CGPoint(x:0.0, y: -4.0)
        powerupGroup.addChild(powerupValue)
        
        //make invisible to start
        powerupGroup.alpha = 0.0
        
        // Add powerupGroup as child of our HUD node
        addChild(powerupGroup)
        
        // --------------
        // build an empty sk node and name it so that
        // we can get a reference to it later
        let healthGroup = SKNode()
        healthGroup.name = HealthGroupName
        
        let healthTitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        healthTitle.fontSize = 14.0
        healthTitle.fontColor = SKColor.cyan
        healthTitle.horizontalAlignmentMode = .left
        healthTitle.verticalAlignmentMode = .bottom
        healthTitle.text = "HEALTH"
        healthTitle.position = CGPoint(x:0.0, y: 4.0)
        healthGroup.addChild(healthTitle)
        
        let healthValue = SKLabelNode(fontNamed: "AvenirNext-Bold")
        healthValue.fontSize = 20.0
        healthValue.fontColor = SKColor.cyan
        healthValue.horizontalAlignmentMode = .left
        healthValue.verticalAlignmentMode = .top
        healthValue.name = HealthValueName
        healthValue.text = "50%"
        healthValue.position = CGPoint(x:0.0, y: -4.0)
        healthGroup.addChild(healthValue)
        
        addChild(healthGroup)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //group nodes are centered on screen, but we need to fix that.
    //we need to create a layout method that will properly position
    //the groups.
    func layoutForScene() {
        if let scene = scene {
            let sceneSize = scene.size
            
            //the following will calculate each position
            var groupSize = CGSize.zero
            var scoreSize = CGFloat()
            
            if let scoreGroup = childNode(withName: ScoreGroupName) {
                groupSize = scoreGroup.calculateAccumulatedFrame().size
                scoreSize = groupSize.height // used for placing healthgroup
                scoreGroup.position = CGPoint(x: -sceneSize.width/2.0 + 40.0, y: sceneSize.height/2.0 - groupSize.height)
                
            } else {
                assert(false, "No Score Group Node was found in Node Tree")
            }
            
            if let elapsedGroup = childNode(withName: ElapsedGroupName) {
                groupSize = elapsedGroup.calculateAccumulatedFrame().size
                
                elapsedGroup.position = CGPoint(x: sceneSize.width/2.0 - 50.0, y: sceneSize.height/2.0 - groupSize.height)
                
            } else {
                assert(false, "No Elapsed Group Node was found in Node Tree")
            }
            
            if let powerUpGroup = childNode(withName: PowerupGroupName) {
                groupSize = powerUpGroup.calculateAccumulatedFrame().size
                
                powerUpGroup.position = CGPoint(x: 0.0, y: sceneSize.height/2.0 - groupSize.height)
                
            } else {
                assert(false, "No Powerup Group Node was found in Node Tree")
            }
            
            if let healthGroup = childNode(withName: HealthGroupName) {
                groupSize = healthGroup.calculateAccumulatedFrame().size
                
                healthGroup.position = CGPoint(x: -sceneSize.width/2.0 + 40.0, y: sceneSize.height/2.0 - (groupSize.height + scoreSize + CGFloat(sceneSize.height/20)))
                
            } else {
                assert(false, "No Health Group Node was found in Node Tree")
            }
        }
    }
    
    //show our powerup timer countdown
    func showPowerupTimer(_ time: TimeInterval) {
        
        if let powerUpGroup = childNode(withName: PowerupGroupName) {

            //Remove any existing action with key powerup
            self.removeAction(forKey: PowerupTimerActionName)
            
            if let powerupValue = powerUpGroup.childNode(withName: PowerupValueName) as! SKLabelNode? {
                
                //Run the countdown
                //action repeats every 0.05seconds in order
                //to update powerupvalue label text
                let start = Date.timeIntervalSinceReferenceDate
                
                let block = SKAction.run {
                    [weak self] in
                    
                    if let weakSelf = self {
                        let elapsedTime = Date.timeIntervalSinceReferenceDate - start
                        let timeLeft = max(time - elapsedTime, 0)
                        let timeLeftFormat = weakSelf.timeFormatter.string(from: NSNumber(value: timeLeft))!
                        powerupValue.text = "\(timeLeftFormat)s left"
                    }
                }
                
                //actions
                let countDownSequence = SKAction.sequence([block, SKAction.wait(forDuration: 0.05)])
                let countDown = SKAction.repeatForever(countDownSequence)
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 1.0)
                let stopAction = SKAction.run({() -> Void in
                    powerUpGroup.removeAction(forKey: self.PowerupTimerActionName)
                })
                
                let visuals = SKAction.sequence([fadeIn, SKAction.wait(forDuration: time), fadeOut, stopAction])
                powerUpGroup.run(SKAction.group([countDown, visuals]), withKey: self.PowerupTimerActionName)                
            }
        }
    }
    
    func addPoints(_ points: Int) {
        score += points
        //Look up score value
        if let scoreValue = childNode(withName: "\(ScoreGroupName)/\(ScoreValueName)") as! SKLabelNode? {
            //Format our score value using the thousands separator
            //so lets use our cached self.scoreFormatter
            scoreValue.text = scoreFormatter.string(from: NSNumber(value: score))
            //scale node up then down
            scoreValue.run(SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.02), SKAction.scale(to: 1.0, duration: 0.07)]))
        }
    }
    
    func startGame() {
        let startTime = Date.timeIntervalSinceReferenceDate
        
        if let elapsedValue = childNode(withName: "\(ElapsedGroupName)/\(ElapsedValueName)") as! SKLabelNode? {
            
            let update = SKAction.run({
                [weak self] in
                
                if let weakSelf = self {
                    let currentTime = Date.timeIntervalSinceReferenceDate
                    weakSelf.elapsedTime = currentTime - startTime
                    elapsedValue.text = weakSelf.timeFormatter.string(from: NSNumber(value: weakSelf.elapsedTime))
                    
                    
                }
                
            })
            
            let updateAndDelay = SKAction.sequence([update, SKAction.wait(forDuration: 0.05)])
            let timer = SKAction.repeatForever(updateAndDelay)
            
            run(timer, withKey: TimerActionName)
        }
    }
    
    func endGame() {
        removeAction(forKey: TimerActionName)
        
        // If the game ends while a powerup is in pogress, fade
        if let powerupGroup = childNode(withName: PowerupGroupName) {
            powerupGroup.removeAction(forKey: PowerupTimerActionName)
            powerupGroup.run(SKAction.fadeAlpha(to: 0.0, duration: 0.3))
        }
    }
    func showHealth(_ health: Double) {
        //Look up score value
        if let healthValue = childNode(withName: "\(HealthGroupName)/\(HealthValueName)") as! SKLabelNode? {
            //Format our score value using the thousands separator
            //so lets use our cached self.scoreFormatter
            healthValue.text = "\(100 * (health/4))%"
            //scale node up then down
            healthValue.run(SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.04), SKAction.scale(to: 1.0, duration: 0.07)]))
        }
    }
}
