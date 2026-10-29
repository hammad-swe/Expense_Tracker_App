//
//  Theme.swift
//  Expensive_Tracker
//
//  Created on 29/10/2026.
//

import UIKit

enum Theme {
    
    // MARK: - Brand & Semantic Colors
    
    static let primaryIndigo = UIColor(red: 0.31, green: 0.27, blue: 0.90, alpha: 1.0) // #4F46E5
    static let primaryPurple = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1.0) // #7C3AED
    static let accentViolet  = UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1.0) // #8B5CF6
    
    static let emeraldGreen  = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0) // #10B981
    static let amberOrange   = UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0) // #F59E0B
    static let coralRed      = UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1.0) // #EF4444
    
    static let screenBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.07, blue: 0.11, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
    }
    
    static let cardBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.13, blue: 0.19, alpha: 1.0)
            : UIColor.white
    }
    
    static let subtleBorderColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.05)
    }
    
    // MARK: - Gradients
    
    static var heroGradientColors: [CGColor] {
        [
            UIColor(red: 0.26, green: 0.22, blue: 0.79, alpha: 1.0).cgColor,
            UIColor(red: 0.43, green: 0.16, blue: 0.85, alpha: 1.0).cgColor,
            UIColor(red: 0.58, green: 0.20, blue: 0.92, alpha: 1.0).cgColor
        ]
    }
    
    static var overBudgetGradientColors: [CGColor] {
        [
            UIColor(red: 0.75, green: 0.12, blue: 0.24, alpha: 1.0).cgColor,
            UIColor(red: 0.90, green: 0.22, blue: 0.27, alpha: 1.0).cgColor
        ]
    }
    
    // MARK: - Greeting Helper
    
    static func timeBasedGreeting() -> (greeting: String, icon: String) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return ("Good Morning", "sun.max.fill")
        case 12..<17:
            return ("Good Afternoon", "sun.haze.fill")
        case 17..<21:
            return ("Good Evening", "moon.stars.fill")
        default:
            return ("Good Night", "moon.zzz.fill")
        }
    }
    
    static func currentMonthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}

extension UIView {
    func applyElevatedCardStyle(cornerRadius: CGFloat = 20, shadowOpacity: Float = 0.06, shadowRadius: CGFloat = 14) {
        backgroundColor = Theme.cardBackground
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = shadowRadius
        layer.borderWidth = 1
        layer.borderColor = Theme.subtleBorderColor.cgColor
    }
}
