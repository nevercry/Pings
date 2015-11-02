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
    static let ShortCutNotification = "PingsURL ShortCut Radio Station"
    static let ShortCutKey = "PingsURL ShortCut Key"
}

struct Constants {
    static let FileExtension = "conf"
    static let DefaultFileName = "DEFAULT"
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Type
    
    enum ShortcutIdentifier: String {
        case First
        case Second
        
        // MARK: Intializers
        
        init?(fullType: String) {
            guard let last = fullType.componentsSeparatedByString(".").last else { return nil }
            
            self.init(rawValue: last)
        }
        
        // MARK: Properties
        
        var type: String {
            return NSBundle.mainBundle().bundleIdentifier! + ".\(self.rawValue)"
        }
    }
    
    // MARK: Static Properties
    
    static let applicationShortcutUserInfoKey = "applicationShortcutUserInfoKey"
    
    // MARK: Properties

    var window: UIWindow?
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
        guard ShortcutIdentifier(fullType: shortcutItem.type) != nil else { return false }
        
        guard let shortCutType = shortcutItem.type as String? else { return false }
        
        var shortCutFileIndex: Int?
        
        switch(shortCutType) {
        case ShortcutIdentifier.First.type:
            shortCutFileIndex = 0
            handled = true
        case ShortcutIdentifier.Second.type:
            let userInfoDic = shortcutItem.userInfo as! [String : Int]
            shortCutFileIndex = userInfoDic[AppDelegate.applicationShortcutUserInfoKey]
            handled = true
        default:
            break
        }
        
        if handled == true {
            guard let currenVC = window!.rootViewController?.contentViewController else { return false }
            
            let storyboard = currenVC.storyboard
            
            var fileListVC: FileListTableViewController
            if let vc = currenVC as? FileListTableViewController {
                fileListVC = vc
            } else {
                fileListVC = currenVC.navigationController?.viewControllers.first as! FileListTableViewController
            }
            
            let pingsTVC = storyboard?.instantiateViewControllerWithIdentifier("PingsTableViewController") as! PingsTableViewController
            pingsTVC.fileName = applicationFileList()[shortCutFileIndex!]
            pingsTVC.isFromShortCut = true
            fileListVC.navigationController?.setViewControllers([fileListVC,pingsTVC], animated: false)
        }
        
        return handled
    }
    
    // MARK: Application Life Cycle
    
    func applicationDidBecomeActive(application: UIApplication) {
        guard let shortcut = launchedShortcutItem else { return }
        handleShortCutItem(shortcut)
        launchedShortcutItem = nil
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        var shouldPerformAdditionalDelegateHandling = true
        
        // If a shortcut was launched, display its information and take the appropriate action
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            
            launchedShortcutItem = shortcutItem
            
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    /*
    Called when the user activates your application by selecting a shortcut on the home screen, except when
    application(_:,willFinishLaunchingWithOptions:) or application(_:didFinishLaunchingWithOptions) returns `false`.
    You should handle the shortcut in those callbacks and return `false` if possible. In that case, this
    callback is used if your application is already launched in the background.
    */
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: Bool -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        
        completionHandler(handledShortCutItem)
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        let center = NSNotificationCenter.defaultCenter()
        let notification = NSNotification(name: PingsURL.Notification, object: self, userInfo: [PingsURL.Key:url])
        center.postNotification(notification)
        return true
    }
    
    // MARK: - File system support
    
    func applicationDocumentsDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
    }
    
    func applicationFileList() -> [String] {
        let documentsDirectoryPath = applicationDocumentsDirectory()
        let defaultManager = NSFileManager.defaultManager()
        
        let documentsDirectoryContents = try! defaultManager.contentsOfDirectoryAtPath(documentsDirectoryPath)
        
        if documentsDirectoryContents.count == 0 {
            let defaultConfPathURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent("\(Constants.DefaultFileName).\(Constants.FileExtension)")
            defaultManager.createFileAtPath(defaultConfPathURL.path!, contents: nil, attributes: nil)
            return [Constants.DefaultFileName]
        } else {
            var fileList = [String]()
            for curFileName in documentsDirectoryContents {
                let filePath = NSURL.fileURLWithPath(documentsDirectoryPath).URLByAppendingPathComponent(curFileName).path!
                let fileURL = NSURL.fileURLWithPath(filePath)
                var isDirectory: ObjCBool = false
                defaultManager.fileExistsAtPath(filePath, isDirectory: &isDirectory)
                
                if (!(isDirectory && curFileName == "Inbox")) {
                    let suffixRange = curFileName.rangeOfString("." + Constants.FileExtension)
                    let nosuffixFileName = curFileName.substringToIndex(suffixRange!.startIndex)
                    fileList.append(nosuffixFileName)
                } else {
                    let inboxContents = try! defaultManager.contentsOfDirectoryAtPath(filePath)
                    if inboxContents.count > 0 {
                        for inboxFileName in inboxContents {
                            let moveFileURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent(inboxFileName)
                            let srcPath = fileURL.URLByAppendingPathComponent(inboxFileName).path!
                            try! defaultManager.moveItemAtPath(srcPath, toPath: moveFileURL.path!)
                            let suffixRange = inboxFileName.rangeOfString("." + Constants.FileExtension)
                            let nosuffixFileName = inboxFileName.substringToIndex(suffixRange!.startIndex)
                            fileList.append(nosuffixFileName)
                        }
                    }
                }
            }
            return fileList
        }
    }
    
    
    
}

extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController!
        } else {
            return self
        }
    }
}

