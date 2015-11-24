//
//  PingsProducts.swift
//  Pings
//
//  Created by nevercry on 11/24/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import Foundation

// Use enum as a simple namespace.  (It has no cases so you can't instantiate it.)

public enum PingsProducts {
    
    /// TODO:  Change this to whatever you set on iTunes connect
    private static let Prefix = "com.nevercry.Pings."

    
    /// MARK: - Supported Product Identifiers
    public static let RemoveAd = Prefix + "RemoveAd"
    
    private static let productIdentifiers: Set<ProductIdentifier> = [PingsProducts.RemoveAd]
    
    /// Static instance of IAPHelper that for Pings products.
    public static let store = IAPHelper(productIdentifiers: PingsProducts.productIdentifiers)
}

/// Return the resourcename for the product identifier.
func resourceNameForProductIdentifier(productIdentifier: String) -> String? {
    return productIdentifier.componentsSeparatedByString(".").last
}