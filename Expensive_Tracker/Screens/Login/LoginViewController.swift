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
    
    
    
    override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
        }

        func setupUI() {
            title = "Sign In"

            googleSignInButton.layer.cornerRadius = 12
            googleSignInButton.backgroundColor    = .white
            googleSignInButton.layer.borderWidth  = 1.5
            googleSignInButton.layer.borderColor  = UIColor.systemGray4.cgColor
            googleSignInButton.setTitleColor(.label, for: .normal)
            googleSignInButton.titleLabel?.font   = .systemFont(ofSize: 16, weight: .medium)
            googleSignInButton.setTitle("  Sign in with Google", for: .normal)
            googleSignInButton.setImage(UIImage(systemName: "g.circle.fill"), for: .normal)
            googleSignInButton.tintColor          = .systemRed
        }

    @IBAction func googleSignInTapped(_ sender: UIButton) {
        googleSignInButton.isEnabled = false
        googleSignInButton.setTitle("  Signing in...", for: .normal)

        AuthManager.shared.signInWithGoogle(presenting: self) { result in
            DispatchQueue.main.async {
                self.googleSignInButton.isEnabled = true
                self.googleSignInButton.setTitle("  Sign in with Google", for: .normal)

                switch result {
                case .success(let user):
                    // ✅ Save profile to Firestore
                    FirestoreManager.shared.saveProfile(
                        name:  user.displayName ?? "",
                        email: user.email ?? ""
                    )
                    // ✅ Go to main tab bar
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

            // ✅ Smooth transition
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
    }
    
