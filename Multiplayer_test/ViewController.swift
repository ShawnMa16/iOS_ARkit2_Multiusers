//
//  ViewController.swift
//  Multiplayer_test
//
//  Created by Shawn Ma on 9/22/18.
//  Copyright © 2018 Shawn Ma. All rights reserved.
//

import UIKit
import SnapKit
import ARKit
import SceneKit
import MultipeerConnectivity

struct GameState {
    static let detectSurface = 0  // Scan playable surface (Plane Detection On)
    static let pointToSurface = 1 // Point to surface to see focus point (Plane Detection Off)
    static let readyToPlay = 2    // Focus point visible on surface, we are ready to play
}


class ViewController: UIViewController {

    let arscnView: ARSCNView = {
        let view = ARSCNView()
        return view
    }()
    
    
    var focusSquare = FocusSquare()
    var screenCenter: CGPoint {
        let bounds = arscnView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    lazy var padView: SKView = {
        let view = SKView()
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    
    lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
        button.setTitle("Start", for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    
    var gameState: Int = GameState.detectSurface
    var focusNode: SCNNode!
    var focusPoint: CGPoint!
    var gameWorldCenterTransform: SCNMatrix4 = SCNMatrix4Identity
    var statusMessage: String = ""
    var trackingStatus: String = ""
    
    var tankTemplateNode: SCNNode!
    var tankNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(arscnView)
        view.addSubview(padView)
        view.addSubview(startButton)
        
        initARScene()
        setupCamera()
        setupARView()
        setupPadView()
        setupARSubvies()

        initARSession()
        setupPadScene()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(forName: joystickNotificationName, object: nil, queue: OperationQueue.main) { (notification) in
            guard let userInfo = notification.userInfo else { return }
            let data = userInfo["data"] as! AnalogJoystickData
            
//            print(data.description)
            
            self.tankNode!.position = SCNVector3(
                self.tankNode!.position.x + Float(data.velocity.x * joystickVelocityMultiplier),
                self.tankNode!.position.y,
                self.tankNode!.position.z - Float(data.velocity.y * joystickVelocityMultiplier))
            
            self.tankNode!.eulerAngles.y = Float(data.angular) + Float(180.0 * .pi / 180)
//                + self.arscnView.session.currentFrame!.camera.eulerAngles.y
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        arscnView.session.pause()
    }
    
    func setupCamera() {
        guard let camera = arscnView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }

    func setupARView() {
        arscnView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().offset(0)
        }
        
        arscnView.scene.rootNode.addChildNode(focusSquare)
    }
    
    func setupPadView() {
        view.addSubview(padView)
        padView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().offset(0)
            make.height.equalTo(180)
        }
    }
    
    func setupPadScene() {
        let scene = ARJoystickSKScene(size: CGSize(width: view.bounds.size.width, height: 180))
        scene.scaleMode = .resizeFill
        padView.presentScene(scene)
        padView.ignoresSiblingOrder = true
    }
    
    func initARScene() {
        arscnView.delegate = self
        arscnView.autoenablesDefaultLighting = true
    }
    
    func initARSession() {
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        arscnView.session.delegate = self
        
        // Start the view's AR session.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        arscnView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arscnView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func setupARSubvies() {
        
        startButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalTo(arscnView.snp.bottom).offset(-50)
            make.height.equalTo(44)
        }
        startButton.isHidden = false
        startButton.addTarget(self, action: #selector(addTank), for: .touchUpInside)
    }
    
    
    private func loadTank() -> SCNNode {
        let sceneURL = Bundle.main.url(forResource: "Tank", withExtension: "scn", subdirectory: "Assets.scnassets/Models")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        
        return referenceNode
    }
    
    
    @objc func addTank() {
        startButton.isHidden = true
        padView.isHidden = false
        tankNode = loadTank()
        DispatchQueue.main.async {
            self.tankNode?.transform = self.focusSquare.transform
            self.tankNode?.eulerAngles = SCNVector3(0, self.focusSquare.eulerAngles.y + 180.0 * .pi / 180, 0)
            self.tankNode?.scale = SCNVector3(0.0002, 0.0002, 0.0002)
            
            self.arscnView.scene.rootNode.addChildNode(self.tankNode!)
        }
    }
    
    // MARK: - Focus Square
    
    func updateFocusSquare(isObjectVisible: Bool) {
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
        }
        
        if let camera = arscnView.session.currentFrame?.camera, case .normal = camera.trackingState , let result = self.arscnView.hitTest(self.screenCenter, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane, .estimatedVerticalPlane]).first {
            DispatchQueue.main.async {
                self.arscnView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
                self.gameState = GameState.readyToPlay
            }
        } else {
            DispatchQueue.main.async {
                self.focusSquare.state = .initializing
                self.arscnView.pointOfView?.addChildNode(self.focusSquare)
            }
        }
    }
    
    // MARK:- update delegate
    
    
    // MARK:- game logic
    
    @objc func startGame() {
        DispatchQueue.main.async {
//            self.startButton.isHidden = true
//            self.focusNode.isHidden = true
//            self.suspendARPlaneDetection()
//            self.hideARPlaneNodes()
//            self.gameState = GameState.pointToSurface
//            self.createGameWorld()
        }
    }
    
    
//    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        <#code#>
//    }

}

extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
                self.updateFocusSquare(isObjectVisible: !self.padView.isHidden)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // should init plan here
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        
    }
}

