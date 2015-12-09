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
import PingsSharedDataLayer

class PingsTableViewController: UITableViewController, CDZPingerDelegate, MBProgressHUDDelegate {
    
    private struct Constants {
        static let EditHostSegueIdentifier = "Edit Host"
    }
    
   
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
    
    var isFromShortCut = false
    
    @IBOutlet weak var pingsBarButton: UIBarButtonItem!
    
    
    
    private struct Storyboard {
        static let CellReuseIdentifier = "Server Cell"
    }

    
    // MARK: - Unwind Segue
    @IBAction func unwindToPingsForAddDone(sender: UIStoryboardSegue) {
        if let attvc = sender.sourceViewController as? AddHostTableViewController {
            if let hostName = attvc.hostName {
                let host = Host.init(hostName: hostName,averageTime: "")
                var saveStr = hostName
                if let nickName = attvc.nickName {
                    if nickName.characters.count > 0 {
                        saveStr = "\(hostName)\"\(nickName)\""
                        host.nickName = nickName
                    }
                }
                
                savefile(saveStr)
                serverLists.append(host)
                tableView.reloadData()
                updateUI()
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
                
                updateFile()
                tableView.reloadData()
            }
        }
    }
    
    
    
    // MARK: - Parse File
    func readfile(fileName: String) {
        let fileURL = NSURL(fileURLWithPath: AppDelegate().applicationDocumentsDirectory()).URLByAppendingPathComponent(fileName + ".conf")
        let fileText = try! String(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding)
        
        if fileText.characters.count > 0 {
            let scanner = NSScanner(string: fileText)
            let SERVER = "[Server]\n"
            let linebreak = NSCharacterSet.newlineCharacterSet()
            scanner.scanString(SERVER, intoString: nil)
            var hostName: NSString?
            
            while !scanner.atEnd {
                scanner.scanUpToCharactersFromSet(linebreak, intoString: &hostName)
                if let stringArr = hostName?.componentsSeparatedByString("\"") {
                    let unFormatHostName = stringArr[0]
                    if unFormatHostName.characters.count > 0 {
                        let hostName = unFormatHostName.stringByReplacingOccurrencesOfString(" ", withString: "")
                        let host = Host(hostName: hostName, averageTime: "")
                        if stringArr.count > 1 {
                            let nickName = stringArr[1]
                            host.nickName = nickName
                        }
                        serverLists.append(host)
                    }
                }
            }
        }
    }
    
    func savefile(content: String) {
        let dir:NSURL = NSURL(fileURLWithPath: AppDelegate().applicationDocumentsDirectory())
        let fileurl =  dir.URLByAppendingPathComponent(fileName! + ".conf")
        
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
    
    func removeServerAtIndex(index: Int) {
        
        serverLists.removeAtIndex(index)
        updateFile()
    }
    
    func updateFile() {
        let serverS = serverLists.map({ $0.hostName! + ($0.nickName! == $0.hostName! ? "" : "\"\($0.nickName!)\"") }).joinWithSeparator("\n") + "\n"
        
        let fileURL = NSURL(fileURLWithPath: AppDelegate().applicationDocumentsDirectory()).URLByAppendingPathComponent(fileName! + ".conf")
        
        try! serverS.writeToURL(fileURL, atomically: true, encoding: NSUTF8StringEncoding)
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
        if serverLists.count > 0 {
            unPingedServerCount = serverLists.count
            spinner.show(true)
            beginPingServer()
        }
    }
    
    // MARK: - Convenience Methods
    
    func pingProgress() -> String {
        let serverCount = serverLists.count
        let progress:Int
        if serverCount > 0 {
            
            let progressCaCulator = (serverLists.count - unPingedServerCount) * 100 / serverLists.count
            
            if progressCaCulator > 100 {
                print("error progress should not greater than 100, sth error should occur!!")
                progress = 100
            } else {
                progress = progressCaCulator
            }
            
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
        let lastUnPingedIndex = unPingedServerCount - 1
        let host = serverLists[lastUnPingedIndex]
        pinger = CDZPinger.init(host: host.hostName)
        pinger!.delegate = self
        pinger!.startPinging()
        
        //debug 
        
        print("lastUnPingIndex \(lastUnPingedIndex)  unPingServerCount \(unPingedServerCount)")
        
        timeoutTimer?.invalidate()
        timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "checkIfTimeOut:", userInfo: host, repeats: false)
    }
    
    func checkIfTimeOut(sender: AnyObject?) {
        pinger!.stopPinging()
        unPingedServerCount--
        
        let timer = sender as! NSTimer
        let host = timer.userInfo as! Host
        
        host.averageTime = "timeout"
        
        if unPingedServerCount > 0 {
            beginPingServer()
        } else {
            spinner.hide(true)
            tableView.reloadData()
        }
    }
    
    
    // MARK: - View LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.delegate = self
        self.view.addSubview(spinner)
    
        updateUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFromShortCut {
            pings(self)
        }
    }
    
    // MARK: - MBProgressHUDDelegate
    func hudWasHidden(hud: MBProgressHUD!) {
        if fastServer != nil {
            if let fastIndex = serverLists.indexOf({$0 === fastServer!}) {
                let indexPath = NSIndexPath.init(forRow: fastIndex, inSection: 0)
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
            }
            
            //MARK: ping actions is over, show result
            showFastServer()
            
            //MARK: Connect to iWatch
            
            do {
                try WatchSessionManager.sharedManager.updateAppicationContext(["serverName":fastServer!.hostName!,"avgTime":fastServer!.averageTime!])
            } catch {
                let alertController = UIAlertController(title: "Oops!", message: "Looks like your \(fastServer?.hostName) got stuck on the way!", preferredStyle: .Alert)
                let okAction = UIAlertAction.init(title: "OK", style: .Cancel, handler: nil)
                alertController.addAction(okAction)
                presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - CDPingerDelegate 
    func pinger(pinger: CDZPinger!, didUpdateWithAverageSeconds seconds: NSTimeInterval) {
        timeoutTimer?.invalidate()
        pinger.stopPinging()
        
        let lastUnPingedIndex = unPingedServerCount - 1
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
        pinger.stopPinging()
        
        let lastUnPingedIndex = unPingedServerCount - 1
        let host = serverLists[lastUnPingedIndex]
        host.averageTime = "\(error.localizedDescription)"
        
        unPingedServerCount--
        if unPingedServerCount > 0 {
            beginPingServer()
        } else {
            spinner.hide(true)
            tableView.reloadData()
            updateUI()
        }
    }
    
    // MARK: - Preview actions
    
    override func previewActionItems() -> [UIPreviewActionItem] {
        let previewActionItem1 = UIPreviewAction(title: "Ping", style: .Default) { previewAction, viewController in
            
            let pingsTVC = self.storyboard?.instantiateViewControllerWithIdentifier("PingsTableViewController") as? PingsTableViewController
            let tmpVC = viewController as! PingsTableViewController
            
            pingsTVC?.fileName = tmpVC.fileName
            pingsTVC?.isFromShortCut = true
            
            if let navVC = UIApplication.sharedApplication().delegate?.window??.rootViewController as? UINavigationController {
                navVC.pushViewController(pingsTVC!, animated: false)
            }
        }
        
        return [previewActionItem1]
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
        cell.textLabel?.text = host.nickName
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

    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            removeServerAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    

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
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.EditHostSegueIdentifier {
            if let editVC = segue.destinationViewController as? EditHostTableViewController {
                let cell = sender as! UITableViewCell
                let indexPath = tableView.indexPathForCell(cell)
                let host = serverLists[indexPath!.row]
                editVC.host = host
            }
        }
    }
    

}
