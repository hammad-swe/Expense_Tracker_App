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
    @IBOutlet weak var currencyButton: UIButton?
    @IBOutlet weak var darkModeSwitch: UISwitch?
    @IBOutlet weak var memberBadgeButton: UIButton?
    
    private let currencyCodes: [String] = ["PKR", "USD"]
    private let darkModeDefaultsKey = "isDarkModeEnabled"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCurrencyDropdown()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        setupCurrencyDropdown()
    }

    // MARK: - Setup
    func setupUI() {
        title = "Profile"
        view.backgroundColor = .systemGroupedBackground
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let isDark: Bool
            if UserDefaults.standard.object(forKey: darkModeDefaultsKey) != nil {
                isDark = UserDefaults.standard.bool(forKey: darkModeDefaultsKey)
                window.overrideUserInterfaceStyle = isDark ? .dark : .light
            } else {
                isDark = traitCollection.userInterfaceStyle == .dark
            }
            darkModeSwitch?.isOn = isDark
        }
    }
    
    private func setupCurrencyDropdown() {
        guard let currencyButton = currencyButton else { return }
        let selectedCode = CurrencyManager.shared.selectedCurrencyCode
        let shortDisplay = selectedCode == "USD" ? "USD ($)" : "PKR (Rs)"
        currencyButton.setTitle(shortDisplay, for: .normal)
        
        let actions = currencyCodes.map { code in
            let option = CurrencyManager.shared.currencyOption(forCode: code)
            return UIAction(
                title: option.full,
                state: code == selectedCode ? .on : .off
            ) { [weak self] _ in
                CurrencyManager.shared.setSelectedCurrency(code)
                self?.setupCurrencyDropdown()
            }
        }
        currencyButton.menu = UIMenu(title: "Select Display Currency", options: .displayInline, children: actions)
        currencyButton.showsMenuAsPrimaryAction = true
    }

    func updateUI() {
        if AuthManager.shared.isLoggedIn {
            let user        = AuthManager.shared.currentUser
            let displayName = user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            nameLabel.text  = displayName.isEmpty ? "Verified User" : displayName
            emailLabel.text = user?.email ?? ""

            syncButton.isHidden    = false
            signOutButton.isHidden = false
            signInButton.isHidden  = true
            syncButton.setTitle("Sync Data", for: .normal)
            memberBadgeButton?.setTitle("  Verified Account", for: .normal)
        } else {
            nameLabel.text  = "Guest User"
            emailLabel.text = "Not signed in"

            syncButton.isHidden    = true
            signOutButton.isHidden = true
            signInButton.isHidden  = false
            memberBadgeButton?.setTitle("  Local Guest Mode", for: .normal)
        }
    }
    
    @IBAction func darkModeChanged(_ sender: UISwitch) {
        let style: UIUserInterfaceStyle = sender.isOn ? .dark : .light
        UserDefaults.standard.set(sender.isOn, forKey: darkModeDefaultsKey)
        
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
                        window.overrideUserInterfaceStyle = style
                    }
                }
            }
        }
    }
    
    @IBAction func exportTapped(_ sender: Any) {
        guard let pdfURL = PDFExportManager.shared.exportExpensesToPDF() else {
            showAlert("Failed to generate PDF")
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [pdfURL],
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(activityVC, animated: true)
    }

    // MARK: - Sync
    @IBAction func syncTapped(_ sender: UIButton) {
        guard AuthManager.shared.isLoggedIn else { return }

        syncButton.isEnabled = false
        syncButton.setTitle("Syncing...", for: .normal)

        if let budget = CoreDataManager.shared.fetchCurrentBudget() {
            FirestoreManager.shared.syncBudget(budget)
        }

        FirestoreManager.shared.syncAllExpenses { error in
            DispatchQueue.main.async {
                self.syncButton.isEnabled = true

                if let error = error {
                    self.syncButton.setTitle("Sync Failed", for: .normal)
                    print("Sync error: \(error.localizedDescription)")
                } else {
                    self.syncButton.setTitle("Synced", for: .normal)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.syncButton.setTitle("Sync Data", for: .normal)
                    }
                }
            }
        }
    }

    // MARK: - Sign In
    @IBAction func signInTapped(_ sender: UIButton) {
        let vc = LoginViewController(nibName: "LoginViewController", bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Sign Out
    @IBAction func signOutTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            AuthManager.shared.signOut()
            self.updateUI()
        })
        present(alert, animated: true)
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
