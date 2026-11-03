//
//  SignUpViewController.swift
//  Expensive_Tracker
//
//  Created on 03/11/2026.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var eyeButton: UIImageView!
    @IBOutlet weak var confirmEyeButton: UIImageView!
    @IBOutlet weak var signUpActionButton: UIButton!
    @IBOutlet weak var googleSignUpButton: UIButton!
    
    private var isPasswordVisible = false
    private var isConfirmVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"
        setupDelegatesAndGestures()
    }
    
    private func setupDelegatesAndGestures() {
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        eyeButton.isUserInteractionEnabled = true
        let eyeTap = UITapGestureRecognizer(target: self, action: #selector(togglePasswordVisibility))
        eyeButton.addGestureRecognizer(eyeTap)
        
        confirmEyeButton.isUserInteractionEnabled = true
        let confirmEyeTap = UITapGestureRecognizer(target: self, action: #selector(toggleConfirmVisibility))
        confirmEyeButton.addGestureRecognizer(confirmEyeTap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordTextField.isSecureTextEntry = !isPasswordVisible
        eyeButton.image = UIImage(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
    }
    
    @objc private func toggleConfirmVisibility() {
        isConfirmVisible.toggle()
        confirmPasswordTextField.isSecureTextEntry = !isConfirmVisible
        confirmEyeButton.image = UIImage(systemName: isConfirmVisible ? "eye.fill" : "eye.slash.fill")
    }
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert("Please enter your full name.")
            return
        }
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            showAlert("Please enter your email address.")
            return
        }
        guard let password = passwordTextField.text, password.count >= 6 else {
            showAlert("Password must be at least 6 characters long.")
            return
        }
        guard let confirm = confirmPasswordTextField.text, confirm == password else {
            showAlert("Passwords do not match.")
            return
        }
        
        signUpActionButton.isEnabled = false
        signUpActionButton.setTitle("  Creating Account...", for: .normal)
        
        AuthManager.shared.signUp(email: email, password: password, name: name) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.signUpActionButton.isEnabled = true
                self.signUpActionButton.setTitle("  Create Account", for: .normal)
                
                switch result {
                case .success(let user):
                    FirestoreManager.shared.saveProfile(
                        name: name,
                        email: user.email ?? email
                    )
                    self.goToMainDashboard()
                case .failure(let error):
                    self.showAlert(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func googleSignUpTapped(_ sender: UIButton) {
        googleSignUpButton.isEnabled = false
        googleSignUpButton.setTitle("  Signing up...", for: .normal)
        
        AuthManager.shared.signInWithGoogle(presenting: self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.googleSignUpButton.isEnabled = true
                self.googleSignUpButton.setTitle("  Continue with Google", for: .normal)
                
                switch result {
                case .success(let user):
                    FirestoreManager.shared.saveProfile(
                        name: user.displayName ?? "",
                        email: user.email ?? ""
                    )
                    self.goToMainDashboard()
                case .failure(let error):
                    self.showAlert(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func backToSignInTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    private func goToMainDashboard() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate else { return }

        let tabBar = MainTabBarController()
        sceneDelegate.window?.rootViewController = tabBar
        sceneDelegate.window?.makeKeyAndVisible()

        UIView.transition(with: sceneDelegate.window!,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil)
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
