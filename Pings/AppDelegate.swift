//
//  AppDelegate.swift
//  Pings
//
//  Created by nevercry on 10/20/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit

struct PingsURL {
    static let Notification = "PingsURL Radio Station"
    static let Key = "PingsURL URL Key"
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        print("url = \(url)")
        let center = NSNotificationCenter.defaultCenter()
        let notification = NSNotification(name: PingsURL.Notification, object: self, userInfo: [PingsURL.Key:url])
        center.postNotification(notification)
        return true
    }

    
    // MARK: - File system support
    
    func applicationDocumentsDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
    }


}

