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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Expense"
        
    }
    
    func setupCollectionView() {
            categoryCollectionView.delegate   = self
            categoryCollectionView.dataSource = self
            categoryCollectionView.register(
                CategoryCell.self,
                forCellWithReuseIdentifier: "CategoryCell"
            )

            // Flow layout
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection       = .horizontal
            layout.minimumInteritemSpacing = 8
            layout.minimumLineSpacing    = 8
            layout.estimatedItemSize     = UICollectionViewFlowLayout.automaticSize
            categoryCollectionView.collectionViewLayout = layout
            categoryCollectionView.showsHorizontalScrollIndicator = false
        }

    @IBAction func saveTapped(_ sender: UIButton) {
        // Validation
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

                //  Check if expense exceeds remaining balance
                let remaining = CoreDataManager.shared.remainingBalance()
                if amount > remaining {
                    showOverBudgetAlert(amount: amount, remaining: remaining) {
                        self.saveExpense(title: title, amount: amount,
                                         category: category, note: note, date: date)
                    }
                    return
                }

                saveExpense(title: title, amount: amount,
                            category: category, note: note, date: date)

    }
    
    func saveExpense(title: String, amount: Double,
                         category: String, note: String, date: Date) {

            CoreDataManager.shared.createExpense(
                title: title,
                amount: amount,
                category: category,
                note: note,
                date: date
            )

            // ✅ Navigate to expense list tab (index 1)
            tabBarController?.selectedIndex = 1
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
