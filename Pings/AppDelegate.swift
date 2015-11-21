//
//  AppDelegate.swift
//  Pings
//
//  Created by nevercry on 10/20/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit

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
            pingFileAt(shortCutFileIndex!)
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
        
        // MARK: need Setup WCSession for communication apple watch
        WatchSessionManager.sharedManager.startSession()
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: Bool -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        
        completionHandler(handledShortCutItem)
    }
    
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        let urlScheme = url.scheme
            
        if urlScheme == "pings" {
            let resourceSpecifier = url.resourceSpecifier
            
            if resourceSpecifier == "/pingRecent" {
            
                if let mutableShortCutItem = UIApplication.sharedApplication().shortcutItems?.last {
                    let userInfoDic = mutableShortCutItem.userInfo as! [String: Int]
                    let recentFileIndex = userInfoDic[AppDelegate.applicationShortcutUserInfoKey]
                    pingFileAt(recentFileIndex!)
                }
                
                return true
            }
            
        } else {
            let center = NSNotificationCenter.defaultCenter()
            let notification = NSNotification(name: YSFGlobalConstants.Strings.PingsURLNotification, object: self, userInfo: [YSFGlobalConstants.Strings.PingsURLKey:url])
            center.postNotification(notification)
        }
        
        return true
    }
    
    // MARK: - private methods
    
    func pingFileAt(index: Int) {
        guard let currenVC = window!.rootViewController?.contentViewController else { return }
        
        guard index < applicationFileList().count else { return }
        
        let storyboard = currenVC.storyboard
        
        var fileListVC: FileListTableViewController
        if let vc = currenVC as? FileListTableViewController {
            fileListVC = vc
        } else {
            fileListVC = currenVC.navigationController?.viewControllers.first as! FileListTableViewController
        }
        
        let pingsTVC = storyboard?.instantiateViewControllerWithIdentifier("PingsTableViewController") as! PingsTableViewController
        
        pingsTVC.fileName = applicationFileList()[index]
        pingsTVC.isFromShortCut = true
        fileListVC.navigationController?.setViewControllers([fileListVC,pingsTVC], animated: false)
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
            let defaultConfPathURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent("\(YSFGlobalConstants.Strings.DefaultFileName).\(YSFGlobalConstants.Strings.FileExtension)")
            defaultManager.createFileAtPath(defaultConfPathURL.path!, contents: nil, attributes: nil)
            return [YSFGlobalConstants.Strings.DefaultFileName]
        } else {
            var fileList = [String]()
            for curFileName in documentsDirectoryContents {
                let filePath = NSURL.fileURLWithPath(documentsDirectoryPath).URLByAppendingPathComponent(curFileName).path!
                let fileURL = NSURL.fileURLWithPath(filePath)
                var isDirectory: ObjCBool = false
                defaultManager.fileExistsAtPath(filePath, isDirectory: &isDirectory)
                
                if (!(isDirectory && curFileName == "Inbox")) {
                    let suffixRange = curFileName.rangeOfString("." + YSFGlobalConstants.Strings.FileExtension)
                    let nosuffixFileName = curFileName.substringToIndex(suffixRange!.startIndex)
                    fileList.append(nosuffixFileName)
                } else {
                    let inboxContents = try! defaultManager.contentsOfDirectoryAtPath(filePath)
                    if inboxContents.count > 0 {
                        for inboxFileName in inboxContents {
                            let moveFileURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent(inboxFileName)
                            let srcPath = fileURL.URLByAppendingPathComponent(inboxFileName).path!
                            
                            // Check File isExist
                            if defaultManager.fileExistsAtPath(moveFileURL.path!) {
                                try! defaultManager.removeItemAtURL(moveFileURL)
                            }
                            
                            try! defaultManager.moveItemAtPath(srcPath, toPath: moveFileURL.path!)
                            let suffixRange = inboxFileName.rangeOfString("." + YSFGlobalConstants.Strings.FileExtension)
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

