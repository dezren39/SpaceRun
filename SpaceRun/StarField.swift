//
//  StarField.swift
//  SpaceRun
//
//  Created by Pope, Drewry on 5/10/17.
//  Copyright © 2017 assignmentInClass5 Drew Pope. All rights reserved.
//

import SpriteKit

class StarField: SKNode {
    
    override init() {
        super.init()
        initSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        initSetup()
    }
    
    func initSetup() {
        //Because we need to call a method on self (launchStar) from inside a code block. We must create a weak reference to self.
        // This is what we are doing with [weak self] and then eventually assigning the weak self to a constant weakSelf.
        // Why? the run action hold astrong reference to the code block and the node holds a strong reference to the run action.
        //If the code block held a strong reference to the node then the run action, the code bock, and the node(self) would all hold strong references to each other, forming a retain cycle which would never get deallocated => memory leak
        //
        
        let update = SKAction.run {
            [weak self] in
            
            if arc4random_uniform(10) < 5 {
               if let weakSelf = self {
                   weakSelf.launchStar()
                }
            }
        }
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.01), update])))
 
    }
    
    func launchStar() {
        // Make sure we have a reference to our scene.
        if let scene = self.scene {
            let randomX = Double(arc4random_uniform(uint(scene.size.width)))
            let maxY = Double(scene.size.height) + (Double(arc4random_uniform(uint(scene.size.height))) / 4)
            let randomStart = CGPoint(x: randomX, y: maxY)
            let star = SKSpriteNode(imageNamed: "shootingstar")
            star.position = randomStart
            star.alpha = 0.1 + (CGFloat(arc4random_uniform(10)) / 10.0)
            star.size = CGSize(width: 3.0 - star.alpha, height: 8 - star.alpha)
            
            //stack the stars from dimmest to brightest in the z access
            star.zPosition = -100 + star.alpha * 10
            //move the star toward the bottom of the screen using a random duration, removing the star when it passes the bottom edge.
            //the different speeds of the stars, based on duration, will give the illusion of a parallax effect.
            let destY = 0.0 - scene.size.height - star.size.height
            
            let destX:CGFloat = star.alpha > 0.6 ? (Double(arc4random_uniform(4)) > 1 ?                  (Double(arc4random_uniform(2)) > 1 ? 1 : -1) : 0):0
            
            let duration = Double (-star.alpha + 1.8)
            addChild(star)
            star.run(SKAction.sequence([SKAction.moveBy(x: destX, y: destY, duration: duration), SKAction.removeFromParent()]))
            
        }
    }
}
