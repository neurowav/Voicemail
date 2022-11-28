//
//  VoiceMailPresenter.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//
import Foundation
import Combine
import AVFoundation

final class VoiceMailPresenter {

    weak var view: VoiceMailViewProtocol!

    private var dataStore: [VoiceMailCellItem: VoiceMailStorage] = [:]
    private var voiceMails: [VoiceMail] = VoiceMail.generateMocks()

    private var cleanupContainer = Set<AnyCancellable>()

    var audioService: AudioService {
        Services.audioService
    }

    private var activeVoiceMail: VoiceMail?
    private var player: AVAudioPlayer?
    var playerItem: VoiceMailCellItem?

    var playBackProgress: Float? {
        if let player = player {
            return Float(player.currentTime / player.duration)
        }
        return nil
    }

    var currentPlayerTime: String? {
        Formatters.formattedAudioDuration(seconds: player?.currentTime ?? .zero)
    }
    
    static let secondsCount = TimeInterval(15)

}
// MARK: - Voice Mails
private extension VoiceMailPresenter {

    func didSelect(voiceMailStorage: VoiceMailStorage, item: VoiceMailCellItem) {
        if !voiceMailStorage.expanded && activeVoiceMail != nil {
            return
        }
        var voiceMailStorage = voiceMailStorage
        let voiceMail = voiceMailStorage.voiceMail
        voiceMailStorage.expanded.toggle()
        if voiceMailStorage.expanded {
            activeVoiceMail = voiceMail
            item.viewModel = VoiceMailCellItem.listItemModel(voiceMail, accessoryHidden: true)
            let audioViewModel = VoiceMailCellItem.audioModel(voiceMail, currentTime: player?.currentTime ?? .zero, isPlaying: false)
            let audioItem = VoiceMailCellItem(itemType: .audio, viewModel: audioViewModel)
            self.playerItem = audioItem
            dataStore[audioItem] = voiceMailStorage
            voiceMailStorage.audioItem = audioItem
            dataStore[item] = voiceMailStorage
            view.insertInDataSource(items: [audioItem], insertAfter: item)
            createPlayerIfNeeded(for: voiceMail)
        } else {
            stopAndRemovePlayerIfActive()
            activeVoiceMail = nil
            if let audioItem = voiceMailStorage.audioItem {
                item.viewModel = VoiceMailCellItem.listItemModel(voiceMail, accessoryHidden: false)
                if let audioItem = voiceMailStorage.audioItem {
                    dataStore.removeValue(forKey: audioItem)
                }
                voiceMailStorage.audioItem = nil
                voiceMailStorage.isPlaying = false
                dataStore[item] = voiceMailStorage
                view.deleteInDataSource(items: [audioItem], reconfigure: [item])
            }
        }
    }

    func onVoiceMailsFetchSuccess(_ voiceMails: [VoiceMail]) {
        if self.voiceMails != voiceMails {
            self.voiceMails = voiceMails
            prepareVoiceMailsData(voiceMails)
        }
    }

    func generateVoiceMailsData() -> [VoiceMailCellItem] {
        var cellItems: [VoiceMailCellItem] = []
        dataStore.removeAll()
        let voiceMailItems: [VoiceMailCellItem] = voiceMails.enumerated().reduce([], { partialResult, voiceMail in
            var partialResult = partialResult
            let active = voiceMail.element == activeVoiceMail
            let voiceMailViewModel = VoiceMailCellItem.listItemModel(voiceMail.element, accessoryHidden: active)
            let voiceMailItem = VoiceMailCellItem(itemType: .listItem, viewModel: voiceMailViewModel)
            partialResult.append(voiceMailItem)
            var storage = VoiceMailStorage(voiceMail: voiceMail.element, expanded: active)
            if active {
                let audioViewModel = VoiceMailCellItem.audioModel(
                    voiceMail.element,
                    currentTime: player?.currentTime ?? .zero,
                    isPlaying: player?.isPlaying ?? false
                )
                storage.isPlaying = audioViewModel.isPlaying
                let audioItem = VoiceMailCellItem(itemType: .audio, viewModel: audioViewModel)
                self.playerItem = audioItem
                partialResult.append(audioItem)
                dataStore[audioItem] = storage
                storage.audioItem = audioItem
            }
            dataStore[voiceMailItem] = storage
            return partialResult
        })
        cellItems.append(contentsOf: voiceMailItems)
        return cellItems
    }
    
    func prepareVoiceMailsData(_ voiceMails: [VoiceMail]) {
        var items = [VoiceMailCellItem]()
        items.append(.recentsViewHeader)
        let cellItems = generateVoiceMailsData()
        items.append(contentsOf: cellItems)
        view.updateDataSource(items: items, section: .voiceMails)
    }

}
// MARK: - AVFoundation Setup
private extension VoiceMailPresenter {

    func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func createAndStartPlayer(_ url: URL, play: Bool = true) {
        if let player = try? AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue) {
            self.player = player
            player.delegate = view as? AVAudioPlayerDelegate
            if play {
                player.prepareToPlay()
                player.play()
                view.startUpdatingPlaybackStatus()
            }
        }
    }

    func updatePlayerState(isPlaying: Bool, isEnabled: Bool? = nil) {
        if let playerItem = playerItem,
           var voiceMailStorage = dataStore[playerItem],
           let activeVoiceMail = activeVoiceMail {
            var viewModel = VoiceMailCellItem.audioModel(
                activeVoiceMail,
                currentTime: player?.currentTime ?? .zero,
                isPlaying: isPlaying
            )
            voiceMailStorage.isPlaying = viewModel.isPlaying
            if let isEnabled = isEnabled {
                viewModel.isEnabled = isEnabled
            }
            playerItem.viewModel = viewModel
            dataStore[playerItem] = voiceMailStorage
            self.view.reloadItem(playerItem, animated: false)
        }
    }

    func createPlayerIfNeeded(for voiceMail: VoiceMail) {
        if player == nil && voiceMail.audioFileExistLocally, let url = voiceMail.audioFileLocalUrl {
            createAndStartPlayer(url, play: false)
        }
    }
    
    func stopAndRemovePlayerIfActive() {
        if player != nil {
            player?.stop()
            player = nil
            view.stopUpdatingPlaybackStatus()
        }
    }

}
// MARK: - VoiceMailPresenterProtocol
extension VoiceMailPresenter: VoiceMailPresenterProtocol {

    func setup() {
        prepareVoiceMailsData(voiceMails)
        setupAudio()
    }

    func voiceMailExpanded(item: VoiceMailCellItem) -> Bool? {
        if let voiceMailStorage = dataStore[item] {
            return voiceMailStorage.expanded
        }
        return nil
    }

    func onPlay(item: VoiceMailCellItem) {
        guard var storage = dataStore[item] else { return }
        storage.isPlaying.toggle()
        defer {
            dataStore[item] = storage
        }
        if storage.isPlaying == false {
            player?.pause()
            view.stopUpdatingPlaybackStatus()
            return
        } else if player != nil && player?.isPlaying == false && storage.isPlaying {
            view.stopUpdatingPlaybackStatus()
            player?.play()
            view.startUpdatingPlaybackStatus()
            return
        }
        if storage.voiceMail.audioFileExistLocally, let fileUrl = storage.voiceMail.audioFileLocalUrl {
            createAndStartPlayer(fileUrl)
        } else {
            if let urlString = storage.voiceMail.uri, let url = URL(string: urlString) {
                view.setActivityIndicator(true)
                audioService.downloadAudio(url: url).sink { [weak self] result in
                    if case let .failure(error) = result {
                        switch error {
                        case is NoAudioIdError:
                            print("no id url parameter")
                        case is MoveFileAudioErorr:
                            print("cannot move the downloaded file")
                        default:
                            break
                        }
                    }
                    self?.view.setActivityIndicator(false)
                } receiveValue: { [weak self] url in
                    self?.createAndStartPlayer(url)
                    self?.updatePlayerState(isPlaying: true, isEnabled: true)
                }.store(in: &cleanupContainer)
            }
        }
    }

    func updatePlayerCurrentTime(_ sliderValue: Double) {
        if let duration = player?.duration {
            player?.currentTime = duration * sliderValue
        }
    }

    func audioPlayerDidFinishPlaying(success flag: Bool) {
        updatePlayerState(isPlaying: false)
    }

    func rewindAudio(forward: Bool) {
        guard let player = player else {
            return
        }
        if forward {
            let newTime = min(player.duration, player.currentTime + VoiceMailPresenter.secondsCount)
            player.currentTime = newTime
            if newTime == player.duration {
                player.stop()
                updatePlayerState(isPlaying: false)
            }
        } else {
            player.currentTime = max(.zero, player.currentTime - VoiceMailPresenter.secondsCount)
        }
        print(player.currentTime)
        view.updatePlaybackStatus()
    }

    func didSelect(item: VoiceMailCellItem) {
        if let voiceMailStorage = dataStore[item] {
            didSelect(voiceMailStorage: voiceMailStorage, item: item)
        }
    }

}
private extension VoiceMailPresenter {

    struct VoiceMailStorage {
        let voiceMail: VoiceMail
        var audioItem: VoiceMailCellItem?
        var expanded = false
        var isPlaying = false
    }

}
