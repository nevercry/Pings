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
import iAd
import StoreKit

class BannerViewController: UIViewController, ADBannerViewDelegate {
    
    var bannerView: ADBannerView?
    var contentController: UIViewController?
    
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - View LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentController = self.childViewControllers[0]
        
        // IAP
        // Subscribe to a notification that fires when a product is purchased.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "productPurchased:", name: IAPHelperProductPurchasedNotification, object: nil)
        
        // Check RemoveAd Whether Purchased
        let removeAdProductID = PingsProducts.RemoveAd
        if !PingsProducts.store.isProductPurchased(removeAdProductID) {
            // TODO: Not show Ad anymore
            bannerView = ADBannerView.init(adType: .Banner)
            bannerView?.delegate = self
            view.addSubview(bannerView!)
        }
    }
    
    override func viewDidLayoutSubviews() {
        var contentFrame = view.bounds, bannerFrame = CGRectZero
        
        bannerFrame.size = bannerView?.sizeThatFits(contentFrame.size) ?? CGSizeZero
        
        if bannerView?.bannerLoaded == true {
            contentFrame.size.height -= bannerFrame.size.height
            bannerFrame.origin.y = contentFrame.size.height
        } else {
            bannerFrame.origin.y = contentFrame.size.height
        }
        contentController!.view.frame = contentFrame
        bannerView?.frame = bannerFrame
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
        return contentController!.preferredInterfaceOrientationForPresentation()
    }
    
    // MARK: - ADBannerViewDelegate 
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        UIView.animateWithDuration(0.25) { () -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        print("didFailToReceiveAdWithError \(error)");
        
        UIView.animateWithDuration(0.25) { () -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        NSNotificationCenter.defaultCenter().postNotificationName(YSFGlobalConstants.Banner.BannerViewActionWillBegin, object: self)
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        NSNotificationCenter.defaultCenter().postNotificationName(YSFGlobalConstants.Banner.BannerViewActionDidFinish, object: self)
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
