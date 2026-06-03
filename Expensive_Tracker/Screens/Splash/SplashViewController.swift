//
//  SplashViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 01/06/2026.
//

import UIKit

class SplashViewController: UIViewController {
    
    @IBOutlet weak var logoicon: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        startSplashTimer()
        // Do any additional setup after loading the view.
    }
    
    private func startSplashTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.navigateToNextScreen()
            
        }
        
    }
    
    private func navigateToNextScreen() {
        let nextVC: UIViewController

               if CoreDataManager.shared.fetchCurrentBudget() != nil {
                   // ✅ Budget exists → go to TabBar
                   nextVC = MainTabBarController()
               } else {
                   // ✅ No budget → set budget first
                   nextVC = SetBudgetViewController(nibName: "SetBudgetViewController", bundle: nil)
               }

               navigationController?.setViewControllers([nextVC], animated: true)
    }
}
