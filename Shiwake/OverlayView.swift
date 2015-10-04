//
//  OverlayView.swift
//  Shiwake
//
//  Created by ShimmenNobuyoshi on 2015/07/05.
//  Copyright (c) 2015年 Shimmen Nobuyoshi. All rights reserved.
//

import UIKit

enum OverlayMode {
    case Right
    case Left
}

class OverlayView: UIView {

    var mode: OverlayMode? { didSet { self.setImage(self.mode!) } }
    var imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        self.backgroundColor = UIColor.whiteColor()
        self.imageView.frame = CGRectMake(0, 0, 100, 100)
        self.addSubview(self.imageView)
    }

    func setImage(mode: OverlayMode) {
        if mode == OverlayMode.Left {
            self.imageView.image = UIImage(named: "trash")
            self.imageView.sizeThatFits(self.imageView.frame.size)
            self.imageView.center = self.center
        } else {
            self.imageView.image = UIImage(named: "bookmark")
            self.imageView.sizeThatFits(self.imageView.frame.size)
            self.imageView.center = self.center
        }
    }

}
