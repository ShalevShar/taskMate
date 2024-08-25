//
//  HomeController.swift
//  taskMate
//
//  Created by Shalev on 22/08/2024.
//

import UIKit
import FirebaseDatabaseInternal

class CellForRecord: UITableViewCell {
    //@IBOutlet weak var recordLabel: UILabel!
    @IBOutlet weak var recordLabel: UILabel!
}

class HomeController: UIViewController {
    @IBOutlet weak var newRecordBTN: UIButton!
    @IBOutlet weak var logoutBTN: UIButton!
    @IBOutlet weak var personalBTN: UIButton!
    @IBOutlet weak var noActiveRecordsLabel: UILabel!
    @IBOutlet weak var arrowIMG: UIImageView!
    
    @IBOutlet weak var recordsTableView: UITableView!
    var strings: [String] = ["a", "b", "c", "d"]
    var records: [Record] = [] // Array to hold records
    private var username: String? {
        return UserDefaults.standard.string(forKey: "username")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recordsTableView.delegate = self
        recordsTableView.dataSource = self
        recordsTableView.isUserInteractionEnabled = true
        if let username = username {
            fetchRecordsFromDatabase(username: username)
        } else {
            showAlert(message: "Username not found. Please log in again.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let username = username {
            fetchRecordsFromDatabase(username: username)
        } else {
            showAlert(message: "Username not found. Please log in again.")
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "userRecords")
        
        
        // Clear local state
        records.removeAll()
        recordsTableView.reloadData()
        noActiveRecordsLabel.isHidden = false
        arrowIMG.isHidden = false
        recordsTableView.isHidden = true
        
        // Dismiss HomeController and go back to ViewController
        self.dismiss(animated: false) {
            self.navigateToViewController()
        }
    }
    
    deinit {
        // Cleanup code if needed
        Database.database().reference().removeAllObservers()
        print("HomeController has been deallocated")
    }
    
    @IBAction func newRecordAction(_ sender: Any) {
        showNewRecordDialog()
    }
    @IBAction func personalAction(_ sender: Any) {
    }
    
    private func showNewRecordDialog() {
        view.endEditing(true)
        print("Showing new record dialog")
        let alertController = UIAlertController(title: "New Record", message: "Enter the name of the new record", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Record name"
        }
        view.endEditing(true)
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let recordName = alertController.textFields?.first?.text, !recordName.isEmpty,
                  let username = self?.username else {
                self?.showAlert(message: "Please enter a valid record name or log in again.")
                return
            }
            self?.createRecord(recordName: recordName, username: username)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        
        DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func createRecord(recordName: String, username: String) {
        // Generate a unique key for the record
        let recordRef = Database.database().reference().child("records").childByAutoId()
        let recordID = recordRef.key // This is the unique ID that will be used in both locations
        
        // Create a new Record object with the current user and the unique ID
        let newRecord = Record(recordName: recordName, items: [], users: [username], id: recordID!)
        records.append(newRecord)
        
        // Convert the record to a dictionary
        let recordData = newRecord.toDictionary()
        
        // Update Firebase Database under users -> username -> records -> recordID
        let userRef = Database.database().reference().child("users").child(username).child("records").child(recordID!)
        userRef.setValue(recordData)
        
        // Update Firebase Database under records -> recordID for shared access
        recordRef.setValue(recordData)
        
        // Reload table view
        DispatchQueue.main.async {
            self.recordsTableView.reloadData()
        }
    }
    
    private func fetchRecordsFromDatabase(username: String) {
        let userRef = Database.database().reference().child("users").child(username).child("records")
        userRef.observe(.value) { [weak self] snapshot in
            self?.records.removeAll()
            var fetchedRecords: [String: Any] = [:]
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any] {
                    fetchedRecords[snapshot.key] = dict // Store the fetched record data for debugging
                    
                    // Extract record data
                    if let recordName = dict["recordName"] as? String {
                        let itemsArray = dict["items"] as? [[String: Any]] ?? []
                        
                        let items = itemsArray.compactMap { itemDict -> Item? in
                            guard let text = itemDict["text"] as? String,
                                  let isChecked = itemDict["isChecked"] as? Bool,
                                  let itemID = itemDict["id"] as? String else { return nil }
                            return Item(text: text, isChecked: isChecked, id: itemID)
                        }
                        
                        let recordID = dict["id"] as? String ?? UUID().uuidString
                        let usersArray = dict["users"] as? [String] ?? []
                        let record = Record(recordName: recordName, items: items, users: usersArray, id: recordID)
                        self?.records.append(record)
                    }
                }
            }
            
            // Debug: Print the fetched records and the records array
            print("Fetched Records: \(fetchedRecords)")
            print("Records array: \(self?.records ?? [])")
            
            // Reload table view on the main thread
            DispatchQueue.main.async {
                self?.recordsTableView.reloadData()
                
                // Hide or show the no active records label and arrow image based on records array
                let hasRecords = !(self?.records.isEmpty ?? true)
                self?.noActiveRecordsLabel.isHidden = hasRecords
                self?.arrowIMG.isHidden = hasRecords
                self?.recordsTableView.isHidden = !hasRecords
            }
        } withCancel: { error in
            print("Failed to fetch records: \(error.localizedDescription)")
            self.showAlert(message: "Failed to fetch records. Please try again later.")
        }
    }
        
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func navigateToViewController() {
        // Replace `MainViewController` with the actual identifier of your main view controller
        if let mainVC = storyboard?.instantiateViewController(identifier: "LoginController") {
            mainVC.modalPresentationStyle = .fullScreen
            self.present(mainVC, animated: false, completion: nil)
        }
    }
}

extension HomeController: UITableViewDelegate ,UITableViewDataSource{
    // TableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellForRecord", for: indexPath) as! CellForRecord
                
        let record = self.records[indexPath.row] // Get the record from the records array
                cell.recordLabel?.text = record.recordName // Set the record name to the label
                
                return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRecord = records[indexPath.row]
        
        // Debug: Print the selected record details
        print("Selected Record: \(selectedRecord)")
        
        // Instantiate RecordController and pass the selected record's ID
        if let recordController = storyboard?.instantiateViewController(withIdentifier: "RecordController") as? RecordController {
            recordController.recordID = selectedRecord.id
            recordController.recordName = selectedRecord.recordName
            // Set the modal presentation style to full screen
            recordController.modalPresentationStyle = .fullScreen
            
            self.present(recordController, animated: false, completion: nil)
        } else {
            // Debug: Log if the RecordController couldn't be instantiated
            print("Failed to instantiate RecordController")
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let recordToDelete = records[indexPath.row]
            
            // Remove the record locally
            records.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // Delete the record from Firebase Database for all users
            let recordID = recordToDelete.id // Directly use the id since it's non-optional

            deleteRecordForAllUsers(recordID: recordID) { [weak self] success in
                if success {
                    print("Record deleted successfully from all users")
                } else {
                    self?.showAlert(message: "Failed to delete record from all users. Please try again later.")
                }
            }
        }
    }

    private func deleteRecordForAllUsers(recordID: String, completion: @escaping (Bool) -> Void) {
        let recordRef = Database.database().reference().child("records").child(recordID)
        let usersRef = recordRef.child("users")
        
        // Fetch the users associated with this record
        usersRef.observeSingleEvent(of: .value) { snapshot in
            guard let users = snapshot.value as? [String] else {
                completion(false)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            for username in users {
                dispatchGroup.enter()
                
                let userRecordRef = Database.database().reference().child("users").child(username).child("records").child(recordID)
                
                userRecordRef.removeValue { error, _ in
                    if let error = error {
                        print("Failed to delete record for user \(username): \(error.localizedDescription)")
                    } else {
                        print("Record deleted for user \(username) successfully")
                    }
                    dispatchGroup.leave()
                }
            }
            
            // After removing the record from all users, delete the record itself
            dispatchGroup.notify(queue: .main) {
                recordRef.removeValue { error, _ in
                    if let error = error {
                        print("Failed to delete shared record: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Shared record deleted successfully")
                        completion(true)
                    }
                }
            }
        }
    }

}

