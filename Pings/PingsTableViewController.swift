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

class PingsTableViewController: UITableViewController, CDZPingerDelegate, MBProgressHUDDelegate {
    
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
    
    private var fastServer: Host?
    private let spinner = MBProgressHUD.init()
    
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
    var unPingedServerCount: Int = 0 {
        didSet {
            spinner.labelText = pingProgress()
        }
    }
    
    @IBAction func pings(sender: AnyObject) {
        unPingedServerCount = serverLists.count
        spinner.show(true)
        beginPingServer()
    }
    
    // MARK: - Convenience Methods
    
    func pingProgress() -> String {
        let serverCount = serverLists.count
        let progress:Int
        if serverCount > 0 {
            progress = (serverLists.count - unPingedServerCount) * 100 / serverLists.count
        } else {
            progress = 0
        }
        
        return "\(progress)%"
    }
    
    func fastPingMs() -> Int {
        var timeStr = fastServer!.averageTime!
        let sufixRange = timeStr.rangeOfString(" ms")
        timeStr.removeRange(sufixRange!)
        return Int(timeStr)!
    }
    
    func showFastServer() {
        let alertControl = UIAlertController.init(title: "Fast Server", message: "\(fastServer!.hostName!) \(fastServer!.averageTime!)", preferredStyle: .Alert)
        let alertAction = UIAlertAction.init(title: "Copy", style: .Default) { action in
            let pasteboard = UIPasteboard.generalPasteboard()
            pasteboard.string = self.fastServer!.hostName!
            self.fastServer = nil
        }
        alertControl.addAction(alertAction)
        self.presentViewController(alertControl, animated: true, completion: nil)
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
        let timer = sender as! NSTimer
        let host = timer.userInfo as! Host
        
        host.averageTime = "timeout"
        if unPingedServerCount == 0 {
            spinner.hide(true)
        } else {
            unPingedServerCount--
            beginPingServer()
        }
    }
    
    
    // MARK: - View LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.delegate = self
        self.view.addSubview(spinner)
        updateUI()
    }
    
    // MARK: - MBProgressHUDDelegate
    func hudWasHidden(hud: MBProgressHUD!) {
        if fastServer != nil {
            if let fastIndex = serverLists.indexOf({$0 === fastServer!}) {
                let indexPath = NSIndexPath.init(forRow: fastIndex, inSection: 0)
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
            }
            showFastServer()
        }
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
        
        if fastServer != nil {
            if Int(avgmSec) < fastPingMs() {
                fastServer = host
            }
        } else {
            fastServer = host
        }
        
        pinger.stopPinging()
        
        unPingedServerCount--
        
        if unPingedServerCount > 0 {
            beginPingServer()
        } else {
            spinner.hide(true)
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
            spinner.hide(true)
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
        
        let host = serverLists[indexPath.row]
        cell.textLabel?.text = host.hostName
        cell.detailTextLabel?.text = host.averageTime
        
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
