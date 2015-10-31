//
//  FileListTableViewController.swift
//  Pings
//
//  Created by nevercry on 10/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit

class FileListTableViewController: UITableViewController, DirectoryWatcherDelegate {
    
    var fileList = [String]()
    var docWatcher: DirectoryWatcher?
    
    var myObserver: AnyObject?
    
    
    private struct Constants {
        static let FileExtension = "conf"
        static let DefaultFileName = "DEFAULT"
        static let CellReuseIdentifier = "File Cell"
        static let SegueIdentifier = "Show Servers"
    }
    

    // MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let watchPath = AppDelegate().applicationDocumentsDirectory()
        
        docWatcher = DirectoryWatcher.watchFolderWithPath(watchPath, delegate: self)
        directoryDidChange(docWatcher)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        
        myObserver = center.addObserverForName(PingsURL.Notification, object: appDelegate, queue: queue) { notification in
            if let url = notification.userInfo?[PingsURL.Key] as? NSURL {
                
                let defaultManager = NSFileManager.defaultManager()
                let documentsDirectoryPath = AppDelegate().applicationDocumentsDirectory()
                let moveFileURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent(url.lastPathComponent!)
                let srcPath = url.path!
                try! defaultManager.moveItemAtPath(srcPath, toPath: moveFileURL.path!)
                
                
                var fileName = url.lastPathComponent!
                let suffixRange = fileName.rangeOfString(".conf")!
                fileName.removeRange(suffixRange)
                self.performSegueWithIdentifier(Constants.SegueIdentifier, sender: fileName)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let center = NSNotificationCenter.defaultCenter()
        let appDelegate = UIApplication.sharedApplication().delegate
        center.removeObserver(myObserver!, name: PingsURL.Notification, object: appDelegate)
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
                    fileList.append(curFileName)
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
        var fileName = fileList[indexPath.row]
        let extensionSuffixRange = fileName.rangeOfString(".conf")
        fileName.removeRange(extensionSuffixRange!)
        cell.textLabel!.text = fileName

        return cell
    }
    

    
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.SegueIdentifier {
            if let cell = sender as? UITableViewCell {
                let fileName = cell.textLabel!.text
                if let ptvc = segue.destinationViewController as? PingsTableViewController {
                    ptvc.fileName = fileName
                }
            } else if let fileName = sender as? String {
                if let ptvc = segue.destinationViewController as? PingsTableViewController {
                    ptvc.fileName = fileName
                }
            }
        }
    }
    

}
