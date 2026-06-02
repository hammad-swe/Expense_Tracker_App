//
//  GetStartViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 02/06/2026.
//

import UIKit

class GetStartViewController: UIViewController {

    
    @IBOutlet weak var getlogo: UIImageView!
    @IBOutlet weak var getImage: UIImageView!
    @IBOutlet weak var getButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getImage.layer.cornerRadius = 12
        // Do any additional setup after loading the view.
    }


    @IBAction func getButtonTapped(_ sender: Any) {
        let vc = SetBudgetViewController()
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    

}
