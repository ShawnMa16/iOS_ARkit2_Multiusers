///*
//See LICENSE folder for this sample’s licensing information.
//
//Abstract:
//A simple abstraction of the MultipeerConnectivity API as used in this app.
//*/
//
//import MultipeerConnectivity
//import simd
//
///// - Tag: MultipeerSession
//class MultipeerSession: NSObject {
//
//    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
//    private var session: MCSession!
//    private var myOutput: OutputStream!
//    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
//    private var serviceBrowser: MCNearbyServiceBrowser!
//
//    private let receivedDataHandler: (Data, MCPeerID) -> Void
//    private let streamDataHandler: (Stream, Stream.Event) -> Void
//
//    /// - Tag: MultipeerSetup
//    init(receivedDataHandler: @escaping (Data, MCPeerID) -> Void, streamingDataHandler: @escaping (Stream, Stream.Event) -> Void ) {
//        self.receivedDataHandler = receivedDataHandler
//        self.streamDataHandler = streamingDataHandler
//
//        super.init()
//
//        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
//        session.delegate = self
//
//        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: MultipeerSession.serviceType)
//        serviceAdvertiser.delegate = self
//        serviceAdvertiser.startAdvertisingPeer()
//
//        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerSession.serviceType)
//        serviceBrowser.delegate = self
//        serviceBrowser.startBrowsingForPeers()
//
//
//    }
//
//    func sendToAllPeers(_ data: Data) {
//        do {
//            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
//        } catch {
//            print("error sending data to peers: \(error.localizedDescription)")
//        }
//
//    }
//
//    var connectedPeers: [MCPeerID] {
//        return session.connectedPeers
//    }
//
//    var publicSession: MCSession {
//        return self.session
//    }
//
//    var outpuStream: OutputStream {
//        return myOutput
//    }
//}
//
//extension MultipeerSession: MCSessionDelegate, StreamDelegate {
//
//    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//        // not used
//    }
//
//    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        receivedDataHandler(data, peerID)
//    }
//
//
//
//    // MARK:- streaming here // receiver
//    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
//        stream.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
//        stream.delegate = self
//        stream.open()
//        print("didReceiveStream", stream, streamName, stream.hasBytesAvailable)
//    }
//
//    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
//        streamDataHandler(aStream, eventCode)
//    }
//
//    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
//        fatalError("This service does not send/receive resources.")
//    }
//
//    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
//        fatalError("This service does not send/receive resources.")
//    }
//
//}
//
//extension MultipeerSession: MCNearbyServiceBrowserDelegate {
//
//    /// - Tag: FoundPeer
//    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
//        // Invite the new peer to the session.
//        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
//    }
//
//    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
//        // This app doesn't do anything with non-invited peers, so there's nothing to do here.
//    }
//
//}
//
//extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
//
//    /// - Tag: AcceptInvite
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//        // Call handler to accept invitation and join the session.
//        invitationHandler(true, self.session)
//    }
//
//}
