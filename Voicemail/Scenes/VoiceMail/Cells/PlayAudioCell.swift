//
//  PlayAudioCell.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//

import UIKit

final class PlayAudioCell: UICollectionViewCell {

    static let reuseId = String(describing: PlayAudioCell.self)

    private lazy var mainView = PlayAudioView()

    var slider: UISlider {
        mainView.slider
    }

    var playButtonSelected: Bool {
        get { mainView.playButtonSelected }
        set { mainView.playButtonSelected = newValue }
    }

    var onPlay: ((Bool, UISlider) -> Void)? {
        get { mainView.onPlay }
        set { mainView.onPlay = newValue }
    }
    
    var onBackward: (() -> Void)? {
        get { mainView.onBackward }
        set { mainView.onBackward = newValue }
    }
    
    var onForward: (() -> Void)? {
        get { mainView.onForward }
        set { mainView.onForward = newValue }
    }
    
    var onRemove: (() -> Void)? {
        get { mainView.onRemove }
        set { mainView.onRemove = newValue}
    }

    var onDidBeginDraggingSlider: ((UISlider) -> Void)? {
        get { mainView.onDidBeginDraggingSlider }
        set { mainView.onDidBeginDraggingSlider = newValue }
    }

    var onDidEndDraggingSlider: ((UISlider) -> Void)? {
        get { mainView.onDidEndDraggingSlider }
        set { mainView.onDidEndDraggingSlider = newValue }
    }

    var currentTime: String? {
        get { mainView.currentTimeLabel.text }
        set { mainView.currentTimeLabel.text = newValue }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(mainView)
        mainView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        slider.value = .zero
    }
    
    func configure(with viewModel: PlayAudioView.ViewModel) {
        mainView.configure(with: viewModel)
    }

}
