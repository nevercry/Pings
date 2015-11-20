//
//  GlanceController.swift
//  PingsWatch Extension
//
//  Created by nevercry on 11/20/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class GlanceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var fastServerLabel: WKInterfaceLabel!
    @IBOutlet var averageTimeLabel: WKInterfaceLabel!
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
            
            let context = session.receivedApplicationContext
            
            if let serverName = context["serverName"] {
                fastServerLabel.setText(serverName as? String)
                averageTimeLabel.setText(context["avgTime"] as? String)
            }
            
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // MARK: - WCSessionDelegate
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let serverName = applicationContext["serverName"] {
            fastServerLabel.setText(serverName as? String)
            averageTimeLabel.setText(applicationContext["avgTime"] as? String)
        }
    }
}
