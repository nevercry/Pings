//
//  AddThingTableViewController.swift
//  Pings
//
//  Created by nevercry on 10/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit

class AddThingTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField! { didSet { textField.delegate = self } }
    
    var thing: String? {
        didSet {
            if thing?.characters.count > 0 {
                doneBarButton.enabled = true
            } else {
                doneBarButton.enabled = false
            }
        }
    }
    
    private var tfObserver: NSObjectProtocol?
    
    func observeTextFields() {
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        tfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: queue) { notification in
            self.thing = self.textField.text
        }
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        
        
    }
    
    
    // MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeTextFields()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = tfObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
    
    
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    
}
