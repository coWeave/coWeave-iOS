//
//  Image+CoreDataProperties.swift
//  coWeave
//
//  Created by Benoît Frisch on 17.05.18.
//  Copyright © 2018 Benoît Frisch. All rights reserved.
//
//

import Foundation
import CoreData


extension Image {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged public var addedDate: NSDate?
    @NSManaged public var id: Int16
    @NSManaged public var image: NSData?
    @NSManaged public var small_image: NSData?
    @NSManaged public var thumbnail: NSData?
    @NSManaged public var next: Image?
    @NSManaged public var page: Page?
    @NSManaged public var previous: Image?

}
