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
        titleTextField.text  = expense.title
        amountTextField.text = String(format: "%.0f", expense.amount)
        noteTextField.text   = expense.note
        selectedCategory     = expense.category
        if let date = expense.date { datePicker.date = date }
        categoryCollectionView.reloadData()
    }
    
    @objc func dismissKeyboard() {
            view.endEditing(true)
        }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        
        guard let title = titleTextField.text, !title.isEmpty else {
                showAlert("Please enter a title")
                return
            }
            guard let amountText = amountTextField.text,
                  let amount = Double(amountText), amount > 0 else {
                showAlert("Please enter a valid amount")
                return
            }
            guard let category = selectedCategory else {
                showAlert("Please select a category")
                return
            }

            let note = noteTextField.text ?? ""
            let date = datePicker.date

            if isEditMode {
                // ✅ Update
                CoreDataManager.shared.updateExpense(
                    expenseToEdit!,
                    title: title,
                    amount: amount,
                    category: category,
                    note: note
                )
                navigationController?.popViewController(animated: true)

            } else {
                // ✅ Add new
                let remaining = CoreDataManager.shared.remainingBalance()
                if amount > remaining {
                    showOverBudgetAlert(amount: amount, remaining: remaining) {
                        CoreDataManager.shared.createExpense(
                            title: title,
                            amount: amount,
                            category: category,
                            note: note,
                            date: date
                        )
                        self.tabBarController?.selectedIndex = 0
                    }
                    return
                }

                CoreDataManager.shared.createExpense(
                    title: title,
                    amount: amount,
                    category: category,
                    note: note,
                    date: date
                )
                tabBarController?.selectedIndex = 0
            }
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
            let message = "This expense (Rs \(String(format: "%.0f", amount))) exceeds your remaining balance (Rs \(String(format: "%.0f", remaining))). Add anyway?"
            let alert = UIAlertController(title: "⚠️ Over Budget", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Add Anyway", style: .destructive) { _ in
                onConfirm()
            })
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
