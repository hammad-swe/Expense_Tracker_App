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
        let vc = GetStartViewController()
        self.navigationController?.setViewControllers([vc], animated: true)
    }
}
