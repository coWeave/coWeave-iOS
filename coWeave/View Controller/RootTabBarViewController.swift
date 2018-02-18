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

class RootTabBarViewController: UITabBarController {
    var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()

        // pass managedObjectcontext to viewcontrollers
        let documentsController = self.viewControllers![0] as! DocumentsNavigationViewController
        documentsController.managedObjectContext = managedObjectContext

        // pass managedObjectcontext to viewcontrollers
        let userController = self.viewControllers![1] as! UserNavigationViewController
        userController.managedObjectContext = managedObjectContext

        // pass managedObjectcontext to viewcontrollers
        let settingsController = self.viewControllers![2] as! SettingsNavigationViewController
        settingsController.managedObjectContext = managedObjectContext

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

