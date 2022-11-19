//
//  VoiceMailCell.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//

import UIKit

final class VoiceMailCell: UICollectionViewCell {

    static let reuseId = String(describing: VoiceMailCell.self)

    private lazy var accessoryIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .label
        return label
    }()

    private lazy var countryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(accessoryIcon)
        NSLayoutConstraint.activate([
            accessoryIcon.widthAnchor.constraint(equalToConstant: Constants.accessorySize),
            accessoryIcon.heightAnchor.constraint(equalToConstant: Constants.accessorySize),
            accessoryIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            accessoryIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15)
        ])
        let stackView = UIStackView(arrangedSubviews: [nameLabel, countryLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 34),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8)
        ])
        contentView.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
            timeLabel.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 12)
        ])
    }

    func configure(with viewModel: ViewModel) {
        nameLabel.text = viewModel.name
        countryLabel.text = viewModel.country
        countryLabel.isHidden = viewModel.country?.isEmpty ?? true
        timeLabel.text = viewModel.callTime
        accessoryIcon.isHidden = viewModel.accessoryHidden
        accessoryIcon.image = .init(named: viewModel.accessoryIconTitle)
        nameLabel.textColor = viewModel.nameColor
    }

}
extension VoiceMailCell {

    struct ViewModel {
        let name: String?
        var country: String?
        let callTime: String?
        var accessoryHidden: Bool
        var accessoryIconTitle = Constants.outgoingIconTitle
        let nameColor: UIColor
    }

}
private enum Constants {
    static let outgoingIconTitle = "outgoing"
    static let accessorySize: CGFloat = 16
}
