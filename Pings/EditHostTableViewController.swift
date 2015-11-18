//
//  EditHostTableViewController.swift
//  Pings
//
//  Created by nevercry on 11/19/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit


class EditHostTableViewController: AddHostTableViewController {
    var host: Host? {
        didSet {
            hostName = host?.hostName
            nickName = host?.nickName
        }
    }
    
    // this is a convenient way to create this view controller without a imageURL
    convenience init() {
        self.init(host: nil)
    }
    
    init(host: Host?) {
        self.host = host
        super.init(nibName: nil, bundle: nil)
    }
    
    // Xcode 7
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        textField.text = host?.hostName
        nickNameTextField.text = nickName
        
        
    }
    
    
}