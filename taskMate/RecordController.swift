//
//  RecordController.swift
//  taskMate
//
//  Created by Shalev on 22/08/2024.
//

import UIKit
import FirebaseDatabaseInternal

class CellForItem: UITableViewCell {
  
    @IBOutlet weak var itemTextField: UITextField!
    @IBOutlet weak var checkboxBTN: UIButton!
    var checkboxAction: (() -> Void)?
        
    @IBAction func checkboxTapped(_ sender: UIButton) {
        print("Checkbox tapped")
        checkboxAction?()
    }
}
class RecordController: UIViewController {
    @IBOutlet weak var addItemBTN: UIButton!
    @IBOutlet weak var collaborateBTN: UIButton!
    @IBOutlet weak var backBTN: UIButton!
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet weak var headerLabel: UILabel!
    var recordID: String?
    var recordName: String?
    var items: [Item] = []
    
    var suggestedUsers: [String] = []
    var pickerView = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        itemsTableView.delegate = self
        itemsTableView.dataSource = self
        if let recordID = recordID {
            print("Record ID: \(recordID)")
            loadItemsForRecord(recordID: recordID)
        }
        if let recordName = recordName {
            print("Record Name: \(recordName)") // Debug print the record name
            self.headerLabel.text = recordName // Optionally set the view controller's title to the record name
        }
    } 

    private func loadItemsForRecord(recordID: String) {
            print("Attempting to load items for record ID: \(recordID)")
            
            let ref = Database.database().reference().child("records").child(recordID)
            
            ref.observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    print("Document found. Retrieving data...")
                    if let data = snapshot.value as? [String: Any] {
                        print("Document data retrieved successfully.")
                        print("Data content: \(data)")
                        
                        if let itemsData = data["items"] as? [[String: Any]] {
                            print("Items field found. Parsing items...")
                            self.items = itemsData.map { dict in
                                let text = dict["text"] as? String ?? ""
                                let isChecked = dict["isChecked"] as? Bool ?? false
                                let id = dict["id"] as? String ?? UUID().uuidString
                                print("Parsed item - ID: \(id), Text: \(text), Is Checked: \(isChecked)")
                                return Item(text: text, isChecked: isChecked, id: id)
                            }
                            print("Items successfully parsed. Updating table view...")
                            self.itemsTableView.reloadData()
                        } else {
                            print("No 'items' field found in the document data.")
                        }
                    } else {
                        print("Document data is nil.")
                    }
                } else {
                    print("No document found with ID: \(recordID)")
                }
            } withCancel: { error in
                print("Error fetching document: \(error.localizedDescription)")
            }
        }
    
    @IBAction func addItemAction(_ sender: Any) {
    // Add a new item with placeholder text
       let newItem = Item(text: "", isChecked: false, id: UUID().uuidString)
       items.append(newItem)
       
       // Reload the table view to display the new item
       itemsTableView.reloadData()
       saveItemToFirestore(item: newItem)
       // Ensure the table view is reloaded before scrolling
       DispatchQueue.main.async {
           // Optionally, scroll to the newly added item if there are items in the table
           if self.items.count > 0 {
               let indexPath = IndexPath(row: self.items.count - 1, section: 0)
               self.itemsTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
           }
       }
   }
    
    @IBAction func collaborateAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Collaborate", message: "Enter a username to collaborate with", preferredStyle: .alert)
                
                alertController.addTextField { textField in
                    textField.placeholder = "Enter username"
                    textField.inputView = self.pickerView
                    textField.addTarget(self, action: #selector(self.usernameTextFieldDidChange(_:)), for: .editingChanged)
                }
                
                pickerView.dataSource = self
                pickerView.delegate = self
                
                let collaborateAction = UIAlertAction(title: "Collaborate", style: .default) { _ in
                    if let username = alertController.textFields?.first?.text, !username.isEmpty {
                        self.addCollaborator(username: username)
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                alertController.addAction(collaborateAction)
                alertController.addAction(cancelAction)
                
                present(alertController, animated: true, completion: nil)
            }
    
    @objc private func usernameTextFieldDidChange(_ textField: UITextField) {
            guard let query = textField.text, !query.isEmpty else { return }
            
            let ref = Database.database().reference().child("users")
            let usersWithAccessRef = Database.database().reference().child("records").child("id").child("users")
            
            usersWithAccessRef.observeSingleEvent(of: .value) { accessSnapshot in
                var usersWithAccess = [String]()
                
                if accessSnapshot.exists() {
                    for child in accessSnapshot.children.allObjects as! [DataSnapshot] {
                        usersWithAccess.append(child.key)
                    }
                }
                
                ref.queryOrdered(byChild: "username")
                    .queryStarting(atValue: query)
                    .queryEnding(atValue: query + "\u{f8ff}")
                    .queryLimited(toFirst: 5)
                    .observeSingleEvent(of: .value) { snapshot in
                        var suggestedUsers = [String]()
                        
                        if snapshot.exists() {
                            for child in snapshot.children.allObjects as! [DataSnapshot] {
                                let userId = child.key
                                if !usersWithAccess.contains(userId),
                                   let userData = child.value as? [String: Any],
                                   let username = userData["username"] as? String {
                                    suggestedUsers.append(username)
                                }
                            }
                            
                            self.suggestedUsers = suggestedUsers
                            self.pickerView.reloadAllComponents()
                        } else {
                            print("No matching users found")
                        }
                    }
            }
        }


    
    private func saveItemToFirestore(item: Item) {
            guard let recordID = recordID else {
                print("Error: No record ID available.")
                return
            }
            
            let ref = Database.database().reference().child("records").child(recordID)
            
            ref.observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    var recordData = snapshot.value as? [String: Any] ?? [:]
                    
                    // Append the new item to the items array
                    var itemsData = recordData["items"] as? [[String: Any]] ?? []
                    let itemData: [String: Any] = ["id": item.id, "text": item.text, "isChecked": item.isChecked]
                    itemsData.append(itemData)
                    
                    // Update the record data with the new items array
                    recordData["items"] = itemsData
                    
                    // Save the updated record back to Firestore
                    ref.setValue(recordData) { error, _ in
                        if let error = error {
                            print("Error updating record: \(error.localizedDescription)")
                        } else {
                            print("Record successfully updated with new item.")
                        }
                    }
                } else {
                    print("No document found with ID: \(recordID)")
                }
            } withCancel: { error in
                print("Error retrieving document: \(error.localizedDescription)")
            }
        }
    
    private func addCollaborator(username: String) {
        guard let recordID = recordID else { return }

        let recordRef = Database.database().reference().child("records").child(recordID)
        
        // Fetch the record data first
        recordRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var recordData = snapshot.value as? [String: Any] else { return }
            
            // Check if the user is already a collaborator
            var users = recordData["users"] as? [String] ?? []
            if users.contains(username) {
                // User already exists as a collaborator, show an alert
                self?.showAlert(title: "", message: "The user \(username) is already a collaborator.")
                return
            }
            
            // If not, add the user as a collaborator
            users.append(username)
            recordData["users"] = users
            
            // Update the record in Firebase under the record
            recordRef.setValue(recordData) { [weak self] error, _ in
                if let error = error {
                    print("Failed to update record: \(error)")
                    self?.showAlert(title: "Error", message: "Failed to update record: \(error.localizedDescription)")
                    return
                }
                
                // Update the record in all users' records
                self?.updateRecordForAllUsers(recordID: recordID, recordData: recordData) { success in
                    if success {
                        // Add record reference under the user's records
                        let userRef = Database.database().reference().child("users").child(username).child("records").child(recordID)
                        userRef.setValue(recordData) { [weak self] error, _ in
                            if let error = error {
                                print("Failed to add record to user: \(error)")
                                self?.showAlert(title: "Error", message: "Failed to add record to user: \(error.localizedDescription)")
                            } else {
                                print("Collaborator added successfully")
                                self?.showAlert(title: "Success", message: "Collaborator \(username) added successfully.")
                            }
                        }
                    } else {
                        self?.showAlert(title: "Error", message: "Failed to update record for all users.")
                    }
                }
            }
        }
    }

    private func updateRecordForAllUsers(recordID: String, recordData: [String: Any], completion: @escaping (Bool) -> Void) {
        let usersRef = Database.database().reference().child("users")
        
        usersRef.observeSingleEvent(of: .value) { snapshot in
            guard let usersDict = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            for userID in usersDict.keys {
                let userRecordRef = Database.database().reference().child("users").child(userID).child("records").child(recordID)
                dispatchGroup.enter()
                userRecordRef.setValue(recordData) { error, _ in
                    if let error = error {
                        print("Failed to update record for user \(userID): \(error)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(true)
            }
        }
    }
    
    deinit {
        // Cleanup code if needed
        Database.database().reference().removeAllObservers()
        print("RecordController has been deallocated")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func backToHomeAction(_ sender: Any) {
        self.dismiss(animated: false) {
            self.navigateToHomeController()
        }
    }
    
//    private func addItem(text: String) {
//        let newItem = Item(text: text, isChecked: false)
//           items.append(newItem)
//           
//           // Reload the table view to display the new item
//           itemsTableView.reloadData()
//    }
   
    private func updateCheckbox(for indexPath: IndexPath) {
        print("Updating checkbox at indexPath: \(indexPath)")
        items[indexPath.row].isChecked.toggle()

        updateItem(item: items[indexPath.row])
        // Directly update the cell’s checkbox image
        if let cell = itemsTableView.cellForRow(at: indexPath) as? CellForItem {
            let imageName = items[indexPath.row].isChecked ? "checkmark.square" : "square"
            cell.checkboxBTN.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    private func updateItem(item: Item) {
            guard let recordID = recordID else {
                print("Error: No record ID available.")
                return
            }
            
            let ref = Database.database().reference().child("records").child(recordID)
            
            ref.observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    var recordData = snapshot.value as? [String: Any] ?? [:]
                    
                    // Update the item in the items array
                    var itemsData = recordData["items"] as? [[String: Any]] ?? []
                    
                    if let index = itemsData.firstIndex(where: { $0["id"] as? String == item.id }) {
                        // Replace the item
                        itemsData[index] = ["id": item.id, "text": item.text, "isChecked": item.isChecked]
                        
                        // Update the record data with the updated items array
                        recordData["items"] = itemsData
                        
                        // Save the updated record back to Firestore
                        ref.setValue(recordData) { error, _ in
                            if let error = error {
                                print("Error updating record: \(error.localizedDescription)")
                            } else {
                                print("Record successfully updated with new item.")
                            }
                        }
                    } else {
                        print("Item with ID \(item.id) not found in the record.")
                    }
                } else {
                    print("No document found with ID: \(recordID)")
                }
            } withCancel: { error in
                print("Error retrieving document: \(error.localizedDescription)")
            }
        }
        
    @objc func checkboxButtonTapped(_ sender: UIButton) {
        print("CheckboxButtonTapped")
        let indexPath = IndexPath(row: sender.tag, section: 0)
        updateCheckbox(for: indexPath)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // Find the index path of the cell containing the text field
        if let cell = textField.superview?.superview as? CellForItem,
           let indexPath = itemsTableView.indexPath(for: cell) {
            items[indexPath.row].text = textField.text ?? ""
            updateItem(item: items[indexPath.row])
        }
    }
    
    private func navigateToHomeController() {
        if let homeVC = storyboard?.instantiateViewController(identifier: "HomeController") {
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: false, completion: nil)
        }
    }
}

extension RecordController: UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return items.count
        }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! CellForItem
        let item = items[indexPath.row]
        
        cell.itemTextField.text = item.text
        let imageName = item.isChecked ? "checkmark.square" : "square"
        cell.checkboxBTN.setImage(UIImage(systemName: imageName), for: .normal)
        cell.checkboxBTN.tag = indexPath.row // Set the tag for button
        
        cell.checkboxAction = { [weak self] in
            self?.checkboxButtonTapped(cell.checkboxBTN)
        }
        
        cell.itemTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                // Remove the item from the data source
                let removedItem = items.remove(at: indexPath.row)
                
                // Delete the item from Firebase
                deleteItemFromFirestore(item: removedItem)
                
                // Remove the row from the table view
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
        // Set the background color to red during the swipe-to-delete action
        func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
            if let cell = tableView.cellForRow(at: indexPath) as? CellForItem {
                cell.backgroundColor = UIColor.red
            }
        }
        
        // Reset the background color after the swipe-to-delete action
        func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
            if let indexPath = indexPath,
               let cell = tableView.cellForRow(at: indexPath) as? CellForItem {
                cell.backgroundColor = UIColor.white // or your default color
            }
        }
        
        private func deleteItemFromFirestore(item: Item) {
            guard let recordID = recordID else {
                print("Error: No record ID available.")
                return
            }
            
            let ref = Database.database().reference().child("records").child(recordID)
            
            ref.observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    var recordData = snapshot.value as? [String: Any] ?? [:]
                    var itemsData = recordData["items"] as? [[String: Any]] ?? []
                    
                    // Remove the item from the items array
                    if let index = itemsData.firstIndex(where: { $0["id"] as? String == item.id }) {
                        itemsData.remove(at: index)
                        recordData["items"] = itemsData
                        
                        // Save the updated record back to Firestore
                        ref.setValue(recordData) { error, _ in
                            if let error = error {
                                print("Error deleting item: \(error.localizedDescription)")
                            } else {
                                print("Item successfully deleted from Firestore.")
                            }
                        }
                    }
                } else {
                    print("No document found with ID: \(recordID)")
                }
            } withCancel: { error in
                print("Error retrieving document: \(error.localizedDescription)")
            }
        }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return suggestedUsers.count
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return suggestedUsers[row]
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            // Update the text field with the selected username
            if let alertController = presentedViewController as? UIAlertController,
               let textField = alertController.textFields?.first {
                textField.text = suggestedUsers[row]
            }
        }
        
}
