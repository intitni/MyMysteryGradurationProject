//
//  FilesViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 2/22/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class FilesViewController: UIViewController {
    
    var collectionViewController: FilePreviewCollectionViewController?
    var shouldShowRef: SPSharpenerDocumentRef?
    
    @IBOutlet weak var navigationBar: SPNavigationBar! {
        didSet {
            navigationBar.buttonDelegate = self
        }
    }
    @IBOutlet weak var newButton: SPNewButton! {
        didSet {
            newButton.addTarget(self, action: "shouldShowCaptureView", forControlEvents: .TouchUpInside)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let fileHandler = SPSharpenerFileHandler()
        fileHandler.delegate = self
        fileHandler.fetchAllLocalDocumentRef()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "FileEmbedCollection":
            if let toVC = segue.destinationViewController as? FilePreviewCollectionViewController {
                toVC.containerViewController = self
                collectionViewController = toVC
            }
        case "FileToDetail":
            if let toVC = segue.destinationViewController as? DetailViewController {
                toVC.docRef = shouldShowRef
            }
        default: break
        }
    }
    
    @IBAction func unwindToFile(sender: UIStoryboardSegue) {}
    @IBAction func unwindWithNewFileAdded(sender: UIStoryboardSegue) {}

    func shouldShowCaptureView() {
        performSegueWithIdentifier("FileToCapture", sender: self)
    }
}

extension FilesViewController: FilePreviewCollectionViewControllerDelegate {
    func selectedRef(ref: SPSharpenerDocumentRef) {
        shouldShowRef = ref
        performSegueWithIdentifier("FileToDetail", sender: self)
    }
}

extension FilesViewController: SPSharpenerFileHandlerDelegate {
    func newDocumentRefFetched(ref: SPSharpenerDocumentRef) {
        collectionViewController?.documentRefs.append(ref)
        collectionViewController?.collectionView?.insertItemsAtIndexPaths([NSIndexPath(forRow: collectionViewController!.documentRefs.count-1, inSection: 0)])
    }
}

extension FilesViewController: SPNavigationBarDelegate {
    func navigationBarButtonTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

