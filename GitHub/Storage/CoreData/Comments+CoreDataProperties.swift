//
//  Comments+CoreDataProperties.swift
//  GitHub test
//
//  Created by Nikita Marchenko on 02.04.2018.
//  Copyright © 2018 Nikita Marchenko. All rights reserved.
//
//

import Foundation
import CoreData


extension Comments {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comments> {
        return NSFetchRequest<Comments>(entityName: "Comments")
    }

    @NSManaged public var body: String?
    @NSManaged public var htmlUrl: String?
    @NSManaged public var id: Int32
    @NSManaged public var issues: Issues?

}
