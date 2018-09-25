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

enum GameState {
    case shouldInit
    case canStart
    case worldMapSent
    case tankAdded
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
    
    let sessionInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()
    
    let sessionInfoLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()
    
    lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
        button.setTitle("Start", for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.isHidden = true
        return button
    }()
    
    lazy var mappingStatusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()
    
    lazy var sendMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
        button.setTitle("send world Map", for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    
    var multipeerSession: MultipeerSession!
    var mapHasInited: Bool = false
    
    var gameState: GameState = .shouldInit
    var gameWorldCenterTransform: SCNMatrix4 = SCNMatrix4Identity
    
    var tankTemplateNode: SCNNode!
    var myTank: SCNNode?
    var otherTank: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(arscnView)
        view.addSubview(padView)
        view.addSubview(startButton)
        view.addSubview(sendMapButton)
        
        view.addSubview(sessionInfoView)
        sessionInfoView.addSubview(sessionInfoLabel)
        sessionInfoView.addSubview(mappingStatusLabel)
        
        initARScene()
        setupCamera()
        setupARView()
        setupPadView()
        setupSubViews()
        
        initARSession()
        setupPadScene()
        
        // multipeer session here
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(forName: joystickNotificationName, object: nil, queue: OperationQueue.main) { (notification) in
            guard let userInfo = notification.userInfo else { return }
            let data = userInfo["data"] as! AnalogJoystickData
            let shouldSend = MovementData(velocity: data.velocity, angular: Float(data.angular))
            guard let sendData = try? NSKeyedArchiver.archivedData(withRootObject: shouldSend, requiringSecureCoding: true)
                else { fatalError("can't encode anchor") }
            
//            let test = WritableBitStream
//            self.multipeerSession.sendToAllPeers(sendData)
            self.multipeerSession.sendToAllPeers(sendData)
            //            print(data.description)
            
            self.moveTank(data: shouldSend)
//            self.myTank!.position = SCNVector3(
//                self.myTank!.position.x + Float(data.velocity.x * joystickVelocityMultiplier),
//                self.myTank!.position.y,
//                self.myTank!.position.z - Float(data.velocity.y * joystickVelocityMultiplier))
//
//            self.myTank!.eulerAngles.y = Float(data.angular) + Float(180.0 * .pi / 180)
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
        resetTracking()
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        arscnView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arscnView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    func setupSubViews() {
        
        sessionInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().offset(0)
        }
        
        sessionInfoLabel.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(50)
        }
        
        mappingStatusLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(sendMapButton.snp.top).offset(-20)
        }
        
        startButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalTo(arscnView.snp.bottom).offset(-50)
            make.height.equalTo(44)
        }
        startButton.isHidden = false
        startButton.addTarget(self, action: #selector(addTank), for: .touchUpInside)
        
        
        sendMapButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
            make.width.equalTo(150)
            make.bottom.equalTo(startButton.snp.top).offset(-20)
        }
        sendMapButton.addTarget(self, action: #selector(sendWorldMap), for: .touchUpInside)
        
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
        //        myTank = loadTank()
        //            self.tankNode?.transform = self.focusSquare.transform
        //            self.tankNode?.eulerAngles = SCNVector3(0, self.focusSquare.eulerAngles.y + 180.0 * .pi / 180, 0)
        //            self.tankNode?.scale = SCNVector3(0.0002, 0.0002, 0.0002)
        let anchor = ARAnchor(name: "tank", transform: self.focusSquare.simdTransform)
        self.arscnView.session.add(anchor: anchor)
        
        //            self.arscnView.scene.rootNode.addChildNode(self.tankNode!)
        
        // send node to another peer
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            else { fatalError("can't encode anchor") }
        self.multipeerSession.sendToAllPeers(data)
    }
    
    @objc func sendWorldMap() {
        arscnView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
            self.sendMapButton.isHidden = true
            self.mapHasInited = true
        }
    }
    
    func moveTank(data: MovementData) {
        self.myTank!.position = SCNVector3(
            self.myTank!.position.x + Float(data.velocity.x * joystickVelocityMultiplier),
            self.myTank!.position.y,
            self.myTank!.position.z - Float(data.velocity.y * joystickVelocityMultiplier))
        
        self.myTank!.eulerAngles.y = Float(data.angular) + Float(180.0 * .pi / 180)
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
                self.gameState = .canStart
            }
        } else {
            DispatchQueue.main.async {
                self.focusSquare.state = .initializing
                self.arscnView.pointOfView?.addChildNode(self.focusSquare)
            }
        }
    }
    
    // MARK: - AR session management
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
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
    
    var mapProvider: MCPeerID?
    
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        do {
            //            var bits = ReadableBitStream(data: data)
            ////            let bit = inout(&bits)
            //            print(bits)
            if !mapHasInited {
                if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                    // Run the session with the received world map.
                    let configuration = ARWorldTrackingConfiguration()
                    configuration.planeDetection = .horizontal
                    configuration.initialWorldMap = worldMap
                    arscnView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                    
                    // Remember who provided the map for showing UI feedback.
                    mapProvider = peer
                }
                self.mapHasInited = true
                DispatchQueue.main.async {
                    self.sendMapButton.isHidden = true
                }
            }
            else {
                if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                    // Add anchor to the session, ARSCNView delegate adds visible content.
                    self.arscnView.session.add(anchor: anchor)
                }
                else
                    if let movement = try NSKeyedUnarchiver.unarchivedObject(ofClass: MovementData.self, from: data) {
                        print(movement)
                        self.moveTank(data: movement)
                }
//                else {
//                    print("unknown data recieved from \(peer)")
//                }
                
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
}

extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare(isObjectVisible: !self.padView.isHidden)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // should init plan here
        //        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        if let name = anchor.name, name.hasPrefix("tank") {
            DispatchQueue.main.async {
                let tank = self.loadTank()
                tank.scale = SCNVector3(0.0002, 0.0002, 0.0002)
                if self.myTank == nil {
                    self.myTank = tank
                } else {
                    self.otherTank = tank
                }
                node.addChildNode(tank)
            }
        }
        
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            sendMapButton.isEnabled = false
        case .extending:
            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        case .mapped:
            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        }
        mappingStatusLabel.text = frame.worldMappingStatus.description
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        //        resetTracking(nil)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    
}

