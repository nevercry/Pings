//
//  DataSource.swift
//  Pings
//
//  Created by nevercry on 11/21/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

struct DataSource {
    
    let server: Item
    
    enum Item {
        case Server(String,String)
        case Unknown
    }
    
    init(data: [String : AnyObject]) {
        if let serverItem = data["serverName"] as? String {
            let avgTime = data["avgTime"] as! String
            server = Item.Server(serverItem, avgTime)
        } else {
            server = Item.Unknown
        }
    }
}
