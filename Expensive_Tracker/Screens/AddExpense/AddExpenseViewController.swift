//
//  AddExpenseViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 03/06/2026.
//

import UIKit

class AddExpenseViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var currencyLabel: UILabel!
    
    
    
    let categories = ["🍔 Food", "🚗 Transport", "🛍 Shopping", "💊 Health",
                      "🎮 Entertainment", "📚 Education", "🏠 Rent", "⚡ Utilities", "Other"]
    
    var selectedCategory: String?
    
    var expenseToEdit: Expense?
    var isEditMode: Bool { return expenseToEdit != nil }
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupCollectionView()
        
        if isEditMode {
            populateData()
        }
        
        // Set delegate for all text fields
                titleTextField.delegate = self
                amountTextField.delegate = self
                noteTextField.delegate = self

                // Tap anywhere on screen → hide keyboard
                let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                tap.cancelsTouchesInView = false
                view.addGestureRecognizer(tap)
        
        updateCurrencyLabel()

            // ✅ Listen for currency changes while this screen is open
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateCurrencyLabel),
                name: CurrencyManager.notificationName,
                object: nil
            )
        
    }
    
    func setupUI() {
        func setupUI() {
            if isEditMode {
                title = "Edit Expense"

                navigationItem.rightBarButtonItem = UIBarButtonItem(
                    title: "Delete",
                    style: .plain,
                    target: self,
                    action: #selector(deleteTapped)
                )
                navigationItem.rightBarButtonItem?.tintColor = .systemRed
            } else {
                title = "Add Expense"
            }
        }
    }
    
    func setupCollectionView() {
        categoryCollectionView.delegate   = self
        categoryCollectionView.dataSource = self
        
        
        let nib = UINib(nibName: "CategoryCell", bundle: nil)
        categoryCollectionView.register(nib, forCellWithReuseIdentifier: "CategoryCell")
        
        // Flow layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection       = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing    = 8
        layout.estimatedItemSize     = UICollectionViewFlowLayout.automaticSize
        categoryCollectionView.collectionViewLayout = layout
        categoryCollectionView.showsHorizontalScrollIndicator = false
    }
    
    // ✅ Fill fields with existing expense data
    func populateData() {
        guard let expense = expenseToEdit else { return }
        titleTextField.text = expense.title

        // ✅ Convert stored PKR amount to currently selected currency for display/editing
        let displayAmount = CurrencyManager.shared.displayAmount(forPKRAmount: expense.amount)
        amountTextField.text = String(format: "%.0f", displayAmount)

        noteTextField.text = expense.note
        selectedCategory   = expense.category
        if let date = expense.date { datePicker.date = date }
        categoryCollectionView.reloadData()
    }
    
    @objc func dismissKeyboard() {
            view.endEditing(true)
        }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateCurrencyLabel() {
        let code = CurrencyManager.shared.selectedCurrencyCode
        let option = CurrencyManager.shared.currencyOption(forCode: code)
        currencyLabel.text = option.short          // e.g. "USD" or "PKR"
        amountTextField.placeholder = "Amount (\(option.short))"
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        
        guard let title = titleTextField.text, !title.isEmpty else {
                showAlert("Please enter a title")
                return
            }
            guard let amountText = amountTextField.text,
                  let enteredAmount = Double(amountText), enteredAmount > 0 else {
                showAlert("Please enter a valid amount")
                return
            }
            guard let category = selectedCategory else {
                showAlert("Please select a category")
                return
            }

            let note = noteTextField.text ?? ""
            let date = datePicker.date

            let amount = CurrencyManager.shared.convertToPKR(
                enteredAmount,
                from: CurrencyManager.shared.selectedCurrencyCode
            )

            if isEditMode {
                // ✅ Edit — no rewarded ad, just save and pop
                CoreDataManager.shared.updateExpense(
                    expenseToEdit!,
                    title: title,
                    amount: amount,
                    category: category,
                    note: note
                )
                InterstitialAdManager.shared.showAdIfAvailable(from: self) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }

            } else {
                // ✅ Add new
                let remaining = CoreDataManager.shared.remainingBalance()

                if amount > remaining {
                    showOverBudgetAlert(amount: amount, remaining: remaining) { [weak self] in
                        self?.proceedToSave(title: title, amount: amount, category: category, note: note, date: date)
                    }
                    return
                }

                proceedToSave(title: title, amount: amount, category: category, note: note, date: date)
            }
    }
    
    private func proceedToSave(title: String, amount: Double, category: String, note: String, date: Date) {
        let count = todayExpenseCount()
        print("💾 Today's expense count: \(count)")

        if count >= 3 {
            // 4th expense onward → show rewarded ad before saving
            RewardedAdManager.shared.showAdIfAvailable(from: self) { [weak self] in
                self?.saveExpenseAndNavigate(title: title, amount: amount, category: category, note: note, date: date)
            }
        } else {
            // First 3 expenses of the day → save freely
            saveExpenseAndNavigate(title: title, amount: amount, category: category, note: note, date: date)
        }
    }

    private func todayExpenseCount() -> Int {
        let expenses = CoreDataManager.shared.fetchTodayExpenses()
        return expenses.count
    }
    
    private func showRewardedAdThenSave(title: String, amount: Double, category: String, note: String, date: Date) {
        // Show alert first so user knows why the ad is appearing
        let alert = UIAlertController(
            title: "Watch a short ad",
            message: "Watch a 30-second ad to complete saving your expense.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Watch Ad", style: .default) { [weak self] _ in
            guard let self = self else { return }
            RewardedAdManager.shared.showAdIfAvailable(from: self) { [weak self] in
                self?.saveExpenseAndNavigate(title: title, amount: amount, category: category, note: note, date: date)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func saveExpenseAndNavigate(title: String, amount: Double, category: String, note: String, date: Date) {
        CoreDataManager.shared.createExpense(
            title: title,
            amount: amount,
            category: category,
            note: note,
            date: date
        )
        navigationController?.popViewController(animated: false)
        tabBarController?.selectedIndex = 0
    }
        
        // MARK: - Delete
    @objc func deleteTapped() {
            let alert = UIAlertController(
                title: "Delete Expense",
                message: "Are you sure you want to delete this expense?",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                guard let expense = self.expenseToEdit else { return }
                CoreDataManager.shared.deleteExpense(expense)
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
        
        
        
        // MARK: - Alerts
        func showAlert(_ message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        
        // Warn if over budget but still allow saving
        func showOverBudgetAlert(amount: Double, remaining: Double, onConfirm: @escaping () -> Void) {
            let amountStr    = CurrencyManager.shared.displayString(forPKRAmount: amount)
                let remainingStr = CurrencyManager.shared.displayString(forPKRAmount: remaining)
                let message = "This expense (\(amountStr)) exceeds your remaining balance (\(remainingStr)). Add anyway?"
                let alert = UIAlertController(title: "⚠️ Over Budget", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Add Anyway", style: .destructive) { _ in onConfirm() })
                present(alert, animated: true)
        }
        
        
    }
    
    extension AddExpenseViewController: UICollectionViewDataSource, UICollectionViewDelegate {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return  categories.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            print("✅ Cell loading at index: \(indexPath.item)")
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "CategoryCell",
                for: indexPath
            ) as! CategoryCell
            
            let category = categories[indexPath.item]
            let isSelected = category == selectedCategory
            cell.configure(title: category, isSelected: isSelected)
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView,
                            didSelectItemAt indexPath: IndexPath) {
            selectedCategory = categories[indexPath.item]
            categoryCollectionView.reloadData() // Refresh to show selection
        }
    }

extension AddExpenseViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case titleTextField:
            amountTextField.becomeFirstResponder()   // move focus to next field
        case amountTextField:
            noteTextField.becomeFirstResponder()     // move focus to next field
        case noteTextField:
            textField.resignFirstResponder()         // last field → close keyboard
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
