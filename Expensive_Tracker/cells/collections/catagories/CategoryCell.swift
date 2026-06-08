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
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth  = 1.5
        contentView.clipsToBounds      = true
    }

    // MARK: - Configure
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title

        if isSelected {
            contentView.backgroundColor   = .systemBlue
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
            titleLabel.textColor          = .white
        } else {
            contentView.backgroundColor   = .systemGray6
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
            titleLabel.textColor          = .label
        }
    }
}
