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

class PagesTableViewController: UITableViewController {
    var managedObjectContext: NSManagedObjectContext!
    var document: Document!

    lazy var fetchedResultsController: NSFetchedResultsController<Page> = {
        // Initialize Fetch Request
        let fetchRequest: NSFetchRequest<Page> = Page.fetchRequest()

        // Add Sort Descriptors
        let number = NSSortDescriptor(key: "number", ascending: true)
        fetchRequest.sortDescriptors = [number]

        fetchRequest.predicate = NSPredicate(format: "document == %@", self.document)

        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("pages", comment: "")
        self.tableView.rowHeight = 150.0
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }

        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterItemID: "PagesList" as NSObject,
                AnalyticsParameterItemName: "PagesList" as NSObject,
                AnalyticsParameterContentType: "document-pages" as NSObject
        ])

        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Page", for: indexPath) as? PagesTableViewCell else {
            fatalError("The dequeued cell is not an instance of PageTableViewCell.")
        }

        let page = self.fetchedResultsController.object(at: indexPath) as Page

        let formatter = DateFormatter()
        // initially set the format based on your datepicker date
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"

        cell.title.text = (page.title == nil) ? "Page \(page.number)" : page.title
        if (page.image != nil) {
            DispatchQueue.main.async(execute: { () -> Void in
                cell.pageImage.image = UIImage(data: page.image!.image! as Data, scale: 0.01)
            })
        }
        cell.number.text = "\(page.number)"
        cell.date.text = formatter.string(from: page.addedDate! as Date)

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0000001
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print("select")
        let page = self.fetchedResultsController.object(at: indexPath)

        let alertController = UIAlertController(title: "\(NSLocalizedString("modify-page-title", comment: "")) \(page.number):", message: "", preferredStyle: .alert)

        let confirmAction = UIAlertAction(title: NSLocalizedString("save", comment: ""), style: .default) { (_) in
            if let field = alertController.textFields![0] as? UITextField {
                // store your data
                page.title = field.text
                do {
                    // Save Record
                    try page.managedObjectContext?.save()
                } catch {
                    let saveError = error as NSError
                    print("\(saveError), \(saveError.userInfo)")
                }
                tableView.reloadData()
                Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                        AnalyticsParameterItemID: "ModifyPageTitle" as NSObject,
                        AnalyticsParameterItemName: "ModifyPageTitle" as NSObject,
                        AnalyticsParameterContentType: "document-pages" as NSObject
                ])
            } else {
                // user did not fill field
            }
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { (_) in
        }

        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("title", comment: "")
            textField.text = page.title
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "openPage") {
            let classVc = segue.destination as! DocumentDetailNavigationViewController
            classVc.managedObjectContext = self.managedObjectContext
            classVc.document = self.document
            let page = self.fetchedResultsController.object(at: tableView.indexPathForSelectedRow!)
            classVc.page = page
        }
    }
}

