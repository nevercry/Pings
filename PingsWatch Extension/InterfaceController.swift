//
//  InterfaceController.swift
//  PingsWatch Extension
//
//  Created by nevercry on 11/20/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController, DataSourceChangedDelegate {

    @IBOutlet var fastServerLabel: WKInterfaceLabel!
    @IBOutlet var averageTimeLabel: WKInterfaceLabel!
    
    func updateUI() {
        // debug 
//        print("last stotre context is \(WatchSessionManager.sharedManager.lastStoreApplicationContext)")
        
        let context = WatchSessionManager.sharedManager.lastStoreApplicationContext
        
        if let serverName = context["serverName"] as? String {
            fastServerLabel.setText(serverName)
            let avgTime = context["avgTime"] as? String
            averageTimeLabel.setText(avgTime)
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        WatchSessionManager.sharedManager.debugDelegate()
        
        WatchSessionManager.sharedManager.addDataSourceChangedDelegate(self)
        
        updateUI()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        
        WatchSessionManager.sharedManager.removeDataSourceChangedDelegate(self)
        
        super.didDeactivate()
    }
    
    // MARK: DataSourceUpdatedDelegate
    func dataSourceDidUpdate(dataSource: DataSource) {
        switch dataSource.server {
        case .Server(let serverName, let avgTime):
            fastServerLabel.setText(serverName)
            averageTimeLabel.setText(avgTime)
        case .Unknown:
            fastServerLabel.setText("UnKnow Server")
            averageTimeLabel.setText("ms")
        }
    }
}
