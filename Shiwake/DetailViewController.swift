//
//  DetailViewController.swift
//  Shiwake
//
//  Created by ShimmenNobuyoshi on 2015/08/10.
//  Copyright (c) 2015年 Shimmen Nobuyoshi. All rights reserved.
//

import UIKit
import CoreData
import WebKit

class DetailViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {

    var webView: WKWebView!
    var pageUrl: String?
    var showUp = false
    var progressView: UIProgressView!
    var refresh: UIBarButtonItem!
    var actionButton:UIBarButtonItem!
    var bookmarkButton: UIBarButtonItem!
    var backButton: UIBarButtonItem!
    var forwardButton: UIBarButtonItem!
    var safariButton: UIBarButtonItem!
    var alreadyBookmarked = false
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
        progressView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, 2)
        progressView.center.x = self.view.center.x
        progressView.trackTintColor = UIColor.hex("#06d0e5", alpha: 1.0)
        progressView.progressTintColor = UIColor.whiteColor()
        setUpButtons()
        let config = WKWebViewConfiguration()
        let jScript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let wkUScript = WKUserScript(source: jScript, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
        let wkUcontentController = WKUserContentController()
        wkUcontentController.addUserScript(wkUScript)
        config.userContentController = wkUcontentController
        self.webView = WKWebView(frame: self.view.frame, configuration: config)
        let url = NSURL(string: pageUrl!)
        self.webView.loadRequest(NSURLRequest(URL: url!))
        webView.center = self.view.center
        webView.navigationDelegate = self
        webView.UIDelegate = self
        webView.scrollView.delegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        webView.addObserver(self, forKeyPath: "canGoBack", options: .New, context: nil)
        webView.addObserver(self, forKeyPath: "canGoForward", options: .New, context: nil)
        webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        self.view.addSubview(webView)
        self.view.addSubview(progressView)
    }

    func getRidOfStuff() {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "canGoBack")
        webView.removeObserver(self, forKeyPath: "canGoForward")
        webView.removeObserver(self, forKeyPath: "loading")
        webView.navigationDelegate = nil
        webView.scrollView.delegate = nil
    }

    func setUpButtons() {
    
        let spacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)

        let backIcon = UIImage(named: "back")
        backButton = UIBarButtonItem(image: backIcon, style: .Plain, target: self, action: "backTapped:")
        backButton.enabled = false

        let forwardIcon = UIImage(named: "forward")
        forwardButton = UIBarButtonItem(image: forwardIcon, style: .Plain, target: self, action: "forwardTapped:")
        forwardButton.enabled = false

        refresh = UIBarButtonItem(barButtonSystemItem: .Refresh, target: webView, action: "reload")
        refresh.enabled = false

        let safariIcon = UIImage(named: "safari")
        safariButton = UIBarButtonItem(image: safariIcon, style: .Plain, target: self, action: "safariTapped:")

        let bookmarkIcon = UIImage(named: "bookmarkButton")
        bookmarkButton = UIBarButtonItem(image: bookmarkIcon, style: .Plain, target: self, action: "bookmarked:")
        bookmarkButton.enabled = false

        actionButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "action:")

        toolbarItems = [backButton, spacer, forwardButton, spacer, bookmarkButton, spacer, safariButton, spacer, actionButton]
        self.navigationController?.toolbar.tintColor = UIColor.hex("64b6ac", alpha: 1.0)
        self.navigationController?.toolbar.backgroundColor = UIColor.whiteColor()
        self.navigationController?.toolbar.translucent = false
        navigationController?.toolbarHidden = false

        let closeIcon = UIImage(named: "xbutton")
        let closeButton = UIBarButtonItem(image: closeIcon, style: .Plain, target: self, action: "closeTapped:")
        self.navigationItem.leftBarButtonItem = closeButton
        self.navigationItem.rightBarButtonItem = refresh
        self.navigationController?.navigationBar.barTintColor = UIColor.hex("06d0e5", alpha: 1.0)
        self.navigationController?.navigationBar.translucent = false
    }

    func action(sender: AnyObject) {
        let string: String = self.title!
        let URL: NSURL = NSURL(string: self.pageUrl!)!
        let activityViewController = UIActivityViewController(activityItems: [string, URL], applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }

    func safariTapped(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: self.pageUrl!)!)
    }
    
    func closeTapped(sender: AnyObject) {
        self.getRidOfStuff()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func backTapped(sender: AnyObject) {
        self.webView.goBack()
    }

    func forwardTapped(sender: AnyObject) {
        self.webView.goForward()
    }

    func bookmarked(sender: AnyObject) {
        let newMessage = GTLGmailMessage()
        let urlTosend = self.pageUrl!.componentsSeparatedByString("?")
        let str = "Content-Type:text/html\nFrom:Shiwake\nSubject:\(self.title!)\n\n\(urlTosend.first!)"
        let utf8str = str.dataUsingEncoding(NSUTF8StringEncoding)
        let base64Encoded = utf8str!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        newMessage.raw = base64Encoded
        let insertQuery = GTLQueryGmail.queryForUsersMessagesInsertWithUploadParameters(nil) as! GTLQueryGmail
        insertQuery.message = newMessage
        GmailClientHelper.sharedInstance.service.executeQuery(insertQuery) { ticket, response, error in
            if error != nil {
                dispatch_async(dispatch_get_main_queue()){
                    self.showAlert("Error", message: error!.localizedDescription)
                }
            } else {
                if let res = response as? GTLGmailMessage {
                    let id = res.identifier
                    let modifyQuery = GTLQueryGmail.queryForUsersMessagesModify()
                     as! GTLQueryGmail
                    modifyQuery.identifier = id
                    modifyQuery.addLabelIds = [GmailClientHelper.sharedInstance.ShiwakeId]
                    GmailClientHelper.sharedInstance.service.executeQuery(modifyQuery) { ticket, response, error in
                        if error != nil {
                            dispatch_async(dispatch_get_main_queue()){
                                self.showAlert("Error", message: "Sorry, something went wrong. If you report this to me, I would really appreciate it\nMy email is nobuyoshi.shimmen@gmail.com\nThanks!")
                            }
                        } else {
                            self.bookmarkMessage("Bookmarked")
                        }
                    }
                }
            }
        }
        let time = NSDate()
        let uid = NSUUID().UUIDString
        if self.pageUrl != nil {
            let dict: [String: AnyObject] = ["title": self.title!, "date": time, "content": self.pageUrl!, "id": uid, "webpage": true]
            _ = Bookmark(dict: dict, context: self.sharedContext)
        }
        CoreDataStackManager.sharedInstance.saveContext()
    }

    func queryForBookmark(id: String) -> [Bookmark]{
        var error: NSError?
        let fetchRequest = NSFetchRequest(entityName: "Bookmark")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        let results: [AnyObject]?
        do {
            results = try self.sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            results = nil
        }
        if error != nil {
            // print("Error", terminator: "")
        }
        return results as! [Bookmark]
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        title = webView.title
        pageUrl = webView.URL?.absoluteString
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch keyPath! {
        case "estimatedProgress":
            if self.progressView.hidden {
                self.progressView.hidden = false
            }
            self.progressView.setProgress(Float(self.webView.estimatedProgress), animated: true)
        case "loading":
            self.showUp = !self.webView.loading
            self.refresh.enabled = !self.webView.loading
            self.bookmarkButton.enabled = !self.webView.loading
            self.progressView.hidden = !self.webView.loading
        case "canGoBack":
            self.backButton.enabled = self.webView.canGoBack
        case "canGoForward":
            self.forwardButton.enabled = self.webView.canGoForward
        default:
        break
        }
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if showUp {
            let translation = scrollView.panGestureRecognizer.translationInView(scrollView)
            if(translation.y > 0) {
                if self.navigationController?.toolbarHidden == true {
                    self.navigationController?.toolbarHidden = false
                }
            } else {
                if self.navigationController?.toolbarHidden == false {
                    self.navigationController?.toolbarHidden = true
                }
            }
        }
    }

    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        webView.loadRequest(navigationAction.request)
        return nil
    }
    
    func bookmarkMessage(title: String) {
        let alertController = UIAlertController(title: title, message:nil, preferredStyle: .Alert)
        self.presentViewController(alertController, animated: true, completion: {
            dispatch_async(dispatch_get_main_queue()){
            UIView.animateWithDuration(4, animations: { alertController.dismissViewControllerAnimated(true, completion: nil) })
            }
        })
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default) { (action) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(action)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
