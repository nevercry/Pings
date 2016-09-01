//
//  BannerViewController.swift
//  Pings
//
//  Created by nevercry on 11/23/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

/*
Abstract:
A container view controller that manages an ADBannerView and a content view controller.
*/

import UIKit
import StoreKit
import Firebase

class BannerViewController: UIViewController {
    
    
    @IBOutlet weak var bannerView: GADBannerView!
    var bannerContentController: UIViewController?
    
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - View LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerContentController = self.childViewControllers[0]
        
        // IAP
        // Subscribe to a notification that fires when a product is purchased.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BannerViewController.productPurchased(_:)), name: IAPHelperProductPurchasedNotification, object: nil)
        
        // Check RemoveAd Whether Purchased
        let removeAdProductID = PingsProducts.RemoveAd
        if !PingsProducts.store.isProductPurchased(removeAdProductID) {
            // TODO: Not show Ad anymore
            bannerView.adUnitID = "ca-app-pub-5747346530004992/7321376863"
            bannerView.rootViewController = self
            let request = GADRequest()
            request.testDevices = ["3e450c8b8bf03d38e68d4fae12fed9ae"]
            
            bannerView.loadRequest(request)
        }
    }
    
    // MARK: - IAP
    func productPurchased(sender: NSNotification) {
        // Remove Ad
        bannerView?.delegate = nil
        bannerView?.removeFromSuperview()
        bannerView = nil
        
        UIView.animateWithDuration(0.25) { () -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return bannerContentController!.preferredInterfaceOrientationForPresentation()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
