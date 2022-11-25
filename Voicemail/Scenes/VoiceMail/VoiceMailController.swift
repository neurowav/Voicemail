//
//  VoiceMailController.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//

import AVFoundation
import UIKit

final class VoiceMailController: UIViewController {

    var presenter: VoiceMailPresenterProtocol!
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(VoiceMailCell.self, forCellWithReuseIdentifier: VoiceMailCell.reuseId)
        collectionView.register(PlayAudioCell.self, forCellWithReuseIdentifier: PlayAudioCell.reuseId)
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<VoiceMailSection, VoiceMailCellItem> = {
        let cellRegistration = textCellRegistration()
        return .init(collectionView: collectionView) { [unowned self] collectionView, indexPath, item in
            self.dequeueCell(
                collectionView: collectionView,
                indexPath: indexPath,
                item: item,
                cellRegistration: cellRegistration
            )
        }
    }()

    private lazy var displayLink = CADisplayLink(target: self, selector: #selector(updatePlaybackStatus))

    class func instantiate() -> UIViewController {
        let vc = VoiceMailController()
        let presenter = VoiceMailPresenter()
        vc.presenter = presenter
        presenter.view = vc
        return vc
    }

    override func loadView() {
        self.view = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.setup()
        setupCollectionView()
    }

    func setupCollectionView() {
        collectionView.refreshControl = .init(
            frame: .zero,
            primaryAction: .init(handler: { [weak self] _ in
                self?.presenter.onRefresh()
            })
        )
    }

    func createLayout() -> UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.itemSeparatorHandler = { [weak self] itemIndexPath, sectionSeparatorConfiguration in
            guard let self = self else { return sectionSeparatorConfiguration}
            var config = sectionSeparatorConfiguration
            if let item = self.dataSource.itemIdentifier(for: itemIndexPath) {
                switch item.itemType {
                case .listItem:
                    if let active = self.presenter.voiceMailExpanded(item: item) {
                        config.bottomSeparatorVisibility = active ? .hidden : .visible
                    }
                case .audio:
                    config.bottomSeparatorVisibility = .visible
                default:
                    break
                }
            }
            config.color = .secondaryLabel
            config.bottomSeparatorInsets = Constants.headerSeparatorInset
            return config
        }
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    func dequeueCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: VoiceMailCellItem,
        cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, VoiceMailCellItem>
    ) -> UICollectionViewCell {
        switch (item.itemType, item.viewModel) {
        case (.listItem, let viewModel as VoiceMailCell.ViewModel):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: VoiceMailCell.reuseId,
                for: indexPath
            ) as? VoiceMailCell
            cell?.configure(with: viewModel)
            return cell ?? .init()
        case (.header, _):
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        case (.audio, let viewModel as PlayAudioView.ViewModel):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PlayAudioCell.reuseId,
                for: indexPath
            ) as? PlayAudioCell
            cell?.configure(with: viewModel)
            cell?.onPlay = { [unowned self] _, _ in
                if let item = self.dataSource.itemIdentifier(for: indexPath) {
                    self.presenter.onPlay(item: item)
                }
            }
            cell?.onBackward = { [unowned self] in
                self.presenter.rewindAudio(forward: false)
            }
            cell?.onForward = { [unowned self] in
                self.presenter.rewindAudio(forward: true)
            }
            cell?.onDidBeginDraggingSlider = { [unowned self] _ in
                displayLink.isPaused = true
            }
            cell?.onDidEndDraggingSlider = { [unowned self] slider in
                let sliderValue = Double(slider.value)
                self.presenter.updatePlayerCurrentTime(sliderValue)
                self.displayLink.isPaused = false
                cell?.currentTime = self.presenter.currentPlayerTime
            }
            return cell ?? .init()
        default:
            return .init()
        }
    }

    func textCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, VoiceMailCellItem> {
        .init { cell, _, item in
            var content = cell.defaultContentConfiguration()
            if case .header = item.itemType, let text = item.viewModel as? String {
                content.text = "\(text)"
            }
            content.textProperties.color = .label
            content.textProperties.font = Constants.headerFont
            cell.contentConfiguration = content
        }
    }

}
// MARK: - UICollectionViewDelegate
extension VoiceMailController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if let item = dataSource.itemIdentifier(for: indexPath), case .listItem = item.itemType {
            return true
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            presenter.didSelect(item: item)
        }
    }

}
// MARK: - VoiceMailViewIput
extension VoiceMailController: VoiceMailViewProtocol {
    
    func updateDataSource(items: [VoiceMailCellItem], section: VoiceMailSection) {
        var snapshot = NSDiffableDataSourceSnapshot<VoiceMailSection, VoiceMailCellItem>()
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func insertInDataSource(items: [VoiceMailCellItem], insertAfter: VoiceMailCellItem) {
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems([insertAfter])
        snapshot.insertItems(items, afterItem: insertAfter)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func deleteInDataSource(items: [VoiceMailCellItem], reconfigure: [VoiceMailCellItem]) {
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems(reconfigure)
        snapshot.deleteItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func reloadItem(_ item: VoiceMailCellItem, animated: Bool) {
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems([item])
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    @objc
    func updatePlaybackStatus() {
        if let playbackProgress = presenter.playBackProgress,
           let playerItem = presenter.playerItem,
           let indexPath = dataSource.indexPath(for: playerItem),
           let cell = collectionView.cellForItem(at: indexPath) as? PlayAudioCell {
            cell.slider.setValue(playbackProgress, animated: true)
            cell.currentTime = presenter.currentPlayerTime
        }
    }

    // MARK: - Player
    func startUpdatingPlaybackStatus() {
        displayLink = .init(target: self, selector: #selector(updatePlaybackStatus))
        displayLink.add(to: .main, forMode: .common)
    }

    func stopUpdatingPlaybackStatus() {
        displayLink.invalidate()
    }

}
// MARK: - AVAudioPlayerDelegate
extension VoiceMailController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        presenter.audioPlayerDidFinishPlaying(success: flag)
        stopUpdatingPlaybackStatus()
    }

}
private enum Constants {
    static let headerFont = UIFont.boldSystemFont(ofSize: 34)
    static let headerSeparatorInset = NSDirectionalEdgeInsets(top: 0, leading: 34, bottom: 0, trailing: 0)
    static let selectNumberHeight: CGFloat = 36
}
