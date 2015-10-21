//
//  PingsTableViewController.swift
//  Pings
//
//  Created by nevercry on 10/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit
import MBProgressHUD
import CDZPinger

class PingsTableViewController: UITableViewController, CDZPingerDelegate {
    
    // MARK: - Model
    var fileName: String? {
        didSet {
            title = fileName
            readfile(fileName!)
        }
    }
    private var serverLists = [Host]()
    private var pinger: CDZPinger?
    private var timeoutTimer: NSTimer?
    
    @IBOutlet weak var pingsBarButton: UIBarButtonItem!
    
    
    
    private struct Storyboard {
        static let CellReuseIdentifier = "Server Cell"
    }

    
    @IBAction func unwindToPingsForAddDone(sender: UIStoryboardSegue) {
        if let attvc = sender.sourceViewController as? AddThingTableViewController {
            if let thing = attvc.thing {
                savefile(thing)
                let host = Host.init(hostName: thing,averageTime: "")
                serverLists.append(host)
                tableView.reloadData()
                updateUI()
            }
        }
    }
    
    func readfile(fileName: String) {
        let fileURL = NSURL(fileURLWithPath: AppDelegate().applicationDocumentsDirectory()).URLByAppendingPathComponent(fileName)
        let fileText = try! String(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding)
        
        if fileText.characters.count > 0 {
            let scanner = NSScanner(string: fileText)
            
            let SERVER = "[Server]"
            let flagSet = NSCharacterSet.newlineCharacterSet()
            scanner.scanString(SERVER, intoString: nil)
            var hostName: NSString?
            while scanner.scanUpToCharactersFromSet(flagSet, intoString: &hostName) {
                let host = Host(hostName: String(hostName!), averageTime: "")
                serverLists.append(host)
            }
        }
    }
    
    func savefile(content: String) {
        let dir:NSURL = NSURL(fileURLWithPath: AppDelegate().applicationDocumentsDirectory())
        let fileurl =  dir.URLByAppendingPathComponent(fileName!)
        
        let string = "\(content)\n"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileurl.path!) {
            if let fileHandle = try? NSFileHandle(forWritingToURL: fileurl) {
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }
            else {
                print("Can't open fileHandle")
            }
        }
    }
    
    func updateUI() {
        if serverLists.count > 0 {
            pingsBarButton.enabled = true
        } else {
            pingsBarButton.enabled = false
        }
    }
    
    // MARK: Ping every URL in Server List 
    var unPingedServerCount: Int = 0
    
    @IBAction func pings(sender: AnyObject) {
        unPingedServerCount = serverLists.count
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        beginPingServer()
    }
    
    func beginPingServer() {
        var lastUnPingedIndex: Int
        if unPingedServerCount > 0 {
            lastUnPingedIndex = unPingedServerCount - 1
        } else {
            lastUnPingedIndex = unPingedServerCount
        }
        let host = serverLists[lastUnPingedIndex]
        pinger = CDZPinger.init(host: host.hostName)
        pinger!.delegate = self
        pinger!.startPinging()
        
        timeoutTimer?.invalidate()
        timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "checkIfTimeOut:", userInfo: host, repeats: false)
    }
    
    func checkIfTimeOut(sender: AnyObject?) {
        let host = sender as! Host
        if host.averageTime?.characters.count == 0 {
            host.averageTime = "timeout"
            if unPingedServerCount == 0 {
                MBProgressHUD.hideAllHUDsForView(view, animated: true)
            } else {
                unPingedServerCount--
                beginPingServer()
            }
        }
    }
    
    
    // MARK: - View LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    // MARK: - CDPingerDelegate 
    func pinger(pinger: CDZPinger!, didUpdateWithAverageSeconds seconds: NSTimeInterval) {
        timeoutTimer?.invalidate()
        var lastUnPingedIndex: Int
        if unPingedServerCount > 0 {
            lastUnPingedIndex = unPingedServerCount - 1
        } else {
            lastUnPingedIndex = unPingedServerCount
        }
        let host = serverLists[lastUnPingedIndex]
        let avgmSec = seconds * 1000
        let formatStr = String(format: "%.f", avgmSec)
        host.averageTime = "\(formatStr) ms"
        pinger.stopPinging()
        
        unPingedServerCount--
        if unPingedServerCount > 0 {
            beginPingServer()
        } else {
            MBProgressHUD.hideAllHUDsForView(view, animated: true)
            tableView.reloadData()
            updateUI()
        }
        
    }
    
    func pinger(pinger: CDZPinger!, didEncounterError error: NSError!) {
        timeoutTimer?.invalidate()
        var lastUnPingedIndex: Int
        if unPingedServerCount > 0 {
            lastUnPingedIndex = unPingedServerCount - 1
        } else {
            lastUnPingedIndex = unPingedServerCount
        }
        let host = serverLists[lastUnPingedIndex]
        host.averageTime = "\(error.localizedDescription)"
        pinger.stopPinging()
        
        unPingedServerCount--
        if unPingedServerCount > 0 {
            beginPingServer()
        } else {
            MBProgressHUD.hideAllHUDsForView(view, animated: true)
            tableView.reloadData()
            updateUI()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return serverLists.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath)
        
        cell.textLabel?.text = serverLists[indexPath.row].hostName
        cell.detailTextLabel?.text = serverLists[indexPath.row].averageTime

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
