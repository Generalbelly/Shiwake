//
//  MailViewController.swift
//  MailApp
//
//  Created by ShimmenNobuyoshi on 2015/07/04.
//  Copyright (c) 2015年 Shimmen Nobuyoshi. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import WebKit

class MailViewController: UIViewController, DraggableViewDelegate, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {

    // for mail in trash
    var selectedMail: Mail?

    // for bookmark
    var selectedBookmark: Bookmark?

    var label: Label! { didSet { self.labelId = label.labelId } }
    var labelId: String?
    var hud: MBProgressHUD!
    var isHudAdded = false
    var pageUrl: String?
    var pageTitle: String?
    var cardsToLoad = 15
    var counter = 0
    var readerButton = UIBarButtonItem()
    var infoButton = UIBarButtonItem()
    var flagButton = UIBarButtonItem()
    var flagTapped = false
    var numberOfCards = 0 { didSet { counter = numberOfCards - 1 } }
    var cardsStack = [DraggableView]() {
        didSet {
            if selectedMail != nil || selectedBookmark != nil {
                if cardsStack.count > 0 {
                    let item = cardsStack.first!
                    item.tag = 0
                    item.selected = true
                    item.delegate = self
                    item.navigationDelegate = self
                    item.UIDelegate = self
                    item.scrollView.delegate = self
                    self.view.insertSubview(item, belowSubview: self.hud)
                    self.disableButton()
                    cardsStack.removeAll()
                }
            } else {
                if numberOfCards > 0 && cardsStack.count == numberOfCards {
                    let orderedStack = cardsStack.sort() { $1.historyId > $0.historyId }
                    for (index, item) in orderedStack.enumerate() {
                        item.tag = index
                        if index == numberOfCards - 1 {
                            item.topMail = true
                        }
                        item.delegate = self
                        item.navigationDelegate = self
                        item.UIDelegate = self
                        item.scrollView.delegate = self
                        self.view.insertSubview(item, belowSubview: self.hud)
                    }
                    self.disableButton()
                    cardsStack.removeAll()
                }
            }
        }
    }
    @IBOutlet weak var smile: UIImageView!
    @IBOutlet weak var nomoreMessage: UILabel!
    @IBOutlet weak var reloadButton: UIButton!
    @IBAction func reloadTapped(sender: AnyObject) {
        self.loadMails()
    }

    // view life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpButtons()
        if self.selectedMail != nil {
            self.setupHUD()
            self.navigationItem.title = ""
            self.createCard(self.selectedMail!, bookmark: nil)
        } else if self.selectedBookmark != nil {
            self.setupHUD()
            self.navigationItem.title = ""
            self.createCard(nil, bookmark: self.selectedBookmark)
        } else {
            if self.label.mails.isEmpty {
                self.loadMails()
            } else {
                self.setupHUD()
                self.numberOfCards = self.label.mails.count
                for item in self.label.mails {
                    self.createCard(item, bookmark: nil)
                }
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.counter == 0 {
            if self.reloadButton.hidden == false || self.smile.hidden == false {
                if self.selectedMail == nil && self.selectedBookmark == nil {
                    self.loadMails()
                }
            }
        }
    }

    func loadMails() {
        self.setupHUD()
        GmailClientHelper.sharedInstance.fetchMailList(self.label, label2: "INBOX",maxNumber: self.cardsToLoad) { success, results, error in
            if success && results != nil {
                if results?.count > 0 {
                    GmailClientHelper.sharedInstance.fetchMail(results!, labelToBelongTo: self.label) { success, error, cardsToMake in
                        if success {
                            if cardsToMake != nil {
                                self.numberOfCards = cardsToMake!.count
                                for item in cardsToMake! {
                                    self.createCard(item, bookmark: nil)
                                }
                            } else {
                                self.noUnreadMails()
                            }
                        } else {
                            self.showAlert("Error", message: error!.localizedDescription)
                        }
                    }
                } else {
                    self.showAlert("No message", message: "There is no message related to this label")
                }
            } else if error != nil {
                self.showAlert("Error", message: error!.localizedDescription)
            } else {
                self.noUnreadMails()
            }
        }
    }

    func noUnreadMails() {
        self.hud.hide(true)
        self.isHudAdded = false
        self.smile.hidden = false
        self.nomoreMessage.hidden = false
        self.readerButton.enabled = false
        self.infoButton.enabled = false
        self.flagButton.enabled = false
    }

    func setupHUD() {
        self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.hud.labelText = "Loading"
        self.isHudAdded = true
    }

    func disableButton() {
        self.reloadButton.hidden = false
        self.readerButton.enabled = false
        self.infoButton.enabled = false
        self.flagButton.enabled = false
    }

    func setUpButtons() {

        reloadButton.layer.masksToBounds = true
        reloadButton.layer.cornerRadius = 0.5 * reloadButton.bounds.size.width

        // info button
        let infoIcon = UIImage(named: "info")
        infoButton = UIBarButtonItem(image: infoIcon, style: .Plain, target: self, action: "tapped:")
        infoButton.tag = 0
        infoButton.enabled = false

        // reader button
        let readerIcon = UIImage(named: "reader")
        readerButton = UIBarButtonItem(image: readerIcon, style: .Plain, target: self, action: "tapped:")
        readerButton.tag = 1
        readerButton.enabled = false

        // flag button
        if self.selectedMail == nil && self.selectedBookmark == nil {
            let flagIcon = UIImage(named: "flag")
            flagButton = UIBarButtonItem(image: flagIcon, style: .Plain, target: self, action: "tapped:")
            flagButton.tag = 2
            flagButton.enabled = false
            self.navigationItem.leftBarButtonItem = flagButton
        }
        
        self.navigationItem.rightBarButtonItems = [readerButton, infoButton]
    }

    func tapped(button: UIButton) {
        let index = self.view.subviews.count - 1
        if let draggableView = self.view.subviews[index] as? DraggableView {
            switch button.tag {
            case 0:
            if draggableView.showInfo {
                draggableView.showInfo = false
            } else {
                draggableView.showInfo = true
            }
            case 1:
                if draggableView.enlarged {
                    draggableView.enlarged = false
                } else if draggableView.enlarged == false && draggableView.altMessageString != nil {
                    draggableView.enlarged = true
                } else {
                    self.showAlert("Error", message: "Sorry, there is no plain text available for this email")
                }
            case 2:
                self.flagTapped = true
                self.showAlert("Flagging", message: "If you flag this mail, mail from this address will become hidden in this app. The mails will remain and be accessable in your gmail account and app.")
            default:
            break
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination = segue.destinationViewController as UIViewController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        if let dvc = destination as? DetailViewController {
            if segue.identifier == "detail" {
                dvc.pageUrl = self.pageUrl!
            }
        }
    }

    // delegate methods

    func cardLoadingCheck(view: DraggableView, completed: Bool) {
        if view.tag == self.counter && completed == true {
            self.hud.hide(true)
            self.isHudAdded = false
            if self.selectedBookmark == nil {
                self.readerButton.enabled = true
                self.infoButton.enabled = true
                self.flagButton.enabled = true
            }
        }
    }

    func cardCounter(view: DraggableView, swiped: Bool) {
        counter -= 1
    }

    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        if webView.tag == self.counter && !self.isHudAdded {
            self.pageUrl = webView.URL?.absoluteString
            self.performSegueWithIdentifier("detail", sender: self)
            decisionHandler(WKNavigationResponsePolicy.Cancel)
        } else {
            decisionHandler(WKNavigationResponsePolicy.Allow)
        }
    }

    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if webView.tag == self.counter {
            self.pageUrl = navigationAction.request.URL?.absoluteString
            self.performSegueWithIdentifier("detail", sender: self)
        }
        return nil
    }

    func createCard(mail: Mail?, bookmark: Bookmark?) {
        let navBarHeightAndStatusBarHeight =  self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height
        let cardFrame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + navBarHeightAndStatusBarHeight, self.view.bounds.size.width, self.view.bounds.size.height - navBarHeightAndStatusBarHeight)
        let jScript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let wkUScript = WKUserScript(source: jScript, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
        let wkUcontentController = WKUserContentController()
        wkUcontentController.addUserScript(wkUScript)
        let config = WKWebViewConfiguration()
        let cardView: DraggableView
        config.userContentController = wkUcontentController
        if bookmark == nil {
            let dict = [
                "from": mail!.from,
                "subject": mail!.subject,
                "to": mail!.to
            ]
            cardView = DraggableView(frame: cardFrame, configuration: config, dict: dict)
            cardView.messageId = mail!.id
            cardView.labelId = self.labelId
            cardView.center.x = view.center.x
            cardView.htmlString = mail!.message
            switch mail!.mimeType {
            case "text/plain":
                cardView.textString = mail!.message
            case "multipart/alternative":
                cardView.htmlString = mail!.message
                if mail!.altMessage != nil {
                    cardView.altMessageString = mail!.altMessage
                    if cardView.htmlString == "" {
                        cardView.enlarged = true
                    }
                }
            case "multipart/mixed":
                cardView.htmlString = mail!.message
                if mail!.altMessage != nil {
                    cardView.altMessageString = mail!.altMessage
                    if cardView.htmlString == "" {
                        cardView.enlarged = true
                    }
                }
            case "text/html":
                cardView.htmlString = mail!.message
                if mail!.altMessage != nil {
                    cardView.altMessageString = mail!.altMessage
                    if cardView.htmlString == "" {
                        cardView.enlarged = true
                    }
                }
            default:
                break
            }
            cardView.historyId = mail!.historyId as Int
        } else {
            cardView = DraggableView(frame: cardFrame, configuration: config, dict: nil)
            if self.selectedBookmark!.webpage {
                cardView.bookmarkedUrlString = self.selectedBookmark?.content
            } else {
                cardView.bookmarkedHtmlString = self.selectedBookmark?.content
            }
        }
        self.cardsStack.append(cardView)
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { (action) in
            if self.flagTapped {
                var sender = ""
                let index = self.view.subviews.count - 1
                if let draggableView = self.view.subviews[index] as? DraggableView {
                    sender = draggableView.dict["from"] as String!
                }
                if NSFileManager.defaultManager().fileExistsAtPath(GmailClientHelper.sharedInstance.filePath) {
                    if let dict = NSKeyedUnarchiver.unarchiveObjectWithFile(GmailClientHelper.sharedInstance.filePath) as? [String: [String]] {
                        var flaggedSenders = dict["flaggedSenders"]
                        flaggedSenders!.append(sender)
                        let updatedDict = ["flaggedSenders": flaggedSenders!]
                        NSKeyedArchiver.archiveRootObject(updatedDict, toFile: GmailClientHelper.sharedInstance.filePath)
                    }
                } else {
                    let dict = ["flaggedSenders": [sender]]
                    NSKeyedArchiver.archiveRootObject(dict, toFile: GmailClientHelper.sharedInstance.filePath)
                }
            }
            self.flagTapped = false
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        if self.flagTapped {
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
            }
            alertController.addAction(cancel)
        }
        alertController.addAction(ok)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}