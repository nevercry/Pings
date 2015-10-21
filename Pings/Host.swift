//
//  Host.swift
//  Pings
//
//  Created by nevercry on 10/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import Foundation

class Host {
    var hostName: String?
    var averageTime: String?
    
    init(hostName: String, averageTime: String) {
        self.hostName = hostName
        self.averageTime = averageTime
    }
}
