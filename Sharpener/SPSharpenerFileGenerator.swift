//
//  SPSharpenerFileHandler.swift
//  Sharpener
//
//  Created by Inti Guo on 1/28/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol SPSharpenerFileHandlerDelegate: class {
    func newDocumentRefFetched(ref: SPSharpenerDocumentRef)
}

class SPSharpenerFileHandler {
    
    weak var delegate: SPSharpenerFileHandlerDelegate?
    
    var documentRefs = [SPSharpenerDocumentRef]()
    
    lazy var localRoot: NSURL = {
       let paths = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        return paths.first!
    }()
    
    func newFileURL() -> NSURL {
        return localRoot.URLByAppendingPathComponent("\(NSUUID().UUIDString).\(SPSharpenerDocument.fileExtension)")
    }
    
    func saveGeometricStore(store: SPGeometricsStore, withCompletionHandler complete: (Bool) -> Void) {
        let newURL = newFileURL()
        let snapshotView = UIView(frame: CGRect(origin: CGPointZero, size: Preference.vectorizeSize))
        store.shapeLayers.forEach {
            snapshotView.layer.addSublayer($0)
        }
        let thumbnail = snapshotView.snapshotInRect(
            CGRect(origin: CGPoint(x: 0, y: (Preference.vectorizeSize.height-Preference.vectorizeSize.width)/2),
                size: CGSize(width: Preference.vectorizeSize.width, height: Preference.vectorizeSize.width))).resizedImageToSize(CGSize(width: 200, height: 200))
        let file = SPSharpenerDocument(store: store, thumbnail: thumbnail, url: newURL)
        file.saveToURL(newURL, forSaveOperation: .ForCreating) { succeed in
            file.closeWithCompletionHandler(complete)
        }
    }
    
    func fetchAllLocalDocumentRef() {
        documentRefs.removeAll()
        var localDocuments: [NSURL]
        do {
            localDocuments = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(localRoot, includingPropertiesForKeys: nil, options: [])
        } catch {
            return
        }
        let matchingDocuments = localDocuments.filter { url in
            return url.pathExtension == SPSharpenerDocument.fileExtension
        }
        
        for doc in matchingDocuments {
            fetchDocumentRefAtURL(doc)
        }
    }
    
    func fetchDocumentRefAtURL(url: NSURL) {
        let document = SPSharpenerDocument(fileURL: url)
        document.openWithCompletionHandler { success in
            guard success else { return }
            let thumbnail = document.thumbnail
            let metaData = document.metaDataJson
            
            document.closeWithCompletionHandler { success in
                guard success && thumbnail != nil else { return }
                dispatch_async(GCD.mainQueue) {
                    self.appendDocumentRefWithURL(url, thumbnail: thumbnail!)
                }
            }
        }
    }
    
    func appendDocumentRefWithURL(url: NSURL, thumbnail: UIImage) {
        let ref = SPSharpenerDocumentRef(url: url, thumbnail: thumbnail)
        documentRefs.append(ref)
        delegate?.newDocumentRefFetched(ref)
    }
}