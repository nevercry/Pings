//
//  FileListTableViewController+UIViewControllerPreviewing.swift
//  Pings
//
//  Created by nevercry on 11/18/15.
//  Copyright © 2015 nevercry. All rights reserved.
//

import UIKit

extension FileListTableViewController: UIViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed
        guard let indexPath = tableView.indexPathForRowAtPoint(location), cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        // Create a detail View controller and set its properties.
        guard let detailViewController = storyboard?.instantiateViewControllerWithIdentifier("PingsTableViewController") as? PingsTableViewController else { return nil }
        
        detailViewController.fileName = cell.textLabel!.text
        
        /* 
           Set the height of the preview by setting the preferred content size of the detail View Controller.
           Width should be zero, because it's not used in portrait.
        */
        detailViewController.preferredContentSize = CGSize(width: 0.0, height: 0.0) // 0.0 means to get the default height
        
        previewingContext.sourceRect = cell.frame
        
        return detailViewController
    }
    
    /// Present the view controller for the "Pop" action
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        showViewController(viewControllerToCommit, sender: self)
    }
}
