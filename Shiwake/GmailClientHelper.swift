//
//  GmailConstants.swift
//  Shiwake
//
//  Created by ShimmenNobuyoshi on 2015/07/20.
//  Copyright (c) 2015年 Shimmen Nobuyoshi. All rights reserved.
//

import Foundation
import CoreData

class GmailClientHelper {

    static let sharedInstance = GmailClientHelper()
    let service = GTLServiceGmail()
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }()
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        return url.URLByAppendingPathComponent("archive").path!
    }
    
    struct Keys {
        static let kKeychainItemName = "Gmail API"
        static let kClientID = "535786933516-s2iitvtsmrm3o925cs0t9p6okj0n9np2.apps.googleusercontent.com"
        static let kClientSecret = "Xanr--tE4syyjDydG7Jx5t_J"
    }

    var ShiwakeId = ""

    func fetchMailList(label: Label, label2: String?, maxNumber: Int, completionHandler: (success: Bool, results: [GTLGmailMessage]?, error: NSError? ) -> Void ) {
        let query = GTLQueryGmail.queryForUsersMessagesList() as! GTLQueryGmail
        query.maxResults = UInt(maxNumber)
        if label2 != nil {
            query.labelIds = [label.labelId, label2!]
        } else {
            query.labelIds = [label.labelId]
        }
        GmailClientHelper.sharedInstance.service.executeQuery(query) { ticket, response, error in
            if error == nil {
                if let MessagesListResponse = response as? GTLGmailListMessagesResponse {
                    let messagesData = MessagesListResponse.messages as? [GTLGmailMessage]
                completionHandler(success: true, results: messagesData, error: nil)
                }
            } else {
                completionHandler(success: false, results: nil, error : error)
            }
        }
    }

    func fetchMail(list: [GTLGmailMessage], labelToBelongTo: Label, completionHandler: (success: Bool, error: NSError?, cardsToMake: [Mail]?) -> Void ) {
        let numberOfCardsToMake = list.count
        var counter = 0
        var cardsToMake = [Mail]() {
            didSet {
                if cardsToMake.count == numberOfCardsToMake - counter {
                    completionHandler(success: true, error: nil, cardsToMake: cardsToMake)
                    CoreDataStackManager.sharedInstance.saveContext()
                }
            }
        }
        for item in list {
            let query = GTLQueryGmail.queryForUsersMessagesGet() as! GTLQueryGmail
            query.identifier = item.identifier
            GmailClientHelper.sharedInstance.service.executeQuery(query) { ticket, response, error in
                if error == nil {
                    if let messagesResponse = response as? GTLGmailMessage {
                        let mail = self.createMail(messagesResponse, labelToBelongTo: labelToBelongTo)
                        if mail == nil {
                            counter += 1
                            if numberOfCardsToMake == counter {
                                completionHandler(success: true, error: nil, cardsToMake: nil)
                            }
                        } else {
                            cardsToMake.append(mail!)
                        }
                    }
                } else {
                    completionHandler(success: false, error: error, cardsToMake: nil)
                }
            }
        }
    }

    func createMail(messagesResponse: GTLGmailMessage, labelToBelongTo: Label) -> Mail? {
        let id = messagesResponse.identifier
        let historyId = messagesResponse.historyId
        let snippet = messagesResponse.snippet
        let threadId = messagesResponse.threadId
        var to = ""
        var from = ""
        var subject = ""
        for item in messagesResponse.payload.headers as NSArray {
            let name = item.valueForKey("name") as! String
            if name == "To" {
                to = item.valueForKey("value") as! String
            } else if name == "From" {
                from = item.valueForKey("value") as! String
            } else if name == "Subject" {
                subject = item.valueForKey("value") as! String
            }
        }
        if let dict = NSKeyedUnarchiver.unarchiveObjectWithFile(GmailClientHelper.sharedInstance.filePath) as? [String: [String]] {
            let flaggedSenders = dict["flaggedSenders"]!
            for sender in flaggedSenders {
                if from == sender {
                    return nil
                }
            }
        }
        let mimeType = messagesResponse.payload.mimeType
        var message = ""
        var altMessage: String? = nil
        if messagesResponse.payload.parts != nil {
            let parts = messagesResponse.payload.parts as NSArray
            let body = parts.lastObject?.body
            let data = body!.data
            if data != nil { message = self.readBodydata(data) }
            let altBody = parts.firstObject?.body
            let altData = altBody!.data
            if altData != nil { altMessage = self.readBodydata(altData) }
        } else if messagesResponse.payload.body.data != nil {
            message = self.readBodydata(messagesResponse.payload.body.data)
        } else {
            print("Error", terminator: "")
        }
        let mailToQuery = self.queryForMail(id)
        if mailToQuery.count > 0 {
            let mail = mailToQuery.first as Mail!
            if mail.label != labelToBelongTo {
                mail.label = labelToBelongTo
            }
            return mailToQuery.first!
        } else {
            let dict: [String: AnyObject] = ["id": id, "historyId": historyId, "snippet": snippet, "threadId": threadId, "to": to, "from": from, "subject": subject, "mimeType": mimeType, "message": message]
            let mail = Mail(dict: dict, context: GmailClientHelper.sharedInstance.sharedContext)
            if altMessage != nil {
                mail.altMessage = altMessage!
            }
            mail.label = labelToBelongTo
            return mail
        }
    }

    func queryForLabel(labelId: String) -> [Label]? {
        let fetchRequest = NSFetchRequest(entityName: "Label")
        fetchRequest.predicate = NSPredicate(format: "labelId == %@", labelId)
        let results: [AnyObject]?
        do {
            results = try self.sharedContext.executeFetchRequest(fetchRequest)
        } catch _ as NSError {
            results = nil
        }
        return results as? [Label]
    }

    func queryForMail(id: String) -> [Mail]{
        var error: NSError?
        let fetchRequest = NSFetchRequest(entityName: "Mail")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        let results: [AnyObject]?
        do {
            results = try GmailClientHelper.sharedInstance.sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            results = nil
        }
        if error != nil {
            print("Error", terminator: "")
        }
        return results as! [Mail]
    }

    func fetchAllMails(label: Label) -> [Mail]{
        var error: NSError?
        let fetchRequest = NSFetchRequest(entityName: "Mail")
        fetchRequest.predicate = NSPredicate(format: "label == %@", label)
        let results: [AnyObject]?
        do {
            results = try self.sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            results = nil
        }
        if error != nil {
            print("Error", terminator: "")
        }
        return results as! [Mail]
    }
    
    func readBodydata(data: String) -> String {
        let bodyString = data.stringByReplacingOccurrencesOfString("-", withString: "+").stringByReplacingOccurrencesOfString("_", withString: "/")
        let htmlData = NSData(base64EncodedString: bodyString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        let string = NSString(data: htmlData!, encoding: NSUTF8StringEncoding) as? String
        return string!
    }

    func logout() -> Bool {
        let result = GTMOAuth2ViewControllerTouch.removeAuthFromKeychainForName("Gmail API")
        if result {
            return true
        }
        return false
    }

}