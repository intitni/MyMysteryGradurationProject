//
//  FilePreviewCollectionViewCell.swift
//  Sharpener
//
//  Created by Inti Guo on 2/22/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class FilePreviewCollectionViewCell: UICollectionViewCell {
    
    var imageView: UIImageView! {
        didSet {
            addSubview(imageView)
            imageView.snp_makeConstraints { make in
                make.edges.equalTo(self)
            }
            imageView.exclusiveTouch = false
            imageView.userInteractionEnabled = false
        }
    }
    
    var ref: SPSharpenerDocumentRef? {
        didSet {
            guard ref != nil else { return }
            imageView.image = ref!.thumbnail
            imageView.contentMode = .ScaleAspectFit
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        imageView = UIImageView()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        UIView.animateWithDuration(0.01, animations: {
            self.imageView.transform = CGAffineTransformMakeScale(0.9, 0.9)
            }, completion: nil)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        UIView.animateWithDuration(0.1, animations: {
            self.imageView.transform = CGAffineTransformIdentity
            }, completion: nil)
        super.touchesEnded(touches, withEvent: event)
    }
}
