//
//  ViewController.swift
//  taskMate
//
//  Created by Shalev on 15/08/2024.
//

import UIKit
import FirebaseDatabaseInternal

class ViewController: UIViewController {
    
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerBTN: UIButton!
    @IBOutlet weak var loginBTN: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Clear text fields when the view appears
        usernameTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func registerAction(_ sender: Any) {
        self.dismissAndNavigateToSignupController()
    }
    
    @IBAction func loginAction(_ sender: Any) {
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(message: "Please enter your username.")
            return
        }
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter your password.")
            return
        }

        // Clear any previous records
        loginUser(username: username, password: password)
    }
    
    private func loginUser(username: String, password: String) {
        let ref = Database.database().reference().child("users").child(username)
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            if let userDict = snapshot.value as? [String: Any],
               let storedPassword = userDict["password"] as? String {
                if password == storedPassword {
                    // Save user records and username in UserDefaults
                    self?.saveUserRecords(username: username)
                    
                    // Save username to UserDefaults
                    UserDefaults.standard.set(username, forKey: "username")
                
                    // Credentials match, navigate to HomeController
                    self?.dismissAndNavigateToHomeController()
                } else {
                    // Password does not match
                    self?.showAlert(message: "Incorrect password. Please try again.")
                }
            } else {
                // User does not exist
                self?.showAlert(message: "Username not found. Please sign up first.")
            }
        }
    }

    private func dismissAndNavigateToHomeController() {
        // Dismiss the current view controller
        self.dismiss(animated: false) {
            // Navigate to HomeController
            self.navigateToHomeController()
        }
    }
    
    private func dismissAndNavigateToSignupController() {
        // Dismiss the current view controller
        self.dismiss(animated: false) {
            // Navigate to HomeController
            self.navigateToSignupController()
        }
    }
    
        deinit {
            // Cleanup code if needed
            Database.database().reference().removeAllObservers()
            print("LoginController has been deallocated")
        }
        
        private func saveUserRecords(username: String) {
            let ref = Database.database().reference().child("users").child(username).child("records")
            ref.observeSingleEvent(of: .value) { [weak self] snapshot in
                var recordsArray: [[String: Any]] = []
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let recordDict = snapshot.value as? [String: Any] {
                        recordsArray.append(recordDict)
                    }
                }
                
                // Save records and username in UserDefaults
                let userDefaults = UserDefaults.standard
                userDefaults.set(recordsArray, forKey: "userRecords")
                userDefaults.set(username, forKey: "username")
                
                // Print saved username
                let savedUsername = userDefaults.string(forKey: "username")
                print("Saved username in UserDefaults: \(savedUsername ?? "None")")
            }
        }

    private func navigateToHomeController() {
        if let homeVC = storyboard?.instantiateViewController(identifier: "HomeController") {
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: false, completion: nil)
        }
    }
    
    private func navigateToSignupController() {
        if let homeVC = storyboard?.instantiateViewController(identifier: "SignupController") {
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: false, completion: nil)
        }
    }

    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}

