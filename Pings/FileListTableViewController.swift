//
//  FileListTableViewController.swift
//  Pings
//
//  Created by nevercry on 10/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit

class FileListTableViewController: UITableViewController, DirectoryWatcherDelegate {
    
    var editBarButton: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .Edit, target: nil, action: "editFileList:")
    
    var fileList = [String]()
    var docWatcher: DirectoryWatcher?
    
    var myObserver: NSObjectProtocol?
    
    private struct Constants {
        static let FileExtension = "conf"
        static let DefaultFileName = "DEFAULT"
        static let CellReuseIdentifier = "File Cell"
        static let SegueIdentifier = "Show Servers"
    }
    
    // MARK: - ShortCut Methods 
    
    var recentNotFirstFileIndex:Int? {
        willSet {
            
        }
        didSet {
            let shortcut1 = UIMutableApplicationShortcutItem(type: AppDelegate.ShortcutIdentifier.Second.type, localizedTitle: "Ping Recent", localizedSubtitle: "\(fileList[recentNotFirstFileIndex!])", icon: UIApplicationShortcutIcon(type: .Time), userInfo: ["applicationShortcutUserInfoKey": recentNotFirstFileIndex!])
            
            // Update the application providing the initial 'dynamic' shortcut items.
            UIApplication.sharedApplication().shortcutItems = [shortcut1]
        }
    }
    

    // MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editBarButton.target = self
        self.navigationItem.rightBarButtonItem = editBarButton
        
        let watchPath = AppDelegate().applicationDocumentsDirectory()
        
        docWatcher = DirectoryWatcher.watchFolderWithPath(watchPath, delegate: self)
        directoryDidChange(docWatcher)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        
        myObserver = center.addObserverForName(PingsURL.Notification, object: appDelegate, queue: queue) { [weak self] notification  in
            guard let strongSelf = self else { return }
            if let url = notification.userInfo?[PingsURL.Key] as? NSURL {
                let defaultManager = NSFileManager.defaultManager()
                let documentsDirectoryPath = AppDelegate().applicationDocumentsDirectory()
                let moveFileURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent(url.lastPathComponent!)
                let srcPath = url.path!
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

    func editFileList(var sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.editing, animated: true)
        let sysItem = tableView.editing ? UIBarButtonSystemItem.Done : .Edit
        sender = UIBarButtonItem.init(barButtonSystemItem: sysItem, target: self, action: "editFileList:")
        self.navigationItem.rightBarButtonItem = sender
    }
    
    func remveFileAtIndex(index: Int) {
        let fileName = fileList[index]
        let documentsDirectoryPath = AppDelegate().applicationDocumentsDirectory()
        let defaultManager = NSFileManager.defaultManager()
        let fileURL = NSURL.fileURLWithPath(documentsDirectoryPath).URLByAppendingPathComponent(fileName + ".\(Constants.FileExtension)")
        try! defaultManager.removeItemAtURL(fileURL)
        fileList.removeAtIndex(index)
    }
    
    // MARK: - DirectoryWatcherDelegate 
    
    func directoryDidChange(folderWatcher: DirectoryWatcher!) {
        fileList.removeAll()
        let documentsDirectoryPath = AppDelegate().applicationDocumentsDirectory()
        let defaultManager = NSFileManager.defaultManager()
    
        let documentsDirectoryContents = try! defaultManager.contentsOfDirectoryAtPath(documentsDirectoryPath)
        
        if documentsDirectoryContents.count == 0 {
            let defaultConfPathURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent("\(Constants.DefaultFileName).\(Constants.FileExtension)")
            defaultManager.createFileAtPath(defaultConfPathURL.path!, contents: nil, attributes: nil)
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
                            try! defaultManager.moveItemAtPath(srcPath, toPath: moveFileURL.path!)
                        }
                    } 
                }
            }
        }
        
        tableView.reloadData()
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
        if indexPath.row == 0 {
            return false
        } else {
            return true
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            remveFileAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
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
                
                guard let noFirstIndex = index?.row where index?.row != 0 else {
                    return
                }
                
                recentNotFirstFileIndex = noFirstIndex
                
            } else if let fileName = sender as? String {
                if let ptvc = segue.destinationViewController as? PingsTableViewController {
                    ptvc.fileName = fileName
                }
            }
        }
    }
    

}
