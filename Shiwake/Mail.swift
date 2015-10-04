//
//  Mail.swift
//  Shiwake
//
//  Created by ShimmenNobuyoshi on 2015/07/10.
//  Copyright (c) 2015年 Shimmen Nobuyoshi. All rights reserved.
//

import Foundation
import CoreData

@objc(Mail)

class Mail: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var historyId: NSNumber
    @NSManaged var threadId: String
    @NSManaged var snippet: String
    @NSManaged var to: String
    @NSManaged var from: String
    @NSManaged var subject: String
    @NSManaged var mimeType: String
    @NSManaged var message: String
    @NSManaged var altMessage: String?
    @NSManaged var label: Label

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dict: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Mail", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.id = dict["id"] as! String
        self.historyId = dict["historyId"] as! NSNumber
        self.threadId = dict["threadId"] as! String
        self.snippet = dict["snippet"] as! String
        self.to = dict["to"] as! String
        self.from = dict["from"] as! String
        self.subject = dict["subject"] as! String
        self.mimeType = dict["mimeType"] as! String
        self.message = dict["message"] as! String
    }

}