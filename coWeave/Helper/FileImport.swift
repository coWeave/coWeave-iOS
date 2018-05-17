/**
 * This file is part of coWeave-iOS.
 *
 * Copyright (c) 2017-2018 Benoît FRISCH
 *
 * coWeave-iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * coWeave-iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with coWeave-iOS If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import CoreData

class FileImport: NSObject {
    var managedObjectContext: NSManagedObjectContext!

    // MARK: Keys

    fileprivate enum Keys: String {
        case addedDate = "addedDate"
        case modifyDate = "modifyDate"
        case name = "name"
        case template = "template"
        case firstPage = "firstPage"
        case lastPage = "lastPage"
        case pages = "pages"
        case user = "user"
        case group = "group"
        case image = "image"
        case next = "next"
        case previous = "previous"
        case audio = "audio"
        case number = "number"
        case title = "title"
        case document = "document"
        case page = "page"
    }


    func importData(from url: URL) {
        // 1
        guard let dictionary = NSDictionary(contentsOf: url),
              let doc = dictionary as? [String: AnyObject],
              let name = doc[Keys.name.rawValue] as? String,
              let addedDate = doc[Keys.addedDate.rawValue] as? NSDate,
              let modifyDate = doc[Keys.modifyDate.rawValue] as? NSDate,
              let template = doc[Keys.template.rawValue] as? Bool,
              let user = doc[Keys.user.rawValue] as? String,
              let group = doc[Keys.group.rawValue] as? String,
              let pages = doc[Keys.pages.rawValue] as? [NSDictionary]
                else {
            return
        }

        // Create Entity
        let entity = NSEntityDescription.entity(forEntityName: "Document", in: self.managedObjectContext)

        // Initialize Record
        let document = Document(entity: entity!, insertInto: self.managedObjectContext)

        let formatter = DateFormatter()
        // initially set the format based on your datepicker date
        formatter.dateFormat = "dd.MM.yyyy"

        document.addedDate = addedDate
        document.modifyDate = modifyDate
        document.name = (user == "none") ? name : "\(name) - \(user) (\(group))"

        do {
            // Save Record
            try document.managedObjectContext?.save()
        } catch {
            let saveError = error as NSError
            print("\(saveError), \(saveError.userInfo)")
        }


        var previous: Page? = nil

        for item in pages { // loop through data items
            let p = item as! [String: AnyObject]
            let addedDate = p[Keys.addedDate.rawValue] as? NSDate
            let modifyDate = p[Keys.modifyDate.rawValue] as? NSDate
            let number = p[Keys.number.rawValue] as! Int16
            let title = p[Keys.title.rawValue] as? String
            let audio = p[Keys.audio.rawValue] as? NSData
            let imageData = p[Keys.image.rawValue] as? NSData

            // Create Entity
            let entity = NSEntityDescription.entity(forEntityName: "Page", in: self.managedObjectContext)

            // Initialize Record
            let pageAdd = Page(entity: entity!, insertInto: self.managedObjectContext)

            pageAdd.addedDate = addedDate
            pageAdd.number = number
            pageAdd.title = (title == "none") ? nil : title
            pageAdd.document = document
            pageAdd.previous = previous
            pageAdd.audio = audio

            if (imageData != nil) {
                // Create Entity
                let imageEntity = NSEntityDescription.entity(forEntityName: "Image", in: self.managedObjectContext)

                // Initialize Record
                let image = Image(entity: imageEntity!, insertInto: self.managedObjectContext)

                image.addedDate = NSDate()
                image.image = imageData
                image.previous = nil
                image.page = pageAdd

                pageAdd.image = image
            }

            document.lastPage = pageAdd

            if (previous != nil) {
                previous!.next = pageAdd
            }

            if (number == 1) {
                document.firstPage = pageAdd
            }

            do {
                // Save Record
                try pageAdd.managedObjectContext?.save()
            } catch {
                let saveError = error as NSError
                print("\(saveError), \(saveError.userInfo)")
            }
            previous = pageAdd

        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to remove item from Inbox")
        }
    }
}
