//
//  Tank.swift
//  Multiplayer_test
//
//  Created by Shawn Ma on 9/30/18.
//  Copyright © 2018 Shawn Ma. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit
import os.log

class Tank: NSObject {
    
    let objectRootNode: SCNNode
    var geometryNode: SCNNode?
    var owner: Player?
    
    var physicsNode: SCNNode?
    
    var isAlive: Bool
    
    static var indexCounter = 0
    var index = 0
    
    init(node: SCNNode, index: Int?, alive: Bool, owner: Player?) {
        objectRootNode = node
        self.isAlive = alive
        self.owner = owner
        
        if let index = index {
            self.index = index
        } else {
            self.index = Tank.indexCounter
            Tank.indexCounter += 1
        }
        
        super.init()
        
        attachGeometry()
    }
    
    private func loadTank() -> SCNNode {
        let sceneURL = Bundle.main.url(forResource: "Tank", withExtension: "scn", subdirectory: "Assets.scnassets/Models")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        
        return referenceNode
    }
    
    private func attachGeometry() {
        self.geometryNode = loadTank()
        self.objectRootNode.addChildNode(self.geometryNode!)
    }
    
    
}
