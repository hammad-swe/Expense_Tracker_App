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
    @IBOutlet weak var cellContainer: UIStackView!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        iconContainerView.layer.cornerRadius = iconContainerView.frame.width / 2
    }

    func setupUI() {
        iconContainerView.layer.cornerRadius  = iconContainerView.frame.width / 2
        iconContainerView.clipsToBounds       = true
        
        iconImageView.contentMode = .scaleAspectFit
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
                iconImageView.widthAnchor.constraint(equalToConstant: 22),
                iconImageView.heightAnchor.constraint(equalToConstant: 22),
                iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
                iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor)
            ])
        
        selectionStyle                        = .none
        layer.cornerRadius                    = 12
        contentView.layer.cornerRadius        = 12
        cellContainer.backgroundColor    = .white
        cellContainer.layer.cornerRadius = 10
        cellContainer.layer.shadowColor  = UIColor.black.cgColor
        cellContainer.layer.shadowOpacity = 0.1
        cellContainer.layer.shadowOffset  = CGSize(width: 0, height: 0)
        cellContainer.layer.shadowRadius  = 4
    }

    func configure(with expense: Expense) {
        titleLabel.text = expense.title ?? ""

            // ✅ Use your actual CurrencyManager method
            let formattedAmount = CurrencyManager.shared.displayString(forPKRAmount: expense.amount)
            amountLabel.text       = "-\(formattedAmount)"
            amountLabel.textColor  = .systemRed

            let category = expense.category ?? "Other"
            categoryLabel.text = category

            if let date = expense.date {
                let formatter        = DateFormatter()
                formatter.dateFormat = "h:mm a"
                timeLabel.text       = formatter.string(from: date)
            }

            let (icon, color) = iconAndColor(for: category)
            iconImageView.image     = UIImage(systemName: icon)
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
