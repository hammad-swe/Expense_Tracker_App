//
//  LoginViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 12/06/2026.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var paswordText: UITextField!
    @IBOutlet weak var eyeButton: UIImageView!
    @IBOutlet weak var googleSignInButton: UIButton!
    @IBOutlet weak var loginActionButton: UIButton?
    
    private var isPasswordVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }

    func setupUI() {
        title = "Sign In"
        emailText.delegate = self
        paswordText.delegate = self
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        eyeButton.isUserInteractionEnabled = true
        let eyeTap = UITapGestureRecognizer(target: self, action: #selector(togglePasswordVisibility))
        eyeButton.addGestureRecognizer(eyeTap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        paswordText.isSecureTextEntry = !isPasswordVisible
        eyeButton.image = UIImage(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
    }
    
    @IBAction func emailLoginTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        guard let email = emailText.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            showAlert("Please enter your email address.")
            return
        }
        guard let password = paswordText.text, !password.isEmpty else {
            showAlert("Please enter your password.")
            return
        }
        
        loginActionButton?.isEnabled = false
        loginActionButton?.setTitle("  Signing In...", for: .normal)
        
        AuthManager.shared.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loginActionButton?.isEnabled = true
                self.loginActionButton?.setTitle("  Sign In", for: .normal)
                
                switch result {
                case .success(let user):
                    FirestoreManager.shared.saveProfile(
                        name: user.displayName ?? "",
                        email: user.email ?? email
                    )
                    self.goToMainDashboard()
                case .failure(let error):
                    self.showAlert(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Reset Password",
            message: "Enter your account email address to receive a password reset link.",
            preferredStyle: .alert
        )
        alert.addTextField { [weak self] tf in
            tf.placeholder = "name@example.com"
            tf.keyboardType = .emailAddress
            tf.text = self?.emailText.text
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send Link", style: .default) { [weak self] _ in
            guard let email = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !email.isEmpty else {
                self?.showAlert("Please enter a valid email address.")
                return
            }
            AuthManager.shared.resetPassword(email: email) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.showInfoAlert(title: "Email Sent", message: "Check your inbox for instructions to reset your password.")
                    case .failure(let error):
                        self?.showAlert(error.localizedDescription)
                    }
                }
            }
        })
        present(alert, animated: true)
    }
    
    @IBAction func createAccountTapped(_ sender: UIButton) {
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        navigationController?.pushViewController(signUpVC, animated: true)
    }

    @IBAction func googleSignInTapped(_ sender: UIButton) {
        googleSignInButton.isEnabled = false
        googleSignInButton.setTitle("  Signing in...", for: .normal)

        AuthManager.shared.signInWithGoogle(presenting: self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.googleSignInButton.isEnabled = true
                self.googleSignInButton.setTitle("  Continue with Google", for: .normal)

                switch result {
                case .success(let user):
                    FirestoreManager.shared.saveProfile(
                        name:  user.displayName ?? "",
                        email: user.email ?? ""
                    )
                    self.goToMainDashboard()

                case .failure(let error):
                    self.showAlert(error.localizedDescription)
                }
            }
        }
    }

    func goToMainDashboard() {
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

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailText {
            paswordText.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
