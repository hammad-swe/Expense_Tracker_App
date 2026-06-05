//
//  DashBoardViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 02/06/2026.
//

import UIKit

class DashBoardViewController: UIViewController {
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var card1: UIStackView!
    @IBOutlet weak var card2: UIStackView!
    @IBOutlet weak var card3: UIStackView!
    @IBOutlet weak var addbutton: UIButton!
    @IBOutlet weak var viewallButton: UIButton!
    @IBOutlet weak var dashBoardTable: UITableView!
    @IBOutlet weak var totalBudgetLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setupCardTap()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showBudget() // ✅ Refreshes every time you come back to dashboard
    }
    
    func showBudget() {
        if let budget = CoreDataManager.shared.fetchCurrentBudget() {
            totalBudgetLabel.text = "Rs \(String(format: "%.0f", budget.totalAmount))"
        } else {
            totalBudgetLabel.text = "No Budget Set"
        }
    }
    
    func setupCardTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        card1.addGestureRecognizer(tap)
        card1.isUserInteractionEnabled = true // crucial!
    }

    @objc func cardTapped() {
        let VC = SetBudgetViewController() // or load from XIB
        VC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(VC, animated: true)
    }
    
    private func setUpUI(){
        title = "Dashboard"
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        card1.layer.cornerRadius = 12
        card2.layer.cornerRadius = 12
        card3.layer.cornerRadius = 12
        styleButton()
    }
    
    private func styleButton() {
        addbutton.layer.cornerRadius =   addbutton.frame.height / 2
        addbutton.layer.masksToBounds = true
        addbutton.backgroundColor = .blue
        addbutton.setImage(UIImage(systemName: "plus"), for: .normal)
        addbutton.tintColor = .systemBlue
       }
    
    
    @IBAction func addTapped(_ sender: UIButton) {
        
        let vc = AddExpenseViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    @IBAction func viewAllTapped(_ sender: Any) {
        let VC = ExpenseListViewController()
        VC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(VC, animated: true)
    }
    
    
    
}
