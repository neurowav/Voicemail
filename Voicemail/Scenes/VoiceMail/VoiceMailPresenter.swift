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

    weak var view: VoiceMailController!
    private var dataStore: [VoiceMailCellItem: Any] = [:]
    private var voiceMails: [VoiceMail] = VoiceMail.generateMocks()
    
    private var activeVoiceMail: VoiceMail?
    private var player: AVAudioPlayer?
    private(set) var playerItem: VoiceMailCellItem?

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

extension VoiceMailPresenter {

    func setup() {
        prepareVoiceMailsData(voiceMails)
        setupAudio()
    }

    func didSelect(recentItem: VoiceMailCellItem) {
        switch dataStore[recentItem] {
        case let voiceMailStorage as VoiceMailStorage:
            didSelect(voiceMailStorage: voiceMailStorage, item: recentItem)
        default:
            break
        }
    }

    func voiceMailExpanded(item: VoiceMailCellItem) -> Bool? {
        if let voiceMailStorage = dataStore[item] as? VoiceMailStorage {
            return voiceMailStorage.expanded
        }
        return nil
    }
    
    func onRefresh() {
        onVoiceMailsRefresh()
    }
    
}
// MARK: Voice Mails
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
    
    func onVoiceMailsRefresh() {
        
    }

    func voiceMailsSetup() {
        
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
        view.updateDataSource(items: items)
    }

}
// MARK: AVFoundation Setup
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
            player.delegate = view
            if play {
                player.prepareToPlay()
                player.play()
                view.startUpdatingPlaybackStatus()
            }
        }
    }

    func updatePlayerState(isPlaying: Bool, isEnabled: Bool? = nil) {
        if let playerItem = playerItem,
           var voiceMailStorage = dataStore[playerItem] as? VoiceMailStorage,
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
            self.view.reloadItem(playerItem)
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
// MARK: Actions
extension VoiceMailPresenter {

    func deleteVoiceMail(item: VoiceMailCellItem) {
        
    }

    func onPlay(item: VoiceMailCellItem) {
        guard var storage = dataStore[item] as? VoiceMailStorage else { return }
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
            downloadVoiceMail(storage.voiceMail.uri) { [weak self] url in
                self?.createAndStartPlayer(url)
                self?.updatePlayerState(isPlaying: true, isEnabled: true)
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

    private func downloadVoiceMail(_ urlString: String?, completion: @escaping (URL) -> Void) {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        let components = URLComponents(string: urlString)
        URLSession.shared.downloadTask(with: url) { tempUrl, _, _ in
            if let tempUrl = tempUrl, let id = components?.queryItems?.first(where: { $0.name == "id" })?.value {
                var temporaryFileURL = tempUrl.deletingLastPathComponent()
                temporaryFileURL.appendPathComponent(id)
                do {
                    try FileManager.default.moveItem(at: tempUrl, to: temporaryFileURL)
                    DispatchQueue.main.async {
                        completion(temporaryFileURL)
                    }
                } catch {
                    print(error)
                }
            }
        }.resume()
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
