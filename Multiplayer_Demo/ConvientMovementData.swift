////
////  ConvientMovementData.swift
////  Multiplayer_test
////
////  Created by Shawn Ma on 9/24/18.
////  Copyright © 2018 Shawn Ma. All rights reserved.
////
//
//import SpriteKit
//
//open class MovementData: NSObject, NSSecureCoding {
//    public static var supportsSecureCoding: Bool = true
//
//    var velocity = CGPoint.zero,
//    angular = Float(0)
//
//    enum Key:String {
//        case velocity = "velocity"
//        case angular = "angular"
//    }
//
//    public func encode(with aCoder: NSCoder) {
//        aCoder.encode(velocity as CGPoint, forKey: Key.velocity.rawValue)
//        aCoder.encode(angular as Float, forKey: Key.angular.rawValue)
//    }
//
//    public convenience required init?(coder aDecoder: NSCoder) {
//        let _velocity = aDecoder.decodeCGPoint(forKey: Key.velocity.rawValue)
//        let _angular = aDecoder.decodeFloat(forKey: Key.angular.rawValue)
//        self.init(velocity: _velocity, angular: _angular)
//    }
//
//    init(velocity: CGPoint, angular: Float) {
//        self.velocity = velocity
//        self.angular = angular
//    }
//}
