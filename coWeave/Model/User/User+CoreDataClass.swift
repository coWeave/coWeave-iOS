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

import Foundation
import CoreData
import Zip

public class User: NSManagedObject {
    func exportCoweaveURL() -> URL? {
        var folderName = "export/\(self.name!)_\(arc4random())/";
        
        for d in self.documents! {
            let doc = d as! Document
            doc.exportToFileURL(folder: folderName);
        }
        
        let documentsDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let exportPath = documentsDirectory.appendingPathComponent(folderName)
        
        do {
            let formatter = DateFormatter()
            // initially set the format based on your datepicker date
            formatter.dateFormat = "dd.MM.yyyy_HH:mm:ss"
            
            let zipFilePath = try Zip.quickZipFiles([exportPath], fileName: "\(self.name!)_\(formatter.string(from: NSDate() as Date))") // Zip
            
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: exportPath.path)
            } catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
            return zipFilePath
            
        } catch {
            print("Something went wrong")
        }
        return exportPath
    }
    
    
    func exportZipURL() -> URL? {
        var folderName = "export/\(self.name!)_\(arc4random())/";
        for d in self.documents! {
            let doc = d as! Document
            doc.exportZipURL(folder: folderName);
        }
        
        let documentsDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let exportPath = documentsDirectory.appendingPathComponent(folderName)
        
        do {
            let formatter = DateFormatter()
            // initially set the format based on your datepicker date
            formatter.dateFormat = "dd.MM.yyyy_HH:mm:ss"
            
            let zipFilePath = try Zip.quickZipFiles([exportPath], fileName: "\(self.name!)_\(formatter.string(from: NSDate() as Date))") // Zip
            
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: exportPath.path)
            } catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
            return zipFilePath
            
        } catch {
            print("Something went wrong")
        }
        return exportPath
    }
}
