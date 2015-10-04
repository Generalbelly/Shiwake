//
//  OnboardViewController.swift
//  Shiwake
//
//  Created by ShimmenNobuyoshi on 2015/10/03.
//  Copyright © 2015年 Shimmen Nobuyoshi. All rights reserved.
//

import Foundation
import UIKit

protocol OnboardViewControllerDelegate{
    func walkthroughCloseButtonPressed(didPress: Bool)
}

class OnboardViewController: UIViewController, UIScrollViewDelegate {
	let backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.3)
    let slides = [
		[ "image": "FirstViewSlide", "text": "Shiwake connects with your Gmail account and allows you to sort through your emails quickly and effectively."],
		[ "image": "SwipeToBSlide", "text": "Swipe right and your email is saved and will move to the Bookmarks menu."],
        [ "image": "ShiwakeSlide", "text": "Bookmarked emails are also viewable in the 'Shiwake' folder in your Gmail, created automatically when you connect your account."],
		[ "image": "SwipeToTSlide", "text": "Swipe left and your email is deleted and will move to the Trash menu and to the trash folder in your Gmail."],
        [ "image": "PlainTextSlide", "text": "Read an email in plain text by tapping the lines icon."],
        [ "image": "InfoSlide", "text": "See the sender and subject of an email by tapping the information icon."],
        [ "image": "FlagSlide", "text": "Tap the flag icon to hide all future emails from that sender in Shiwake. They will still be viewable in Gmail."],
        [ "image": "WebSlide", "text": "Tap a link in an email and the webpage will open within the app. Webpages are also bookmarkable and will be saved to your Bookmarks menu and Shiwake folder in Gmail."],
	]
	let screen: CGRect = UIScreen.mainScreen().bounds
	var scroll: UIScrollView?
	var dots: UIPageControl?
    var button: UIButton?
    var delegate:  OnboardViewControllerDelegate?
    var pageNumber: CGFloat? { didSet {
        if Int(pageNumber!) == slides.count - 1 {
            self.button!.setTitle("Close", forState: .Normal)
            self.button!.sizeToFit()
        }
    } }

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = backgroundColor
		scroll = UIScrollView(frame: CGRect(x: 0.0, y: 0.0, width: screen.width, height: screen.height * 0.9))
		scroll?.showsHorizontalScrollIndicator = false
		scroll?.showsVerticalScrollIndicator = false
		scroll?.pagingEnabled = true
		view.addSubview(scroll!)
		if (slides.count > 1) {
			dots = UIPageControl(frame: CGRect(x: 0.0, y: screen.height * 0.9, width: screen.width, height: screen.height * 0.05))
			dots?.numberOfPages = slides.count
			view.addSubview(dots!)
            button = UIButton()
            button!.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button!)
            button!.addTarget(self, action: "tapped:", forControlEvents: .TouchUpInside)
            button!.setTitle("Skip", forState: .Normal)
            let buttonRightConstraint = NSLayoutConstraint(item:button!, attribute: .Right, relatedBy:NSLayoutRelation.Equal, toItem:self.view, attribute: .Right, multiplier:1.0, constant: -20)
            let buttonTopConstraint = NSLayoutConstraint(item: button!, attribute: .Top, relatedBy: .Equal, toItem: self.topLayoutGuide, attribute: .Top, multiplier: 1, constant: 20)
            button!.sizeToFit()
            view.addConstraints([buttonRightConstraint, buttonTopConstraint])
		}
		for var i = 0; i < slides.count; ++i {
			if let image = UIImage(named: slides[i]["image"]!) {
				let imageView: UIImageView = UIImageView(frame: getFrame(image.size.width, iH: image.size.height, slide: i, offset: screen.height * 0.15))
				imageView.image = image
				scroll?.addSubview(imageView)
			}
			if let text = slides[i]["text"] {
				let textView = UITextView(frame: CGRect(x: screen.width * 0.1 + CGFloat(i) * screen.width, y: screen.height * 0.70, width: screen.width * 0.8, height: 120))
                textView.scrollEnabled = false
				textView.text = text
				textView.editable = false
				textView.selectable = false
				textView.textAlignment = NSTextAlignment.Center
                textView.font = UIFont.boldSystemFontOfSize(17)
				textView.textColor = UIColor.whiteColor()
				textView.backgroundColor = UIColor.clearColor()
				scroll?.addSubview(textView)
			}
		}
		scroll?.contentSize = CGSizeMake(CGFloat(Int(screen.width) *  slides.count), screen.height * 0.5)
		scroll?.delegate = self
		dots?.addTarget(self, action: Selector("swipe:"), forControlEvents: UIControlEvents.ValueChanged)
	}

    func tapped(sender: AnyObject){
        self.delegate?.walkthroughCloseButtonPressed(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }

	func getFrame (iW: CGFloat, iH: CGFloat, slide: Int, offset: CGFloat) -> CGRect {
		let mH: CGFloat = screen.height * 0.50
		let mW: CGFloat = screen.width
		var h: CGFloat
		var w: CGFloat
		let r = iW / iH
		if (r <= 1) {
			h = min(mH, iH)
			w = h * r
		} else {
			w = min(mW, iW)
			h = w / r
		}
		return CGRectMake(
			max(0, (mW - w) / 2) + CGFloat(slide) * screen.width,
			max(0, (mH - h) / 2) + offset,
			w,
			h
		)
	}
    
	func swipe(sender: AnyObject) -> () {
		if let scrollView = scroll {
			let x = CGFloat(dots!.currentPage) * scrollView.frame.size.width
			scroll?.setContentOffset(CGPointMake(x, 0), animated: true)
		}
	}
	func scrollViewDidEndDecelerating(scrollView: UIScrollView) -> () {
		pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
		dots!.currentPage = Int(pageNumber!)
	}
	override func prefersStatusBarHidden() -> Bool {
		return true
	}
}