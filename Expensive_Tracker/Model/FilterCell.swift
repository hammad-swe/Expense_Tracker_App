//
//  FilterCell.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 10/06/2026.
//

import UIKit

class FilterCell: UICollectionViewCell {

    private let titleLabel: UILabel = {
        let label           = UILabel()
        label.font          = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    func setupCell() {
        contentView.addSubview(titleLabel)
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth  = 1.5
        contentView.clipsToBounds      = true

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            contentView.backgroundColor   = .systemBlue
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
            titleLabel.textColor          = .white
        } else {
            contentView.backgroundColor   = .systemBackground
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
            titleLabel.textColor          = .label
        }
    }
}
