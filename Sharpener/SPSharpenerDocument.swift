//
//  SPSharpenerDocument.swift
//  Sharpener
//
//  Created by Inti Guo on 2/22/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit
import SwiftyJSON

struct DateFormatter {
    static let documentMetaDateFormatter = NSDateFormatter()
}

extension NSDate {
    func stringWithBasicFormat() -> String {
        DateFormatter.documentMetaDateFormatter.timeStyle = .ShortStyle
        DateFormatter.documentMetaDateFormatter.dateStyle = .ShortStyle
        return DateFormatter.documentMetaDateFormatter.stringFromDate(self)
    }
}

class SPSharpenerDocumentRef {
    var url: NSURL
    var thumbnail: UIImage
    
    init(url: NSURL, thumbnail: UIImage) {
        self.url = url
        self.thumbnail = thumbnail
    }
}

class SPSharpenerDocument: UIDocument {
    
    var store: SPGeometricsStore? {
        didSet {
            dataJson = store?.json
            var json = [String: JSON]()
            json["created_time"] = JSON(NSDate().stringWithBasicFormat())
            json["created_version"] = JSON(Preference.versionString()!)
            json["frame_size"] = JSON(["width": Preference.vectorizeSize.width, "height": Preference.vectorizeSize.height])
            metaDataJson = JSON(json)
        }
    }
    lazy var dataJson: JSON? = {
        if self.store == nil {
            guard let data = self.dataFromWrapperWithPreferredFileName(self.dataFileName) else { return nil }
            return JSON(data: data)
        } else {
            return self.store!.json
        }
    }()
    lazy var metaDataJson: JSON? = {
            guard let data = self.dataFromWrapperWithPreferredFileName(self.metaFileName) else { return nil }
            return JSON(data: data)
    }()
    var fileWrapper: NSFileWrapper?
    lazy var thumbnail: UIImage? = {
            guard let data = self.dataFromWrapperWithPreferredFileName(self.thumbnailFileName) else { return self.thumbnail }
            return UIImage(data: data)
    }()
    
    var dataRaw: NSData? {
        do {
            let r = try dataJson?.rawData()
            return r
        } catch {
            return nil
        }
    }
    var metaDataRaw: NSData? {
        do {
            let r = try metaDataJson?.rawData()
            return r
        } catch {
            return nil
        }
    }
    
    static let fileExtension: String = "sharpener"
    let dataFileName: String = "sharpener.data"
    let metaFileName: String = "sharpener.metadata"
    let thumbnailFileName: String = "sharpener.thumbnail"
    
    init(store: SPGeometricsStore, thumbnail: UIImage, url: NSURL) {
        super.init(fileURL: url)
        self.store = store
        self.thumbnail = thumbnail
    }
    
    override init(fileURL url: NSURL) {
        super.init(fileURL: url)
    }
    
    override func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
        fileWrapper = contents as? NSFileWrapper
    }
    
    override func contentsForType(typeName: String) throws -> AnyObject {
        if fileWrapper == nil {
            fileWrapper = NSFileWrapper(directoryWithFileWrappers: [String: NSFileWrapper]())
        }
        
        if let data = dataRaw {
            let dataWrapper = NSFileWrapper(regularFileWithContents: data)
            dataWrapper.preferredFilename = dataFileName
            fileWrapper?.addFileWrapper(dataWrapper)
        }
        
        if let metaData = metaDataRaw {
            let metaDataWrapper = NSFileWrapper(regularFileWithContents:metaData)
            metaDataWrapper.preferredFilename = metaFileName
            fileWrapper?.addFileWrapper(metaDataWrapper)
        }
        
        if let thumb = thumbnail {
            autoreleasepool {
                if let thumbnailData = UIImagePNGRepresentation(thumb) {
                    let imageFileWrapper = NSFileWrapper(regularFileWithContents: thumbnailData)
                    imageFileWrapper.preferredFilename = thumbnailFileName
                    fileWrapper?.addFileWrapper(imageFileWrapper)
                }
            }
        }
        
        return fileWrapper!
    }
    
    func dataFromWrapperWithPreferredFileName(name: String) -> NSData? {
        guard let wrapper = fileWrapper?.fileWrappers?[name] else { return nil }
        return wrapper.regularFileContents
    }
}