//
//  ExpenseCell.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 10/06/2026.
//

import UIKit

class ExpenseCell: UITableViewCell {

    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        iconContainerView.layer.cornerRadius  = 22
        iconContainerView.clipsToBounds       = true
        selectionStyle                        = .none
        layer.cornerRadius                    = 12
        contentView.layer.cornerRadius        = 12
    }

    func configure(with expense: Expense) {
        titleLabel.text    = expense.title ?? ""
        amountLabel.text   = "-\(formatAmount(expense.amount)) PKR"
        amountLabel.textColor = .systemRed

        let category = expense.category ?? "Other"
        categoryLabel.text = category

        // Time
        if let date = expense.date {
            let formatter        = DateFormatter()
            formatter.dateFormat = "h:mm a"
            timeLabel.text       = formatter.string(from: date)
        }

        // Icon + color per category
        let (icon, color) = iconAndColor(for: category)
        iconImageView.image    = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconContainerView.backgroundColor = color.withAlphaComponent(0.15)
    }

    func iconAndColor(for category: String) -> (String, UIColor) {
        switch category {
        case "🍔 Food":        return ("fork.knife",          .systemOrange)
        case "🚗 Transport":   return ("car.fill",            .systemBlue)
        case "🛍 Shopping":    return ("bag.fill",            .systemPurple)
        case "💊 Health":      return ("cross.fill",          .systemPink)
        case "🎮 Entertainment": return ("gamecontroller.fill", .systemIndigo)
        case "📚 Education":   return ("book.fill",           .systemGreen)
        case "🏠 Rent":        return ("house.fill",          .systemTeal)
        case "⚡ Utilities":   return ("bolt.fill",           .systemYellow)
        default:               return ("plus.circle.fill",    .systemGray)
        }
    }

    func formatAmount(_ amount: Double) -> String {
        let formatter                   = NumberFormatter()
        formatter.numberStyle           = .decimal
        formatter.groupingSeparator     = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}
