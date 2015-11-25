//
//  FileIOHelper.swift
//  Pings
//
//  Created by nevercry on 11/25/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import Foundation
import PingsSharedDataLayer

public typealias CompletionHandler = (sucess: Bool, error: String?) -> ()

public class FileIOHelper: NSObject {
    
    public class func creatFile(content: String, fileName: String, handler: CompletionHandler) {
        let dir: NSURL = NSURL(fileURLWithPath: AppDelegate().applicationDocumentsDirectory())
        let fileurl =  dir.URLByAppendingPathComponent(fileName + ".conf")
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileurl.path!) {
            handler(sucess: false, error: "File Name Already Exist!")
        } else {
            do {
                try content.writeToURL(fileurl, atomically: true, encoding: NSUTF8StringEncoding)
            } catch let error as NSError {
                handler(sucess: false, error: error.localizedDescription)
            }
            
            handler(sucess: true, error: nil)
        }
    }
    
    public class func updateFile(content: String, fileName: String, oldFileName: String, handler: CompletionHandler) {
        let dir: NSURL = NSURL(fileURLWithPath: AppDelegate().applicationDocumentsDirectory())
        let fileurl =  dir.URLByAppendingPathComponent(fileName + ".conf")
        let oldFileUrl = dir.URLByAppendingPathComponent(oldFileName + ".conf")
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileurl.path!) {
            handler(sucess: false, error: "File Name Already Exist!")
        }
        
        if !NSFileManager.defaultManager().fileExistsAtPath(oldFileUrl.path!) {
            handler(sucess: false, error: "Old File Not Exist Wierd!")
        }
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(oldFileUrl, toURL: fileurl)
        } catch let error as NSError {
            handler(sucess: false, error: error.localizedDescription)
        }
        
        do {
            try content.writeToURL(fileurl, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            handler(sucess: false, error: error.localizedDescription)
        }
        
        handler(sucess: true, error: nil)
    }
    
    
    public class func parseFile(fileName: String)-> [Host] {
        let fileURL = NSURL(fileURLWithPath: AppDelegate().applicationDocumentsDirectory()).URLByAppendingPathComponent(fileName + ".conf")
        let fileText: String
        do {
            fileText = try String(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print("\(error.localizedDescription)")
            return []
        }
        
        var serverLists = [Host]()
        
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
        
        return serverLists
    }
    
    
    
}