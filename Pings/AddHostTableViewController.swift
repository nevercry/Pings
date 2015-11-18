//
//  AddThingTableViewController.swift
//  Pings
//
//  Created by nevercry on 10/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit

class AddHostTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField! { didSet { textField.delegate = self } }
    @IBOutlet weak var nickNameTextField: UITextField! { didSet { nickNameTextField.delegate = self } }
    
    var hostName: String? {
        didSet {
            if hostName?.characters.count > 0 {
                doneBarButton.enabled = true
            } else {
                doneBarButton.enabled = false
            }
        }
    }
    
    var nickName: String?
    
    private var tfObserver: NSObjectProtocol?
    private var nickNametfObserver: NSObjectProtocol?
    
    func observeTextFields() {
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        tfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: queue) { [weak self] notification in
            guard let strongSelf = self else { return }
            strongSelf.hostName = strongSelf.textField.text
        }
        nickNametfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: nickNameTextField, queue: queue) { [weak self] notification in
            guard let strongSelf = self else { return }
            strongSelf.nickName = strongSelf.nickNameTextField.text
        }
        
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
        
        if let observer = nickNametfObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    
}
