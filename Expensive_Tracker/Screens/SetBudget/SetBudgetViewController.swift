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
    
    var isEditingBudget = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Set Monthly Budget"
        setupUI()
    }

    func setupUI() {
        
        Stack1.layer.cornerRadius = 10
        currencyStack.layer.cornerRadius = 10
        messageStack.layer.cornerRadius = 10
        
        uiStepper.minimumValue = 0
        uiStepper.maximumValue = 500000
        uiStepper.stepValue = 100
        
        
        amountTextField.text = "0"
       // amountTextField.layer.borderWidth = 1.5
       // amountTextField.layer.cornerRadius = 8
      //  amountTextField.layer.borderColor = UIColor.systemIndigo.cgColor

        amountTextField.font = UIFont.systemFont(ofSize: 40, weight: .light)
        amountTextField.keyboardType = .numberPad
        
            if let budget = CoreDataManager.shared.fetchCurrentBudget() {
                // ✅ Edit mode
                isEditingBudget = true
                titleLabel.text        = "Edit Budget"
                amountTextField.text   = String(format: "%.0f", budget.totalAmount)
                saveButton.setTitle("Update Budget", for: .normal)
            } else {
                // ✅ New budget mode
                titleLabel.text = "Set Your Budget"
               // saveButton.setTitle("Save Budget", for: .normal)
            }
        }
    

    @IBAction func stepperValuetapped(_ sender: UIStepper) {
        amountTextField.text = "\(Int(sender.value))"
        
    }
    
    
    @IBAction func saveTapped(_ sender: Any) {
        
        guard let text   = amountTextField.text,
        let amount = Double(text), amount > 0 else {
         showAlert("Please enter a valid amount")
        return   }
                
        CoreDataManager.shared.saveOrUpdateBudget(amount: amount)
                if isEditingBudget{
                    // Go back to home
                    navigationController?.popViewController(animated: true)
                } else {
                    // First time — go to home
                    let VC = DashBoardViewController()
                    navigationController?.setViewControllers([VC], animated: true)
                }
    }
    
    func showAlert(_ message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

}
