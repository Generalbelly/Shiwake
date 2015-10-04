//
//  Label.swift
//  Shiwake
//
//  Created by ShimmenNobuyoshi on 2015/07/22.
//  Copyright (c) 2015年 Shimmen Nobuyoshi. All rights reserved.
//

import Foundation
import CoreData

@objc(Label)

class Label: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var labelId: String
    @NSManaged var mails: [Mail]

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dict: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Label", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.labelId = dict["labelId"] as! String
        self.id = dict["id"] as! String
    }
    
}
