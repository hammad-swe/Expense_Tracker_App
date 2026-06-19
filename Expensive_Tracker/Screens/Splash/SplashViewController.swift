//
//  SplashViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 01/06/2026.
//

import UIKit
import GoogleMobileAds

class SplashViewController: UIViewController {
    
    @IBOutlet weak var logoicon: UIImageView!
    override func viewDidLoad() {
            super.viewDidLoad()
        
        MobileAds.shared.start(completionHandler: nil)
            AppOpenAdManager.shared.loadAd()
            InterstitialAdManager.shared.loadAd()
            startSplashTimer()
        }

        private func startSplashTimer() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.navigateToNextScreen()
            }
        }

        private func navigateToNextScreen() {
            AppOpenAdManager.shared.showAdIfAvailable(from: self) { [weak self] in
                self?.proceedToNextScreen()
            }
        }

        private func proceedToNextScreen() {
            let nextVC: UIViewController

            if CoreDataManager.shared.fetchCurrentBudget() != nil {
                nextVC = MainTabBarController()
            } else {
                nextVC = SetBudgetViewController(nibName: "SetBudgetViewController", bundle: nil)
            }

            navigationController?.setViewControllers([nextVC], animated: true)
        }
    }
