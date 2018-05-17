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
import Firebase
import Localize_Swift

class SettingsTableViewController: UITableViewController {
    var managedObjectContext: NSManagedObjectContext!
    var actionSheet: UIAlertController!
    let availableLanguages = Localize.availableLanguages()
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var languageButton: UIButton!
    @IBOutlet var pictureLibrarySwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = 55.0

        pictureLibrarySwitch.setOn(UserDefaults.standard.bool(forKey: "savePictures"), animated: false)

        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterItemID: "Settings" as NSObject,
                AnalyticsParameterItemName: "Settings" as NSObject,
                AnalyticsParameterContentType: "settings" as NSObject
        ])

        versionLabel.text = "Version \(Bundle.main.releaseVersionNumber!) (\(Bundle.main.buildVersionNumber!))"
    }

    @IBAction func selectLanguage(_ sender: Any) {
        actionSheet = UIAlertController(title: nil, message: NSLocalizedString("language-switcher", comment: ""), preferredStyle: UIAlertControllerStyle.actionSheet)
        for language in availableLanguages {
            let displayName = Localize.displayNameForLanguage(language)
            let languageAction = UIAlertAction(title: displayName, style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                print(language)
                UserDefaults.standard.set([language], forKey: "AppleLanguages")
                UserDefaults.standard.synchronize()
                Localize.setCurrentLanguage(language)
            })
            if displayName.count > 0 {
                actionSheet.addAction(languageAction)
            }

        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction) -> Void in
        })
        actionSheet.addAction(cancelAction)
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = languageButton
            popoverController.sourceRect = languageButton.bounds
        }
        self.present(actionSheet, animated: true, completion: nil)
    }

    @IBAction func savePictureSaveLibrary(_ sender: Any) {
        UserDefaults.standard.set(pictureLibrarySwitch.isOn, forKey: "savePictures")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
