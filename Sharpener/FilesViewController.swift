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
    func selectedCell(cell: UICollectionViewCell) {
        
    }
}

extension FilesViewController: SPSharpenerFileHandlerDelegate {
    func newDocumentRefFetched(ref: SPSharpenerDocumentRef) {
        collectionViewController?.documentRefs.append(ref)
        collectionViewController?.collectionView?.insertItemsAtIndexPaths([NSIndexPath(forRow: collectionViewController!.documentRefs.count-1, inSection: 0)])
        let imageView = UIImageView(image: ref.thumbnail)
    }
}
