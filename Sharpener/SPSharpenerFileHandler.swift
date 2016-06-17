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
    
    func newSVGURL() -> NSURL {
        return localRoot.URLByAppendingPathComponent("share.svg")
    }
    
    func saveGeometricStore(store: SPGeometricsStore, withCompletionHandler complete: (SPSharpenerDocumentRef) -> Void) {
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
            file.closeWithCompletionHandler { finished in
                complete(SPSharpenerDocumentRef(url: newURL, thumbnail: thumbnail, modifiedDate: nil))
            }
        }
    }
    
    func saveSVGString(svg: String, withCompletionHandler complete: (NSURL)->()) {
        let newURL = newSVGURL()
        let fileManager = NSFileManager()
     
        if fileManager.fileExistsAtPath(newURL.path!) {
            do {
                try fileManager.removeItemAtURL(newURL)
                    
            } catch {
                print("unable to remove file")
            }
        }
        do {
            try svg.writeToURL(newURL, atomically: false, encoding: NSUTF8StringEncoding)
            complete(newURL)
        } catch {
            print("failed to write file")
        }
    }
    
    func deleteFileAtURL(url: NSURL) {
        
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
            let modifiedDate = document.fileModificationDate
            
            document.closeWithCompletionHandler { success in
                guard success && thumbnail != nil else { return }
                dispatch_async(GCD.mainQueue) {
                    self.appendDocumentRefWithURL(url, thumbnail: thumbnail!, modifiedDate: modifiedDate)
                }
            }
        }
    }
    
    func fetchDocumentForRef(ref: SPSharpenerDocumentRef, withCompletionHandler complete: (SPSharpenerDocument)->Void) {
        let document = SPSharpenerDocument(fileURL: ref.url)
        document.openWithCompletionHandler { success in
            guard success else { return }
            complete(document)
        }
    }
    
    func appendDocumentRefWithURL(url: NSURL, thumbnail: UIImage, modifiedDate: NSDate?) {
        let ref = SPSharpenerDocumentRef(url: url, thumbnail: thumbnail, modifiedDate: modifiedDate)
        documentRefs.append(ref)
        delegate?.newDocumentRefFetched(ref)
    }
}