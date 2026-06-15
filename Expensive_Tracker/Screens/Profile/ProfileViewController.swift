//
//  ProfileViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 03/06/2026.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            updateUI()
        }

        // MARK: - Setup
        func setupUI() {
            title = "Profile"
        }


            func updateUI() {
                if AuthManager.shared.isLoggedIn {
                    let user        = AuthManager.shared.currentUser
                    nameLabel.text  = user?.displayName ?? "User"
                    emailLabel.text = user?.email ?? ""

                    syncButton.isHidden    = false
                    signOutButton.isHidden = false
                    signInButton.isHidden  = true
                    syncButton.setTitle("Sync Data", for: .normal)

                } else {
                    nameLabel.text  = "Guest User"
                    emailLabel.text = "Not signed in"

                    syncButton.isHidden    = true
                    signOutButton.isHidden = true
                    signInButton.isHidden  = false
                }
            }

        // MARK: - Sync
        @IBAction func syncTapped(_ sender: UIButton) {
            guard AuthManager.shared.isLoggedIn else { return }

            // ✅ Show syncing state
            syncButton.isEnabled = false
            syncButton.setTitle("Syncing...", for: .normal)

            if let budget = CoreDataManager.shared.fetchCurrentBudget() {
                FirestoreManager.shared.syncBudget(budget)
            }

            FirestoreManager.shared.syncAllExpenses { error in
                DispatchQueue.main.async {
                    self.syncButton.isEnabled = true

                    if let error = error {
                        // ✅ Show failed in button
                        self.syncButton.setTitle("Sync Failed ❌", for: .normal)
                        print("Sync error: \(error.localizedDescription)")
                    } else {
                        // ✅ Show success in button
                        self.syncButton.setTitle("Synced ✅", for: .normal)

                        // Reset back to "Sync Data" after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.syncButton.setTitle("Sync Data", for: .normal)
                        }
                    }
                }
            }
        }
    
    

    

        // MARK: - Sign In
        @IBAction func signInTapped(_ sender: UIButton) {
            let vc = LoginViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }

        // MARK: - Sign Out
        @IBAction func signOutTapped(_ sender: UIButton) {
            let alert = UIAlertController(
                title: "Sign Out",
                message: "Are you sure?",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
                AuthManager.shared.signOut()
                self.updateUI()
            })
            present(alert, animated: true)
        }
    }
