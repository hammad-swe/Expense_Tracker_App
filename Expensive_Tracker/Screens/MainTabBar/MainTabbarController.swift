//
//  MainTabbarController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 03/06/2026.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBarAppearance()
    }

    func setupTabs() {

        // ✅ Tab 1 — Dashboard
        let homeVC = DashBoardViewController(nibName: "DashBoardViewController", bundle: nil)
        homeVC.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // ✅ Tab 2 — Expenses
        let expenseVC = ExpenseListViewController(nibName: "ExpenseListViewController", bundle: nil)
        expenseVC.tabBarItem = UITabBarItem(
            title: "Expenses",
            image: UIImage(systemName: "list.bullet.rectangle"),
            selectedImage: UIImage(systemName: "list.bullet.rectangle.fill")
        )
        
        
        // ✅ Tab 3 — statistics
        let statsVC = statsViewController(nibName: "statsViewController", bundle: nil)
        statsVC.tabBarItem = UITabBarItem(
            title: "stats",
            image: UIImage(systemName: "chart.line.downtrend.xyaxis"),
            selectedImage: UIImage(systemName: "chart.line.downtrend.xyaxis.fill")
        )

        // ✅ Tab 3 — Add Expense
//        let addVC = AddExpenseViewController(nibName: "AddExpenseViewController", bundle: nil)
//        addVC.tabBarItem = UITabBarItem(
//            title: "Add",
//            image: UIImage(systemName: "plus.circle"),
//            selectedImage: UIImage(systemName: "plus.circle.fill")
//        )

//        // ✅ Tab 4 — Budget
//        let budgetVC = SetBudgetViewController(nibName: "SetBudgetViewController", bundle: nil)
//        budgetVC.tabBarItem = UITabBarItem(
//            title: "Budget",
//            image: UIImage(systemName: "creditcard"),
//            selectedImage: UIImage(systemName: "creditcard.fill")
//        )

        // ✅ Tab 5 — Profile (optional)
        let profileVC = ProfileViewController(nibName: "ProfileViewController", bundle: nil)
        profileVC.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        // Wrap each in NavController
        let tabs = [homeVC, expenseVC,statsVC, profileVC].map {
            UINavigationController(rootViewController: $0)
        }

        viewControllers = tabs
    }

    func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground

        // Selected color
        tabBar.tintColor = .systemBlue

        // Unselected color
        tabBar.unselectedItemTintColor = .systemGray

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}

