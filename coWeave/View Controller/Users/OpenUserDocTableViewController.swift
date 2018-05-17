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

class OpenUserDocTableViewController: UITableViewController, UISearchBarDelegate  {
    var managedObjectContext: NSManagedObjectContext!
    var user: User!
    private var search = ""
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var orderButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!

    lazy var fetchedResultsController: NSFetchedResultsController<Document> = {
        // Initialize Fetch Request
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()

        // Add Sort Descriptors
        let date = NSSortDescriptor(key: "modifyDate", ascending: false)
        let name = NSSortDescriptor(key: "name", ascending: false)
        fetchRequest.sortDescriptors = [date, name]

        fetchRequest.predicate = NSPredicate(format: "user == %@", self.user)

        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "\(user!.name!)"
        self.tableView.rowHeight = 100.0

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
                AnalyticsParameterItemID: "OpenDocument" as NSObject,
                AnalyticsParameterItemName: "OpenDocument" as NSObject,
                AnalyticsParameterContentType: "users" as NSObject
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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (fetchedResultsController.fetchedObjects!.count == 0) {
            return NSLocalizedString("no-documents", comment: "")
        } else {
            return ""
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Document", for: indexPath) as? DocumentsTableViewCell else {
            fatalError("The dequeued cell is not an instance of PageTableViewCell.")
        }
        let document = self.fetchedResultsController.object(at: indexPath)
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        
        cell.pageTitle.text = document.name
        
        DispatchQueue.main.async(execute: { () -> Void in
            cell.documentImage.image = (document.firstPage?.image?.thumbnail != nil) ? UIImage(data: (document.firstPage?.image!.thumbnail!)! as Data, scale: 1) : UIImage(named: "documentPlaceholder")
        })
        
        cell.pageDate.text = "\(formatter.string(from: document.addedDate! as Date))"
        return cell
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print("select")
        let document = self.fetchedResultsController.object(at: indexPath)

        let alertController = UIAlertController(title: NSLocalizedString("modify-title", comment: ""), message: "", preferredStyle: .alert)

        let confirmAction = UIAlertAction(title: NSLocalizedString("modify", comment: ""), style: .default) { (_) in
            if let field = alertController.textFields![0] as? UITextField {
                // store your data
                document.name = field.text
                do {
                    // Save Record
                    try document.managedObjectContext?.save()
                } catch {
                    let saveError = error as NSError
                    print("\(saveError), \(saveError.userInfo)")
                }
                tableView.reloadData()
            } else {
                // user did not fill field
            }
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { (_) in
        }

        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("name", comment: "")
            textField.text = document.name
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0000001
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Fetch Record
            let record = self.fetchedResultsController.object(at: indexPath) as Document
            // Create the alert controller
            let alertController = UIAlertController(title: NSLocalizedString("delete", comment: ""), message: "\(NSLocalizedString("delete-warning-1", comment: "")) \(record.name!)? \n\n \(NSLocalizedString("delete-warning-2", comment: ""))", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: UIAlertActionStyle.destructive) {
                UIAlertAction in
                NSLog("Supprimer Pressed")

                // Delete Record
                self.managedObjectContext.delete(record)
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    let fetchError = error as NSError
                    print("\(fetchError), \(fetchError.userInfo)")
                }
                do {
                    // Save Record
                    try self.managedObjectContext?.save()
                } catch {
                    let saveError = error as NSError
                    print("\(saveError), \(saveError.userInfo)")
                }
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: UIAlertActionStyle.cancel) {
                UIAlertAction in
                NSLog("Cancel Pressed")
            }

            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)

            // Present the controller
            self.present(alertController, animated: true, completion: nil)
        }
    }

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("searchText \(String(describing: searchBar.text))")
        self.search(searchString: searchBar.text!)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchText \(String(describing: searchBar.text))")
        self.search(searchString: searchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("searchText \(String(describing: searchBar.text))")
        self.search(searchString: "")
    }
    
    // called when text changes (including clear)
    internal func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "user == %@", self.user)
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        tableView.reloadData()
    }
    
    
    func search(searchString: String) {
        self.search = searchString
        var predicate:NSPredicate? = nil
        if searchString.count != 0 {
            predicate = NSPredicate(format: "((name BEGINSWITH [c] %@) OR (name CONTAINS [c] %@)) AND user == %@", searchString, searchString, self.user)
        } else {
            predicate = NSPredicate(format: "user == %@", self.user)
        }
        fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        self.tableView.reloadData()
    }
    
    @IBAction func orderAction(_ sender: Any) {
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "OpenOrderAction" as NSObject,
            AnalyticsParameterItemName: "OpenOrderAction" as NSObject,
            AnalyticsParameterContentType: "document" as NSObject
            ])
        
        let actionSheet: UIAlertController! = UIAlertController(title: nil, message: NSLocalizedString("order-action", comment: ""), preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let createdASC = UIAlertAction(title: NSLocalizedString("oldest-first", comment: ""), style: UIAlertActionStyle.default, image: UIImage(named: "order12")!, handler: {
            (alert: UIAlertAction) -> Void in
            // Add Sort Descriptors
            let date = NSSortDescriptor(key: "addedDate", ascending: true)
            self.fetchedResultsController.fetchRequest.sortDescriptors = [date]
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                let fetchError = error as NSError
                print("\(fetchError), \(fetchError.userInfo)")
            }
            self.tableView.reloadData()
            self.orderButton.image = UIImage(named: "order12")
        })
        let createdDESC = UIAlertAction(title: NSLocalizedString("newest-first", comment: ""), style: UIAlertActionStyle.default, image: UIImage(named: "order21")!, handler: {
            (alert: UIAlertAction) -> Void in
            // Add Sort Descriptors
            let date = NSSortDescriptor(key: "addedDate", ascending: false)
            self.fetchedResultsController.fetchRequest.sortDescriptors = [date]
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                let fetchError = error as NSError
                print("\(fetchError), \(fetchError.userInfo)")
            }
            self.tableView.reloadData()
            self.orderButton.image = UIImage(named: "order21")
        })
        
        let modifyASC = UIAlertAction(title: NSLocalizedString("last-opened", comment: ""), style: UIAlertActionStyle.default, image: UIImage(named: "order12")!, handler: {
            (alert: UIAlertAction) -> Void in
            // Add Sort Descriptors
            let date = NSSortDescriptor(key: "modifyDate", ascending: false)
            self.fetchedResultsController.fetchRequest.sortDescriptors = [date]
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                let fetchError = error as NSError
                print("\(fetchError), \(fetchError.userInfo)")
            }
            self.tableView.reloadData()
            self.orderButton.image = UIImage(named: "order12")
        })
        
        let titleAZ = UIAlertAction(title: NSLocalizedString("title", comment: "")+" A-Z", style: UIAlertActionStyle.default, image: UIImage(named: "orderAZ")!, handler: {
            (alert: UIAlertAction) -> Void in
            // Add Sort Descriptors
            let date = NSSortDescriptor(key: "name", ascending: false)
            self.fetchedResultsController.fetchRequest.sortDescriptors = [date]
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                let fetchError = error as NSError
                print("\(fetchError), \(fetchError.userInfo)")
            }
            self.tableView.reloadData()
            self.orderButton.image = UIImage(named: "orderAZ")
        })
        
        let titleZA = UIAlertAction(title: NSLocalizedString("title", comment: "")+" Z-A", style: UIAlertActionStyle.default, image: UIImage(named: "orderZA")!, handler: {
            (alert: UIAlertAction) -> Void in
            // Add Sort Descriptors
            let date = NSSortDescriptor(key: "name", ascending: true)
            self.fetchedResultsController.fetchRequest.sortDescriptors = [date]
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                let fetchError = error as NSError
                print("\(fetchError), \(fetchError.userInfo)")
            }
            self.tableView.reloadData()
            self.orderButton.image = UIImage(named: "orderZA")
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction) -> Void in
        })
        
        actionSheet.addAction(modifyASC)
        actionSheet.addAction(titleAZ)
        actionSheet.addAction(titleZA)
        actionSheet.addAction(createdASC)
        actionSheet.addAction(createdDESC)
        actionSheet.addAction(cancelAction)
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = orderButton
        }
        self.present(actionSheet, animated: true, completion: {
            
        })
    }
    
    @IBAction func shareAction(_ sender: Any) {
        let actionSheet: UIAlertController! = UIAlertController(title: nil, message: NSLocalizedString("export-format", comment: ""), preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let coWeaveAction = UIAlertAction(title: "coWeave", style: UIAlertActionStyle.default, image: UIImage(named: "AppIcon")!, handler: {
            (   alert: UIAlertAction) -> Void in
            
            guard let user = self.user,
                let url = user.exportCoweaveURL() else {
                    return
            }
            
            let activityViewController = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil)
            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.barButtonItem = (sender as! UIBarButtonItem)
            }
            self.present(activityViewController, animated: true, completion: nil)
            
        })
        
        let zipAction = UIAlertAction(title: "Zip", style: UIAlertActionStyle.default, image: UIImage(named: "zip")!, handler: {
            (   alert: UIAlertAction) -> Void in
            guard let user = self.user,
                let url = user.exportZipURL() else {
                    return
            }
            
            let activityViewController = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil)
            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.barButtonItem = (sender as! UIBarButtonItem)
            }
            self.present(activityViewController, animated: true, completion: nil)
            
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction) -> Void in
        })
        
        
        actionSheet.addAction(coWeaveAction)
        actionSheet.addAction(zipAction)
        actionSheet.addAction(cancelAction)
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = self.shareButton
        }
        self.present(actionSheet, animated: true, completion: nil)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "open") {
            let classVc = segue.destination as! DocumentDetailNavigationViewController
            classVc.managedObjectContext = self.managedObjectContext
            let doc = self.fetchedResultsController.object(at: tableView.indexPathForSelectedRow!)
            classVc.document = doc
        }
    }
}

