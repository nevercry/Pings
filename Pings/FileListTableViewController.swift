//
//  FileListTableViewController.swift
//  Pings
//
//  Created by nevercry on 10/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit
import NotificationCenter
import MBProgressHUD
import StoreKit


class FileListTableViewController: UITableViewController, DirectoryWatcherDelegate {
    
    var editBarButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .Edit, target: nil, action: "editFileList:")
    
    var fileList = [String]()
    var docWatcher: DirectoryWatcher?
    
    var myObserver: NSObjectProtocol?
    
    // This list of available in-app purchases
    var products = [SKProduct]()
    
    lazy var spinner: MBProgressHUD = {
        return MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    }()
    
    // priceFormatter is used to show proper, localized currency
    lazy var priceFormatter: NSNumberFormatter = {
        let pf = NSNumberFormatter()
        pf.formatterBehavior = .Behavior10_4
        pf.numberStyle = .CurrencyStyle
        return pf
    }()
    
    
    private struct Constants {
        static let CellReuseIdentifier = "File Cell"
        static let SegueIdentifier = "Show Servers"
    }
    
    // MARK: - View LifeCycle
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // IAP
        // Subscribe to a notification that fires when a product is purchased.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "productPurchased:", name: IAPHelperProductPurchasedNotification, object: nil)
        
        editBarButton.target = self
        self.navigationItem.rightBarButtonItem = editBarButton
        
        
        let watchPath = AppDelegate().applicationDocumentsDirectory()
        
        docWatcher = DirectoryWatcher.watchFolderWithPath(watchPath, delegate: self)
        directoryDidChange(docWatcher)
        
        if let mutableShortCut = UIApplication.sharedApplication().shortcutItems?.last {
            let userInfoDic = mutableShortCut.userInfo as! [String : Int]
            recentFileIndex = userInfoDic["applicationShortcutUserInfoKey"]
        } else {
            NCWidgetController.widgetController().setHasContent(false, forWidgetWithBundleIdentifier: YSFGlobalConstants.BundleId.WidgetId)
        }
        
        // Check for force touch feature, and add force touch/previewing capability.
        if traitCollection.forceTouchCapability == .Available {
            /*
            Register for `UIViewControllerPreviewingDelegate` to enable
            "Peek" and "Pop".
            (see: MasterViewController+UIViewControllerPreviewing.swift)
            
            The view controller will be automatically unregistered when it is
            deallocated.
            */
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        
        updateUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        
        myObserver = center.addObserverForName(YSFGlobalConstants.Strings.PingsURLNotification, object: appDelegate, queue: queue) { [weak self] notification  in
            guard let strongSelf = self else { return }
            if let url = notification.userInfo?[YSFGlobalConstants.Strings.PingsURLKey] as? NSURL {
                let defaultManager = NSFileManager.defaultManager()
                let documentsDirectoryPath = AppDelegate().applicationDocumentsDirectory()
                
                let moveFileURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent(url.lastPathComponent!)
                let srcPath = url.path!
                
                // Check File isExist
                if defaultManager.fileExistsAtPath(moveFileURL.path!) {
                    try! defaultManager.removeItemAtURL(moveFileURL)
                }
                
                try! defaultManager.moveItemAtPath(srcPath, toPath: moveFileURL.path!)
                
                var fileName = url.lastPathComponent!
                let suffixRange = fileName.rangeOfString(".conf")!
                fileName.removeRange(suffixRange)
                strongSelf.performSegueWithIdentifier(Constants.SegueIdentifier, sender: fileName)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let center = NSNotificationCenter.defaultCenter()
        
        if myObserver != nil {
            center.removeObserver(myObserver!)
        }
    }
    
    // MARK: - Private Methods
    
    func updateUI() {
        
        // Check RemoveAd Whether Purchased
        if !isRemoveAd {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "RemoveAd", style: .Plain, target: self, action: "removeAd:")
            
            self.navigationItem.leftBarButtonItem?.enabled = IAPHelper.canMakePayments()
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    func removeAd(sender: UIBarButtonItem) {
        
        
        if products.count > 0 {
            self.displayIAPUI()
        } else {
            spinner.show(true)
            spinner.userInteractionEnabled = true
            PingsProducts.store.requestProductsWithCompletionHandler { (sucess, products) -> () in
                self.spinner.hide(true)
                if sucess {
                    self.products = products
                    self.displayIAPUI()
                } else {
                    let errorAlert = UIAlertController.init(title: "Error", message: "Request AppStore Error", preferredStyle: .Alert)
                    self.presentViewController(errorAlert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func displayIAPUI() {
        if let removeAdProduct = products.last {
            priceFormatter.locale = removeAdProduct.priceLocale
            let realPrice = priceFormatter.stringFromNumber(removeAdProduct.price)
            let alertVC = UIAlertController.init(title: "Remove Ad Forever?", message: "\(removeAdProduct.localizedDescription), You will pay \(realPrice!) for that.", preferredStyle: .Alert)
            
            let purchaseAction = UIAlertAction.init(title: "Purchase", style: .Destructive, handler: { (action) -> Void in
                PingsProducts.store.purchaseProduct(removeAdProduct)
            })
            
            let restoreAction = UIAlertAction.init(title: "Restore", style: .Default, handler: { (action) -> Void in
                PingsProducts.store.restoreCompletedTransactions()
            })
            
            alertVC.addAction(purchaseAction)
            alertVC.addAction(restoreAction)
            
            presentViewController(alertVC, animated: true, completion: nil)
        }
    }
    
    func productPurchased(sender: NSNotification) {
        updateUI()
    }
    

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileList.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath)
        cell.textLabel!.text = fileList[indexPath.row]
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
}
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            remveFileAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

    
    // MARK: - DirectoryWatcherDelegate
    
    func directoryDidChange(folderWatcher: DirectoryWatcher!) {
        fileList.removeAll()
        let documentsDirectoryPath = AppDelegate().applicationDocumentsDirectory()
        let defaultManager = NSFileManager.defaultManager()
        
        let documentsDirectoryContents = try! defaultManager.contentsOfDirectoryAtPath(documentsDirectoryPath)
        
        if documentsDirectoryContents.count == 0 {
            // create default file only once
            if !NSUserDefaults.standardUserDefaults().boolForKey(YSFGlobalConstants.Strings.PingsHasCreateDefaultFileOnceKey) {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: YSFGlobalConstants.Strings.PingsHasCreateDefaultFileOnceKey)
                NSUserDefaults.standardUserDefaults().synchronize()
                let defaultConfPathURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent("\(YSFGlobalConstants.Strings.DefaultFileName)" + "." + "\(YSFGlobalConstants.Strings.FileExtension)")
                defaultManager.createFileAtPath(defaultConfPathURL.path!, contents: nil, attributes: nil)
                
            }
        } else {
            
            for curFileName in documentsDirectoryContents {
                let filePath = NSURL.fileURLWithPath(documentsDirectoryPath).URLByAppendingPathComponent(curFileName).path!
                let fileURL = NSURL.fileURLWithPath(filePath)
                
                var isDirectory: ObjCBool = false
                defaultManager.fileExistsAtPath(filePath, isDirectory: &isDirectory)
                if (!(isDirectory && curFileName == "Inbox")) {
                    let suffixRange = curFileName.rangeOfString(".conf")
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
                        }
                    }
                }
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - event response
    
    func editFileList(var sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.editing, animated: true)
        let sysItem = tableView.editing ? UIBarButtonSystemItem.Done : .Edit
        sender = UIBarButtonItem.init(barButtonSystemItem: sysItem, target: self, action: "editFileList:")
        self.navigationItem.rightBarButtonItem = sender
    }

    
    // MARK: - private methods
    
    func remveFileAtIndex(index: Int) {
        let fileName = fileList[index]
        
        // check RecentFile is be delete ones?
        if recentFileIndex != nil {
            if recentFileIndex! == index {
                recentFileIndex = -1
                
                NCWidgetController.widgetController().setHasContent(false, forWidgetWithBundleIdentifier: YSFGlobalConstants.BundleId.WidgetId)
                
            } else {
                if recentFileIndex! > index {
                    recentFileIndex!--
                }
            }
        }
        

        let documentsDirectoryPath = AppDelegate().applicationDocumentsDirectory()
        let defaultManager = NSFileManager.defaultManager()
        let fileURL = NSURL.fileURLWithPath(documentsDirectoryPath).URLByAppendingPathComponent(fileName + "." + "\(YSFGlobalConstants.Strings.FileExtension)")
        try! defaultManager.removeItemAtURL(fileURL)
        fileList.removeAtIndex(index)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.SegueIdentifier {
            if let cell = sender as? UITableViewCell {
                let fileName = cell.textLabel!.text
                if let ptvc = segue.destinationViewController as? PingsTableViewController {
                    ptvc.fileName = fileName
                }
                
                let index = tableView.indexPathForCell(cell)
                
                recentFileIndex = index?.row
                
            } else if let fileName = sender as? String {
                if let ptvc = segue.destinationViewController as? PingsTableViewController {
                    ptvc.fileName = fileName
                }
            }
        }
    }
    
    // MARK: - getters and settes
    var isRemoveAd: Bool {
        get {
            return PingsProducts.store.isProductPurchased(PingsProducts.RemoveAd)
        }
    }
    
    
    var recentFileIndex:Int? {
        willSet {
            
        }
        didSet {
            if recentFileIndex != -1 && recentFileIndex < fileList.count{
               let shortcut1 = UIMutableApplicationShortcutItem(type: AppDelegate.ShortcutIdentifier.Second.type, localizedTitle: "Ping Recent", localizedSubtitle: "\(fileList[recentFileIndex!])", icon: UIApplicationShortcutIcon(type: .Time), userInfo: ["applicationShortcutUserInfoKey": recentFileIndex!])
                UIApplication.sharedApplication().shortcutItems = [shortcut1]
                NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: YSFGlobalConstants.BundleId.WidgetId)
            } else {
                UIApplication.sharedApplication().shortcutItems = []
            }
            
            
            // Update the application providing the initial 'dynamic' shortcut items.
            
        }
    }
}
