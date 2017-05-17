//
//  SKEmitterNodeExtension.swift
//  SpaceRun
//
//  Created by Pope, Drewry on 5/10/17.
//  Copyright © 2017 assignmentInClass5 Drew Pope. All rights reserved.
//

import SpriteKit

// .sks files are archived in SKEmitterNode instances. We need to retrieve a copy of that node by loading it from the app bundle. In order to mimic the API that Apple uses for sound actions, we will build a Swift extension to add a new method onto the SKEmitterNode class.

//NOTE: extensions were called categories in Obj C

extension String {
    var length: Int {
        return self.characters.count
    }
}

//Now let's exten the SKEmitterNode class by adding a helper method to it named nodewithFile()
extension SKEmitterNode {
    class func nodeWithFile(_ fileName: String) -> SKEmitterNode? {
            //break apart the passed-in fileName into a baseName and it's extension. If the passed in fileName has no extension, add an extension of "sks")
        let baseName = (fileName as NSString).deletingPathExtension
        var fileExtension = (fileName as NSString).pathExtension
        
        if fileExtension.length == 0 {
            fileExtension = "sks"
        }
        
        // Grab the main bundle of our app and ask for the path to a resource using our baseName and fileExtension
        if let path = Bundle.main.path(forResource: baseName, ofType: fileExtension) {
            //particle effects in SK are archived when created and so must be unarchived.
            
            let node = NSKeyedUnarchiver.unarchiveObject(withFile: path) as! SKEmitterNode
            
            return node
        }
        return nil
    }


//We want to add explosions for the two collisions that occur for torpedos vs obstacles and obstacles vs ship

// We don't want the xplosion emitter to keep running indefinitely for these explosion so we will make them die out after a short duration.

    func dieOutInDuration(_ duration: TimeInterval) {
        //Define two waiting periods because once we set the birthrate to zero we will still need to wait before the existing particles die out.
        let firstWait = SKAction.wait(forDuration: duration)
    
        //set the birthrate to zero in order to make the particle effect disappear using an SKaction code block.
        let stop = SKAction.run {
            [weak self] in
        
            if let weakSelf = self {
                weakSelf.particleBirthRate = 0
            }
        }
        
        let secondWait = SKAction.wait(forDuration: TimeInterval(self.particleLifetime))
            
        let remove = SKAction.removeFromParent()
        
        run(SKAction.sequence([firstWait, stop, secondWait, remove]))
        
    }
}
