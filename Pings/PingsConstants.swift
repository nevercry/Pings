//
//  PingsConstants.swift
//  Pings
//
//  Created by nevercry on 11/13/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit

//Declare all the static constants here
struct YSFGlobalConstants {
    // MARK: String Constants
    struct Strings {
        static let PingsURLNotification = "PingsURL Radio Station"
        static let PingsURLKey = "PingsURL URL Key"
        
        static let FileExtension = "conf"
        static let DefaultFileName = "DEFAULT"
        static let PingsHasCreateDefaultFileOnceKey = "PingsHasCreateDefaultFileOnceKey"  // Only create default file once
    }
    
    struct BundleId {
        static let WidgetId = "com.nevercry.Pings.Pings-Widget"
    
    }
    
    struct Banner {
        static let BannerViewActionWillBegin = "BannerViewActionWillBegin"
        static let BannerViewActionDidFinish = "BannerViewActionDidFinish"
    }

}