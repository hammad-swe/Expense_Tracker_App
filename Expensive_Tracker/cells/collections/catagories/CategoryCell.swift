//
//  CategoryCell.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 08/06/2026.
//

import UIKit

class CategoryCell: UICollectionViewCell {

    // MARK: - Outlet
    @IBOutlet weak var titleLabel: UILabel!
    
    static let identifier = "CategoryCell"

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }

    // MARK: - Setup
    func setupCell() {
        contentView.layer.cornerRadius = 14
        contentView.clipsToBounds      = true
    }

    // MARK: - Configure
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.adjustsFontSizeToFitWidth = true

        if isSelected {
            contentView.backgroundColor   = Theme.primaryIndigo
            contentView.layer.borderWidth = 0
            titleLabel.textColor          = .white
        } else {
            contentView.backgroundColor   = .tertiarySystemFill
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = Theme.subtleBorderColor.cgColor
            titleLabel.textColor          = .label
        }
    }
}
