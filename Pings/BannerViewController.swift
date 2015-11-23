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

class BannerViewController: UIViewController, ADBannerViewDelegate {
    
    var bannerView: ADBannerView?
    var contentController: UIViewController?
    
    // MARK: - View LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        bannerView = ADBannerView.init(adType: .Banner)
        bannerView?.delegate = self
        contentController = self.childViewControllers[0]
        view.addSubview(bannerView!)
    }
    
    override func viewDidLayoutSubviews() {
        var contentFrame = view.bounds, bannerFrame = CGRectZero
        
        bannerFrame.size = bannerView!.sizeThatFits(contentFrame.size)
        
        if bannerView!.bannerLoaded {
            contentFrame.size.height -= bannerFrame.size.height
            bannerFrame.origin.y = contentFrame.size.height
        } else {
            bannerFrame.origin.y = contentFrame.size.height
        }
        contentController!.view.frame = contentFrame
        bannerView!.frame = bannerFrame
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
