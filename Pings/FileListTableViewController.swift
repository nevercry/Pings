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

    // MARK: - DirectoryWatcherDelegate 
    
    func directoryDidChange(folderWatcher: DirectoryWatcher!) {
        fileList.removeAll()
        let documentsDirectoryPath = AppDelegate().applicationDocumentsDirectory()
    
        let documentsDirectoryContents = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(documentsDirectoryPath)
        
        if documentsDirectoryContents.count == 0 {
            let defaultConfPathURL = NSURL(fileURLWithPath: documentsDirectoryPath).URLByAppendingPathComponent("\(Constants.DefaultFileName).\(Constants.FileExtension)")
            NSFileManager.defaultManager().createFileAtPath(defaultConfPathURL.path!, contents: nil, attributes: nil)
        } else {
            fileList = documentsDirectoryContents
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
    

    
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.SegueIdentifier {
            if let cell = sender as? UITableViewCell {
                let fileName = cell.textLabel!.text
                if let ptvc = segue.destinationViewController as? PingsTableViewController {
                    ptvc.fileName = fileName
                }
            }
        }
    }
    

}
