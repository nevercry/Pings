//
//  EditOrCreateConfigFileTableViewController.swift
//  Pings
//
//  Created by nevercry on 11/25/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit
import PingsSharedDataLayer

class EditOrCreateConfigFileTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    
    weak var lastPresentingVC: FileListTableViewController?
    
    var fileName: String? {
        didSet {
            if !isEditFile {
                doneBarButton.enabled = fileName?.characters.count > 0
            }
        }
    }
    var serverList = [Host]()
    
    var isEditFile = false
    
    private var oldFileName: String?
    
    struct Constants {
        static let ConfigurationNameCellIdentifier = "Configuration Name Cell"
        static let AddServerCellIdentifier = "Add New Server Cell"
        static let ServerCellIdentifier = "Server Cell"
        static let EditServerSegueIdentifier = "Edit Server"
    }
    
    private var tfObserver: NSObjectProtocol?
    
    func observeTextField() {
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        tfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: nil, queue: queue, usingBlock: { (notification) -> Void in
            let textFiled = notification.object as! UITextField
            
            self.fileName = textFiled.text
            
            if self.isEditFile {
                self.doneBarButton.enabled = (self.fileName?.characters.count > 0 && true)
            }
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isEditFile {
            // SetUp serverList
            serverList = FileIOHelper.parseFile(fileName!)
            
        }

    }
    
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeTextField()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = tfObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - For Editting
    
    func editFile(fileName: String) {
        isEditFile = true
        self.fileName = fileName
        self.oldFileName = fileName
    }
    
    // MARK: - Event Response
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        view.endEditing(true)
        if doneBarButton.enabled {
            let alertVC = UIAlertController.init(title: "Discard unsaved changed?", message: nil, preferredStyle: .Alert)
            let stayAction = UIAlertAction.init(title: "Stay", style: .Cancel, handler: nil)
            let discardAction = UIAlertAction.init(title: "Discard", style: .Default, handler: { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            alertVC.addAction(stayAction)
            alertVC.addAction(discardAction)
            
            presentViewController(alertVC, animated: true, completion: nil)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        view.endEditing(true)
        
        let serverS = serverList.map({ $0.hostName! + ($0.nickName! == $0.hostName! ? "" : "\"\($0.nickName!)\"") }).joinWithSeparator("\n") + "\n"
        let completeHandler = { (sucess: Bool, error: String?) -> () in
            if !sucess {
                let alertVC = UIAlertController.init(title: "Error", message: "\(error!)", preferredStyle: .Alert)
                let cancelAction = UIAlertAction.init(title: "OK", style: .Cancel, handler: nil)
                alertVC.addAction(cancelAction)
                self.presentViewController(alertVC, animated: true, completion: nil)
            } else {
                self.lastPresentingVC?.editFileList(sender)
                self.dismissViewControllerAnimated(true, completion: nil)
                
            }
        }
        if !isEditFile {
            FileIOHelper.creatFile(serverS, fileName: fileName!, handler: completeHandler)
        } else {
            FileIOHelper.updateFile(serverS, fileName: fileName!, oldFileName:oldFileName!, handler: completeHandler)
        }
    }
    
    // MARK: - Unwind Segue
    @IBAction func unwindToPingsForAddDone(sender: UIStoryboardSegue) {
        if let attvc = sender.sourceViewController as? AddHostTableViewController {
            if let hostName = attvc.hostName {
                let host = Host.init(hostName: hostName,averageTime: "")
                if let nickName = attvc.nickName {
                    if nickName.characters.count > 0 {
                        host.nickName = nickName
                    }
                }
                serverList.append(host)
                tableView.reloadData()
            }
        }
    }
    
    @IBAction func unwindToPingsForEditDone(sender: UIStoryboardSegue) {
        if let editVC = sender.sourceViewController as? EditHostTableViewController {
            
            if editVC.host?.hostName != editVC.hostName || editVC.host?.nickName != editVC.nickName {
                if editVC.hostName != "" {
                    editVC.host?.hostName = editVC.hostName
                }
                
                if editVC.nickName != "" {
                    editVC.host?.nickName = editVC.nickName
                }
                
                tableView.reloadData()
            }
        }
    }

    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows: Int
        
        if section == 0 {
            numberOfRows = 1
        } else {
            numberOfRows = serverList.count + 1
        }
        
        return numberOfRows
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        
        if section == 0 {
            title = "name"
        } else if section == 1 {
            title = "servers"
        }
        
        return title
    }
        
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier(Constants.ConfigurationNameCellIdentifier)!
            let textField = cell.viewWithTag(1) as! UITextField
            textField.text = fileName
        } else {
            if indexPath.row == serverList.count {
                cell = tableView.dequeueReusableCellWithIdentifier(Constants.AddServerCellIdentifier)!
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier(Constants.ServerCellIdentifier)!
                let host = serverList[indexPath.row]
                cell.textLabel?.text = host.hostName
                cell.detailTextLabel?.text = host.nickName
            }
        }
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.EditServerSegueIdentifier {
            if let destinationVC = segue.destinationViewController as? EditHostTableViewController {
                let cell = sender as! UITableViewCell
                let indexPath = tableView.indexPathForCell(cell)
                let host = serverList[indexPath!.row]
                destinationVC.host = host
            }
        }
    }
    

}
