//
//  WatchSessionManager.swift
//  Pings
//
//  Created by nevercry on 11/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import WatchConnectivity

// Note that the WCSessionDelegate must be an NSObject
// So no, you cannot use the nice Swift struct here!
// Modification to the WatchSessionManager in the iOS app only
class WatchSessionManager: NSObject, WCSessionDelegate{
    
    // Instantiate the singleton
    static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
    }
    
    // Keep a reference for the session.
    // which will be used later for sending / receiving data
    private let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    private var validSession: WCSession? {
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session where session.paired && session.watchAppInstalled {
            return session
        }
        return nil
    }
    
    // Activate Session
    // This needs to be called to activate the session before first use!
    
    func startSession() {
        session?.delegate = self
        session?.activateSession()
    }
    
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced

extension WatchSessionManager {
    
    // Sender
    func updateAppicationContext(applicationContext: [String : AnyObject]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                throw error
            }
        }
    }
    
    // Receiver
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        // hanle receiviong application context
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
}