//
//  SignupController.swift
//  taskMate
//
//  Created by Shalev on 22/08/2024.
//
import UIKit
import FirebaseDatabaseInternal

class SignupController: UIViewController {

    @IBOutlet weak var signupLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signupBTN: UIButton!
    @IBOutlet weak var exitBTN: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    } 
    @IBAction func signupAction(_ sender: Any) {
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(message: "Please enter a username.")
            return
        }
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter a password.")
            return
        }
        guard let confirmPassword = confirmPasswordTextField.text, password == confirmPassword else {
            showAlert(message: "Passwords do not match.")
            return
        }
        checkUsernameAndSignup(username: username, password: password) { [weak self] success in
            if success {
                // Navigate to the next screen only if sign-up was successful
                self?.dismiss(animated: false) {
                    self?.navigateToViewController()
                }
            }
        }
    }
    
    deinit {
        // Cleanup code if needed
        Database.database().reference().removeAllObservers()
        print("SignupController has been deallocated")
    }
        
        private func checkUsernameAndSignup(username: String, password: String, completion: @escaping (Bool) -> Void) {
                let ref = Database.database().reference().child("users").child(username)
                ref.observeSingleEvent(of: .value) { [weak self] snapshot in
                    if snapshot.exists() {
                        self?.showAlert(message: "Username already exists. Please choose another one.")
                        completion(false)
                    } else {
                        let newUser = User(username: username, password: password)
                        ref.setValue(newUser.toDictionary()) { error, _ in
                            if let error = error {
                                self?.showAlert(message: "Failed to save user data: \(error.localizedDescription)")
                                completion(false)
                            } else {
                                self?.showAlert(message: "Sign-up successful!")
                                completion(true)
                            }
                        }
                    }
                }
        }
        
    private func navigateToViewController() {
        // Replace `MainViewController` with the actual identifier of your main view controller
        if let mainVC = storyboard?.instantiateViewController(identifier: "LoginController") {
            mainVC.modalPresentationStyle = .fullScreen
            self.present(mainVC, animated: false, completion: nil)
        }
    }

    @IBAction func exitAction(_ sender: Any) {
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
