//
//  SetBudgetViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 02/06/2026.
//

import UIKit

class SetBudgetViewController: UIViewController {
    
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var uiStepper: UIStepper!
    @IBOutlet weak var Stack1: UIStackView!
    @IBOutlet weak var currencyStack: UIStackView!
    @IBOutlet weak var messageStack: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    
    @IBOutlet weak var currencyButton: UIButton!
    
    var isEditingBudget = false

        // ✅ which currency codes this screen's dropdown supports (real ISO codes)
        private let currencyCodes: [String] = ["PKR", "USD"]

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Set Monthly Budget"
            setupUI()
            setupCurrencyMenu() // build immediately with fallback names, no network wait

            CurrencyManager.shared.fetchSupportedCurrencyNames { [weak self] in
                self?.setupCurrencyMenu() // quietly rebuild with live names if fetch succeeded
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            updateCurrencyUI()
        }

        func setupUI() {
            Stack1.layer.cornerRadius = 10
            currencyStack.layer.cornerRadius = 10
            messageStack.layer.cornerRadius = 10

            uiStepper.minimumValue = 0
            uiStepper.maximumValue = 500000
            uiStepper.stepValue = 1

            amountTextField.text = "0"
            amountTextField.textAlignment = .left
            amountTextField.layer.borderWidth = 1.5
            amountTextField.layer.cornerRadius = 8
            amountTextField.layer.borderColor = UIColor.systemIndigo.cgColor
            amountTextField.font = UIFont.systemFont(ofSize: 40, weight: .light)
            amountTextField.keyboardType = .numberPad
            amountTextField.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                amountTextField.widthAnchor.constraint(equalToConstant: 180)
            ])

            if let budget = CoreDataManager.shared.fetchCurrentBudget() {
                isEditingBudget = true
                titleLabel.text = "Edit Budget"
                // ✅ budget.totalAmount is ALWAYS stored in PKR — convert it for display in current selection
                let displayValue = CurrencyManager.shared.displayAmount(forPKRAmount: budget.totalAmount)
                amountTextField.text = String(format: "%.2f", displayValue)
                saveButton.setTitle("Update Budget", for: .normal)
            } else {
                titleLabel.text = "Set Your Budget"
            }
        }

        // ✅ Builds the dropdown menu using real ISO codes; checkmark follows CurrencyManager's current selection
        func setupCurrencyMenu() {
            let actions = currencyCodes.map { code in
                let option = CurrencyManager.shared.currencyOption(forCode: code)
                return UIAction(
                    title: option.full,
                    state: code == CurrencyManager.shared.selectedCurrencyCode ? .on : .off
                ) { [weak self] _ in
                    self?.handleCurrencySelected(code: code, fullTitle: option.full)
                }
            }

            currencyButton.menu = UIMenu(title: "", options: .displayInline, children: actions)
            currencyButton.showsMenuAsPrimaryAction = true
            updateCurrencyUI()
        }

        private func handleCurrencySelected(code newCode: String, fullTitle: String) {
            let oldCode = CurrencyManager.shared.selectedCurrencyCode
            print("🟢 handleCurrencySelected: tapped=\(newCode), oldCode=\(oldCode), textField=\(amountTextField.text ?? "nil")")

            guard newCode != oldCode else {
                print("🔴 Same currency as current selection — exiting early, nothing will change")
                return
            }

            guard let text = amountTextField.text, let typedAmount = Double(text), typedAmount > 0 else {
                print("🔴 Could not parse text field as a valid Double > 0 — only switching label, NOT converting")
                CurrencyManager.shared.setSelectedCurrency(newCode)
                updateCurrencyUI()
                setupCurrencyMenu()
                return
            }

            print("🟢 Parsed amount: \(typedAmount), fetching live rate...")
            CurrencyManager.shared.fetchRate { [weak self] in
                guard let self = self else { return }

                let pkrAmount = CurrencyManager.shared.convertToPKR(typedAmount, from: oldCode)
                CurrencyManager.shared.setSelectedCurrency(newCode)
                let convertedDisplay = CurrencyManager.shared.convertFromPKR(pkrAmount, to: newCode)

                print("🟢 Converted: \(typedAmount) \(oldCode) -> \(pkrAmount) PKR -> \(convertedDisplay) \(newCode)")

                self.amountTextField.text = String(format: "%.2f", convertedDisplay)
                self.updateCurrencyUI()
                self.setupCurrencyMenu()
            }
        }

        private func updateCurrencyUI() {
            let code = CurrencyManager.shared.selectedCurrencyCode
            let option = CurrencyManager.shared.currencyOption(forCode: code)
            currencyButton.setTitle(option.full, for: .normal)
            currencyLabel.text = code == "USD" ? "US" : code // display-only shorthand, never used for math
        }

        @IBAction func stepperValuetapped(_ sender: UIStepper) {
            amountTextField.text = "\(Int(sender.value))"
        }

        @IBAction func saveTapped(_ sender: Any) {
            guard let text = amountTextField.text,
                  let amount = Double(text), amount > 0 else {
                showAlert("Please enter a valid amount")
                return
            }

            // ✅ ALWAYS convert back to PKR before saving — this is what gets uploaded to Firestore too
            let pkrAmount = CurrencyManager.shared.convertToPKR(amount, from: CurrencyManager.shared.selectedCurrencyCode)
            print("🟢 saveTapped: textField=\(amount), selectedCurrency=\(CurrencyManager.shared.selectedCurrencyCode), saving PKR=\(pkrAmount)")
            CoreDataManager.shared.saveOrUpdateBudget(amount: pkrAmount)

            if isEditingBudget {
                
                InterstitialAdManager.shared.showAdIfAvailable(from: self) { [weak self] in
                    self?.navigationController?.popViewController(animated: false)
                    self?.tabBarController?.selectedIndex = 0
                        }
            } else {
                
                InterstitialAdManager.shared.showAdIfAvailable(from: self) { [weak self] in
                            let vc = DashBoardViewController()
                            self?.navigationController?.setViewControllers([vc], animated: true)
                        }
            }
        }

        func showAlert(_ message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
