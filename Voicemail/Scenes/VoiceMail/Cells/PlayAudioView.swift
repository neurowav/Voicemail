//
//  PlayAudioView.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//

import UIKit

fileprivate final class CustomSlider: UISlider {

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.size.height = 2
        return newBounds
    }
}

final class PlayAudioView: UIView {

    // MARK: - Views
    private(set) lazy var slider: UISlider = {
        let view = CustomSlider()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.maximumValue = 1.0
        view.setThumbImage(.init(named: Defaults.thumbTitle), for: .normal)
        view.setThumbImage(.init(named: Defaults.thumbTitle), for: .highlighted)
        view.setThumbImage(.init(), for: .selected)
        view.maximumTrackTintColor = .systemGray
        view.minimumTrackTintColor = .systemBlue
        view.isContinuous = false
        view.addTarget(self, action: #selector(didBeginDraggingSlider), for: .touchDown)
        view.addTarget(self, action: #selector(didEndDraggingSlider), for: .valueChanged)
        return view
    }()

    private(set) lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let view = UIProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.progressTintColor = .systemBlue
        view.trackTintColor = .systemGray
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [backwarddButton, playButton, forwardButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Defaults.buttonsStackSpacing
        stackView.alignment = .center
        return stackView
    }()

    private lazy var backwarddButton: UIButton = {
        let button = UIButton(type: .system, primaryAction: .init { [weak self] _ in
            self?.onBackward?()
        })
        button.setImage(Defaults.imageForTitle(Defaults.rewindTitle), for: .normal)
        return button
    }()

    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system, primaryAction: .init { [weak self] _ in
            guard let self = self else {
                return
            }
            self.playButton.isSelected.toggle()
            let isSelected = self.playButton.isSelected
            self.onPlay?(isSelected, self.slider)
        })
        button.tintColor = .clear
        button.backgroundColor = .clear
        button.setBackgroundImage(Defaults.imageForTitle(Defaults.playTitle), for: .normal)
        button.setBackgroundImage(Defaults.imageForTitle(Defaults.playTitle), for: [.normal, .highlighted])
        button.setBackgroundImage(Defaults.imageForTitle(Defaults.pauseTitle), for: [.selected, .highlighted])
        button.setBackgroundImage(Defaults.imageForTitle(Defaults.pauseTitle), for: .selected)
        return button
    }()

    private lazy var forwardButton: UIButton = {
        let button = UIButton(type: .system, primaryAction: .init { [weak self] _ in
            self?.onForward?()
        })
        button.setImage(Defaults.imageForTitle(Defaults.forwardTitle), for: .normal)
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .system, primaryAction: .init { [weak self] _ in
            self?.onRemove?()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(Defaults.imageForTitle(Defaults.removeTitle), for: .normal)
        return button
    }()

    // MARK: - Handlers
    var onPlay: ((Bool, UISlider) -> Void)?
    var onBackward: (() -> Void)?
    var onForward: (() -> Void)?
    var onRemove: (() -> Void)?
    var onDidBeginDraggingSlider: ((UISlider) -> Void)?
    var onDidEndDraggingSlider: ((UISlider) -> Void)?
    
    var sliderEnbled: Bool = true {
        didSet {
            slider.isSelected = !sliderEnbled
            slider.isUserInteractionEnabled = sliderEnbled
        }
    }

    var playButtonSelected: Bool {
        get { playButton.isSelected }
        set { playButton.isSelected = newValue }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        layoutSetup()
    }
    
    private func layoutSetup() {
        addSubview(slider)
        addSubview(stackView)
        addSubview(removeButton)
        addSubview(currentTimeLabel)
        addSubview(durationLabel)
        let bottomConstraint = bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Defaults.stackBottom)
        bottomConstraint.priority = Defaults.stackBottomPriority
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Defaults.sliderInsets.left),
            slider.topAnchor.constraint(equalTo: topAnchor, constant: Defaults.sliderInsets.top),
            trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: Defaults.sliderInsets.right),
            stackView.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: Defaults.sliderInsets.bottom),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomConstraint,
            trailingAnchor.constraint(equalTo: removeButton.trailingAnchor, constant: Defaults.removeTrailing),
            removeButton.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            currentTimeLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            currentTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: Defaults.durationTop),
            slider.trailingAnchor.constraint(equalTo: durationLabel.trailingAnchor),
            durationLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: Defaults.durationTop)
        ])
    }

    func configure(with viewModel: ViewModel) {
        self.sliderEnbled = viewModel.isEnabled
        self.playButtonSelected = viewModel.isPlaying
        currentTimeLabel.text = viewModel.currentTime
        durationLabel.text = viewModel.duration
    }

}
private extension PlayAudioView {

    @objc
    func didBeginDraggingSlider(sender: UISlider) {
        onDidBeginDraggingSlider?(sender)
    }

    @objc
    func didEndDraggingSlider(sender: UISlider) {
        onDidEndDraggingSlider?(sender)
    }

}
extension PlayAudioView {

    struct ViewModel {
        let currentTime: String?
        let duration: String?
        var isPlaying: Bool
        var isEnabled: Bool
    }

}
private enum Defaults {
    static let buttonsStackSpacing: CGFloat = 46
    static let rewindTitle = "rewind"
    static let forwardTitle = "forward"
    static let playTitle = "play"
    static let pauseTitle = "pause"
    static let removeTitle = "remove"
    static let thumbTitle = "thumb"
    static let sliderInsets = UIEdgeInsets(top: 5, left: 34, bottom: 38, right: 16)
    static let removeTrailing: CGFloat = 16
    static let durationTop: CGFloat = 6
    static let stackBottom: CGFloat = 32
    static let stackBottomPriority = UILayoutPriority(rawValue: 999)

    static func imageForTitle(_ title: String) -> UIImage? {
        .init(named: title)?.withRenderingMode(.alwaysOriginal)
    }
    
}
