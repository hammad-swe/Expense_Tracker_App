//
//  LoginViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 12/06/2026.
//

import UIKit

class LoginViewController: UIViewController {
    
    
    @IBOutlet weak var emailStack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

  private func setUpUI(){
      emailStack.layer.cornerRadius = 10
      emailStack.layer.borderWidth = 1
      emailStack.layer.borderColor = UIColor.gray.cgColor
    }

}
