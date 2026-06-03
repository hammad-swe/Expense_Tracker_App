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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        
    }
    
    private func setUpUI(){
        title = "Dashboard"
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
}
