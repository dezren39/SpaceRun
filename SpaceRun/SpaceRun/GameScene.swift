//
//  GameScene.swift
//  SpaceRun
//
//  Created by Pope, Drewry on 5/1/17.
//  Copyright © 2017 assignmentInClass5 Drew Pope. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    //class property
	static var shipHealthRate: Double = 2.0
    
    //instance property
    private let SpaceshipNodeName = "ship"
    private let PhotonTorpedoNodeName = "photon"
    private let ObstacleNodeName = "obstacle"
    private let PowerUpNodeName = "powerup"
    private let HealthPowerUpNodeName = "shipHealth"
    private let HUDNodeName = "hud"
    
    private weak var shipTouch: UITouch?
    
    private var lastUpdateShipX: CGFloat = 0
    private var shipDelta: CGFloat = 0
    
    private var lastUpdateTime: TimeInterval = 0
    private var lastShotFireTime: TimeInterval = 0
    
    private var dropRate: UInt32 = 16
    private var shipFireRate: Double = 0.5
    private var defaultFireRate: Double = 0.5
    
    private var toEnemyRatio: UInt32 = 4
    private var toAsteroidRatio: UInt32 = 48
    private var toHealthRatio:UInt32 = 96 //60
    private var enemyRatio:UInt32 = 50
    
    private let shipSpeed = CGFloat(400)
    private let defaultDropRate: UInt32 = 26 //66 lastL
    private let defaultScore: Double = 100
    
    private let powerUpDuration: TimeInterval = 5.0
    
    private let startTime: TimeInterval = Date.timeIntervalSinceReferenceDate
    
    //properties to hold sound actions. sounds
    // are preloaded into these properties.
    private let shootSound: SKAction = SKAction.playSoundFileNamed("laserShot.wav", waitForCompletion: false)
    
    private let obstacleExplodeSound: SKAction = SKAction.playSoundFileNamed("darkExplosion.wav", waitForCompletion: false)
    
    private let shipExplodeSound: SKAction = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
    
    //We will be using explosion particle emitters over and over, we dont want to load them from the .sks files
    //every time we need them, so instead we'll create properties to cache them like for sounds
    private let shipExplodeTemplate:SKEmitterNode = SKEmitterNode.nodeWithFile("shipExplode")!
    private let obstacleExplodeTemplate:SKEmitterNode = SKEmitterNode.nodeWithFile("obstacleExplode")!
    
    //Define an initializer method for this class.
    override init(size: CGSize) {
        super.init(size: size)
        setupGame(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupGame(size: CGSize) {
        let ship = SKSpriteNode(imageNamed: "Spaceship.png")
        ship.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        ship.size = CGSize(width: 40, height: 40)
        ship.name = SpaceshipNodeName
        addChild(ship) //add node to scenegraph nodetree
        
        if let thruster = SKEmitterNode.nodeWithFile("thruster.sks"){
            thruster.position = CGPoint(x: 0.0, y: -20.0)
            ship.addChild(thruster)
        }
        
        let hudNode = HUDNode()
        hudNode.name = HUDNodeName
        hudNode.zPosition = 100.0
        hudNode.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        addChild(hudNode)
        // lay out the score and time labels of the hud.
        hudNode.layoutForScene()
        // start game
        hudNode.startGame()
        
        addChild(StarField())
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
        /*    let touchPoint = touch.location(in: self)
            if let ship = self.childNode(withName: SpaceshipNodeName) {
                ship.position = touchPoint
            }*/
            self.shipTouch = touch
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        //Game gets harder
        if self.dropRate < 28 { //until 30 sec
            self.dropRate = defaultDropRate + UInt32((Date.timeIntervalSinceReferenceDate - startTime)/15)
        } else if self.dropRate < 32 { //until 60 sec
            self.dropRate = defaultDropRate + UInt32((Date.timeIntervalSinceReferenceDate - startTime)/10)
            print("HARDMODE")
        } else if self.dropRate < 44 { //until 90 sec
            self.dropRate = defaultDropRate + UInt32((Date.timeIntervalSinceReferenceDate - startTime)/5)
            print("HARDMODE2")
        } else if self.dropRate < 66 { //120 up
            self.dropRate = defaultDropRate + UInt32((Date.timeIntervalSinceReferenceDate - startTime)/3)
            print("EXTREME MOOOOODE")
        } else {
            self.dropRate = defaultDropRate + UInt32((Date.timeIntervalSinceReferenceDate - startTime))
            print("IT KEEPS GOING!!!!!!111!1!!!!1!")
            
            if self.shipFireRate != defaultFireRate {
                self.defaultFireRate = 0.4
            } else {
                self.defaultFireRate = 0.4
                self.shipFireRate = self.defaultFireRate
            }
            self.toEnemyRatio = 3
            self.toAsteroidRatio = 70
            self.toHealthRatio = 98
        }
        print("\(self.dropRate)   \(Date.timeIntervalSinceReferenceDate - startTime)")
        
        let timeDelta = currentTime - lastUpdateTime
    
        if let ship = self.childNode(withName: SpaceshipNodeName) {
            //ShipDelta updated for specific enemy which requires this info. Could have used touchPoint, but didn't.
            shipDelta = ship.position.x - self.lastUpdateShipX
            shipDelta = shipDelta == 0 ? CGFloat(arc4random_uniform(2)) - 0.5 : shipDelta
            
        // If the touch is still there (since shipTouch is a weak reference) it will automatically be set to nil by the touch-handling system. when it releases touchs after they are done.
            if (shipTouch != nil) {
            // Call a method to reposition the ship which will
            // move the ship a little ways along the path toward
            // the touch point.
                moveShipTowardPoint(touchPoint: shipTouch!.location(in: self), timeDelta: timeDelta)
 
                // if the distance left to travel is greater than 6 points then keep moving the ship. otherwise, stop moving the ship.
                // because we may experience "jitter"
                
                //We want photons when finger is in contact with screen AND if the idfference in time is greater than 500 ms
                if currentTime - lastShotFireTime > shipFireRate {
                    shoot()
                    lastShotFireTime = currentTime
                }
            }
        
            // Release obstacles some percentage of the time a frame is drawn.
            if arc4random_uniform(1000) <= dropRate {
                dropThing()
            }
        
            //update stored shipx
            lastUpdateShipX = ship.position.x
            
            // Collision Checks
            checkCollisions()
        }
        lastUpdateTime = currentTime
    }
    
    //Collision Detection
    func checkCollisions(){
        if let ship = self.childNode(withName: SpaceshipNodeName) {
        	enumerateChildNodes(withName: HealthPowerUpNodeName) {
                healthPowerUp, _ in

               // stop.pointee = true //Only  take one healthpowerup / framerate plz.
                
                if ship.intersects(healthPowerUp) {
                    GameScene.shipHealthRate = 4
                    
                    if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                        hud.showHealth(GameScene.shipHealthRate)
                    }
                    healthPowerUp.removeFromParent()
                }
            }

            enumerateChildNodes(withName: PowerUpNodeName) {
                myPowerUp, _ in
                
                if ship.intersects(myPowerUp) {
                    if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                        hud.showPowerupTimer(self.powerUpDuration)
                    }
                    
                    myPowerUp.removeFromParent()
                    self.shipFireRate = 0.1
                    
                    //After delay, undo powerup.
                    let powerDown = SKAction.run {
                        self.shipFireRate = self.defaultFireRate
                    }
                    
                    let wait = SKAction.wait(forDuration: self.powerUpDuration)
                    let waitAndPowerdown = SKAction.sequence([wait, powerDown])
                    
                    //ship.run(waitAndPowerdown)
                    // if we collect an additional powerup while one is already in progress we need to stop the one in progress and start a new one so we always get the full duration for the new one.
                    //Sprite kit lets us run actions with a key that we can then use to identify and remove the action before it has a chance to run or before it finishes if already running.
                    
                    //if no key is found, then nothing happens.
                    
                    let powerDownActionKey = "waitAndPowerDown"
                    ship.removeAction(forKey: powerDownActionKey)
                    
                    ship.run(waitAndPowerdown, withKey: powerDownActionKey)
                }
            }
            
            //will enum through scene graph looking for any node with
            //a name of obstacle If it finds one, it automagically
            //populates my obstacle to a reference to it. It loops through the entire node tree.
            enumerateChildNodes(withName: ObstacleNodeName) {
                myObstacle, _ in
                
                //Check for collision with ship
                if ship.intersects(myObstacle) {
                    //our ship collided.
                    //
                    if GameScene.shipHealthRate > 0 {
                    	myObstacle.removeFromParent()

                    	// Update our health rate
                        if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                            GameScene.shipHealthRate -= 1.0
                            hud.showHealth(GameScene.shipHealthRate)
                        }
                        
                        let explosion = self.obstacleExplodeTemplate.copy() as! SKEmitterNode
                        
                        explosion.position = myObstacle.position
                        explosion.dieOutInDuration(0.2)
                        self.addChild(explosion)
                    	self.run(self.obstacleExplodeSound)
                    } else {
	                    // set shipTouch property to nil so that it
	                    // will not be used by our shooting logic 
	                    //in the update methods to continue to track
	                    //the touch and shoot photon torpedos. If this
	                    //fails, the torpedos will continue to fire from 0,0.
	                    self.shipTouch = nil

	                    //Call copy() on the node in the shipExplodeTemplate property because nodes can only be added to a scene once.
	                    // If we try to add a node again that already exists in a scene, the game will crash with an error. We will use the emitter node template in our cached property as a template from which to make these copies
	                    let explosion = self.shipExplodeTemplate.copy() as! SKEmitterNode
	                    
	                    explosion.position = ship.position
	                    explosion.dieOutInDuration(0.3)
	                    self.addChild(explosion)
	                    
	                    //remove ship and obstacle
	                    myObstacle.removeFromParent()
	                    ship.removeFromParent()
	                    self.run(self.shipExplodeSound)
	                    
	                    if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
	                        hud.endGame()
                 	   }
                 	}
                }
                
                //Now add an innerloop that enumerates through the
                //photon topredo nodes and checks if any of them
                //intersect with myObstacle
                self.enumerateChildNodes(withName: self.PhotonTorpedoNodeName) {
                    myPhoton, stop in
                    
                    if myPhoton.intersects(myObstacle) {
                        
                        myPhoton.removeFromParent()
                        myObstacle.removeFromParent()
                        self.run(self.obstacleExplodeSound)
                        
                        // Set stop.pointee to true to end this inner loop
                        // akin to 'break'
                        stop.pointee = true
                        
                        let explosion = self.obstacleExplodeTemplate.copy() as! SKEmitterNode
                        
                        explosion.position = myObstacle.position
                        explosion.dieOutInDuration(0.1)
                        self.addChild(explosion)
                        
                        // Update our score
                        if let hud = self.childNode(withName: self.HUDNodeName) as! HUDNode? {
                            hud.addPoints(Int(self.defaultScore))
                        }
                        stop.pointee = true
                    }
                }
            }
        }
    }

    // Nudge the ship toward the touchpoint by an appropriate distance
    // based on elapsed time since last frame.
    func moveShipTowardPoint(touchPoint: CGPoint, timeDelta: TimeInterval) {
        if let ship = self.childNode(withName: SpaceshipNodeName) {
            let pureOffsetX = ship.position.x - touchPoint.x
            let pureOffsetY = ship.position.y - touchPoint.y
            
            let distanceLeftToTravel = sqrt(pow(pureOffsetX, 2) + pow(pureOffsetY, 2))
            
            let deltaDistance = CGFloat(timeDelta) * self.shipSpeed
            
            if distanceLeftToTravel > deltaDistance {
                //convert the distance remaining to move back into xy coordinates using the atan2() function to determine this proper angle based on ship's position and destionation.
                let angle = atan2(touchPoint.y - ship.position.y, touchPoint.x - ship.position.x)
                
                //using angle with trig sine and cosine
                //cosine functions, determine the x and y offsets
                let xOffset = deltaDistance * cos(angle)
                let yOffset = deltaDistance * sin(angle)
                
                //use offsets to reposition ship
                ship.position = CGPoint(x: ship.position.x + xOffset, y: ship.position.y + yOffset)
            } else {
                ship.position = touchPoint
            }
        }
    }
    
    func shoot() {
        if let ship = self.childNode(withName: SpaceshipNodeName) {
            // Create a photon torpedo sprite
            let photon = SKSpriteNode(imageNamed: "photon")
            photon.name = PhotonTorpedoNodeName
            photon.position = ship.position
            self.addChild(photon)
            
            //Move the torpedo from it's original positions past the top edge over half second
            // 0,0 bottom-left
            // (self.size.height)
            let flyAction = SKAction.moveBy(x: 0, y: self.size.height + photon.size.height, duration: 0.5)
            
            photon.run(flyAction)
            
            //Remove torpedo once it leaves scene
            let removeAction = SKAction.removeFromParent()
            let fireAndRemove = SKAction.sequence([flyAction, removeAction])
            
            photon.run(fireAndRemove)
            self.run(self.shootSound)
        }
    }
    
    func dropThing() {
        let dieRoll = arc4random_uniform(100)
        
        if dieRoll < toEnemyRatio {
            dropWeaponsPowerUp()
        } else if dieRoll < toAsteroidRatio {
            dropEnemyShip()
        } else if dieRoll < toHealthRatio { //switch these two for demo?
        	dropAsteroid()
        } else {
            dropHealth()
        }
    }
    
    func dropWeaponsPowerUp(){
        //random number between 15 and 44 points.
        let sideSize = 30.0
        
        // define starting X position for enemy ship
        let startX = Double(arc4random_uniform(uint(self.size.width - 60)) + 30)
        
        // starting y position
        let startY = Double(self.size.height) + sideSize
        
        // Create a sprite
        let powerUp = SKSpriteNode(imageNamed: "powerup")
        powerUp.name = PowerUpNodeName
        powerUp.size = CGSize(width: sideSize, height: sideSize)
        powerUp.position = CGPoint(x: startX, y: startY)
        self.addChild(powerUp)

        let powerUpPath = createBezierPath()

        let followPath = SKAction.follow(powerUpPath, asOffset: true, orientToPath: true, duration: 5)
        
        let remove = SKAction.removeFromParent()
        
        powerUp.run(SKAction.sequence([followPath, remove]))
    }

    //Drop an enemy ship.
    func dropEnemyShip(){
        //random number between 15 and 44 points.
        let sideSize = 30.0
        
        // define starting X, Y position for enemy ship
        let startX = CGFloat(arc4random_uniform(uint(self.size.width - 40)) + 20)
        let startY = self.size.height + CGFloat(sideSize)
        
        var followPath: SKAction = SKAction.init()
        
        // Create a sprite
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = ObstacleNodeName
        enemy.size = CGSize(width: sideSize, height: sideSize)
        enemy.position = CGPoint(x: startX, y: startY)
        self.addChild(enemy)
        

        if arc4random_uniform(100) + 1 > self.enemyRatio {
	        //Set up enemy ship to follow a curved
	        //flight path (a bezier curve) with control points
	        //to define the curvature
	        let shipPath = createBezierPath()
	        
	        //Use shipPath to move our enemy ship.
	        //asOffset true makes the path relative to the objects original location.
	        // false means absolute.
	        //orienttopath moves the sprite to orient with the path.
	        followPath = SKAction.follow(shipPath, asOffset: true, orientToPath: true, duration: 7)
        } else {
            if let ship = self.childNode(withName: SpaceshipNodeName) {

        	let firstX = ship.position.x
        	let firstY = self.size.height - CGFloat(arc4random_uniform(UInt32(self.size.height / 4)))
			
            let endY = CGFloat(0.0 - sideSize)
			let randomPercentOfScreen = CGFloat(arc4random_uniform(UInt32(self.size.width / 2)))
        	
            var endX = firstX
        	endX += shipDelta < 0 ? -randomPercentOfScreen : randomPercentOfScreen //left:right
            endX = endX > self.size.width ? self.size.width : endX
            endX = endX < 0 ? 0 : endX

        	let firstStop = CGPoint(x: firstX, y: firstY)
                let firstMove = SKAction.sequence([SKAction.move(to: firstStop , duration:Double(arc4random_uniform(3) + 2)), SKAction.rotate(toAngle: CGFloat(shipDelta < 0 ? Double.pi : -Double.pi), duration: 1)])
        	
        	let endMove = SKAction.move(to: CGPoint(x: endX, y: endY), duration:Double(arc4random_uniform(2) + 1))

        	followPath = SKAction.sequence([firstMove, endMove])
            }
        }

        let remove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([followPath, remove]))
    }

    //Create and return a bezier curved path
    func createBezierPath() -> CGPath {
        let yMax = -1.0 * self.size.height
        
        //Bezier path was produced using the PaintCode app
        //which can be found at www.paintcodeapp.com
        let bezierPath = UIBezierPath();
        //Use the class to build an object with two control points each to construct the curved path.
        
        bezierPath.move(to: CGPoint(x:0.5, y: -0.5))
        
        bezierPath.addCurve(to: CGPoint(x:-2.5,y: -59.5), controlPoint1: CGPoint(x:0.5,y: -0.5), controlPoint2: CGPoint(x:4.55, y:-29.48))
        
        bezierPath.addCurve(to: CGPoint(x:-27.5,y: -154.5), controlPoint1: CGPoint(x:-9.55,y: -89.52), controlPoint2: CGPoint(x:-43.32,y: -115.43))
        
        bezierPath.addCurve(to: CGPoint(x:30.5,y: -243.5), controlPoint1: CGPoint(x:-11.68,y: -193.57), controlPoint2: CGPoint(x:17.28,y: -186.95))
        
        bezierPath.addCurve(to: CGPoint(x:-52.5,y: -379.5), controlPoint1: CGPoint(x:43.72, y:-300.05), controlPoint2: CGPoint(x:-47.71,y: -335.76))
        
        bezierPath.addCurve(to: CGPoint(x:54.5, y:-449.5), controlPoint1: CGPoint(x:-57.29,y: -423.24), controlPoint2: CGPoint(x:-8.14, y:-482.45))
        
        bezierPath.addCurve(to: CGPoint(x:-5.5,y: -348.5), controlPoint1: CGPoint(x:117.14,y: -416.55), controlPoint2: CGPoint(x:52.25,y: -308.62))
        
        bezierPath.addCurve(to: CGPoint(x:10.5,y: -494.5), controlPoint1: CGPoint(x:-63.25, y:-388.38), controlPoint2: CGPoint(x:-14.48,y: -457.43))
        
        bezierPath.addCurve(to: CGPoint(x:0.5,y: -559.5), controlPoint1: CGPoint(x:23.74,y: -514.16), controlPoint2: CGPoint(x:6.93,y: -537.57))
        
        bezierPath.addCurve(to: CGPoint(x:-2.5, y:yMax), controlPoint1: CGPoint(x:-5.2,y: yMax), controlPoint2: CGPoint(x:-2.5, y:yMax))
        
        return bezierPath.cgPath
    }
// THIS IS WHERE DROP HEALTH SHOULD BE.

    //drop asteroids randomly from above the top edge and let them come down through the screen at random angles and speeds until they pass the bottom or side or get destroyed. Then, they should be removed.
    func dropAsteroid(){
            //random number between 15 and 44 points.
            let sideSize = Double(arc4random_uniform(30) + 15)

            //max x value for the scene
            let maxX = Double(self.size.width)
            let quarterX = maxX / 4.0
            let randRange = UInt32(maxX + (quarterX * 2))
        
            // arc4Random_uniform() required a uint32 parameter)
            // define starting X position
            let startX = Double(arc4random_uniform(randRange)) - quarterX
        
            // starting y position
            let startY = Double(self.size.height) + sideSize
        
            let endX = Double(arc4random_uniform(UInt32(maxX)))
            let endY = 0.0 - sideSize
        
            // Create a photon torpedo sprite
            let asteroid = SKSpriteNode(imageNamed: "asteroid")
            asteroid.name = ObstacleNodeName
            asteroid.size = CGSize(width: sideSize, height: sideSize)
            asteroid.position = CGPoint(x: startX, y: startY)
            self.addChild(asteroid)
        
            //Remove torpedo once it leaves scene
        
        let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration:Double(arc4random_uniform(4) + 3))
        
        let remove = SKAction.removeFromParent()
        
        let travelAndRemove = SKAction.sequence([move, remove])
        
        // As the asteroid is moving, rotate it by 3 radians
        // just under 180degrees over 1-3 seconds
        let spin = SKAction.rotate(byAngle: 3, duration: Double(arc4random_uniform(3) + 1))
        
        let spinForever = SKAction.repeatForever(spin)
        
        let groupActions = SKAction.group([travelAndRemove, spinForever])
        
        asteroid.run(groupActions)
    }

    func dropHealth(){
        let sideSize = 25.0
        
        let startX = Double(arc4random_uniform(uint(self.size.width - 60)) + 30)
        
        // starting y position
        let startY = Double(self.size.height) + sideSize
        
        // Create a sprite
        let healthPowerUp = SKSpriteNode(imageNamed: "healthPowerUp")
        healthPowerUp.name = HealthPowerUpNodeName
        healthPowerUp.size = CGSize(width: sideSize, height: sideSize)
        healthPowerUp.position = CGPoint(x: startX, y: startY)
        self.addChild(healthPowerUp)

        let healthPowerUpPath = createBezierPath()

        let followPath = SKAction.follow(healthPowerUpPath, asOffset: true, orientToPath: true, duration: 5)
        let remove = SKAction.removeFromParent()

        let fadeAndScale = SKAction.group([SKAction.fadeOut(withDuration: 5), SKAction.scale(to: 0.5, duration: 4)])
        
        healthPowerUp.run(SKAction.group([SKAction.sequence([SKAction.wait(forDuration: 1.5), fadeAndScale]), SKAction.sequence([followPath, remove])]))
    }
}
