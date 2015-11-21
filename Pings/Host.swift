//
//  Host.swift
//  Pings
//
//  Created by nevercry on 10/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import Foundation

public class Host {
    public    var hostName: String?
    public    var averageTime: String?
    public    var nickName: String?
    
    public    init(hostName: String, averageTime: String) {
        self.hostName = hostName
        self.averageTime = averageTime
        self.nickName = hostName
    }
}
