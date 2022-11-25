//
//  VoiceMail+Protocols.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 25.11.2022.
//

protocol VoiceMailPresenterProtocol {
    var playBackProgress: Float? { get }
    var playerItem: VoiceMailCellItem? { get set }
    var currentPlayerTime: String? { get }
    
    func setup()
    func onRefresh()
    func voiceMailExpanded(item: VoiceMailCellItem) -> Bool?
    func deleteVoiceMail(item: VoiceMailCellItem)
    func onPlay(item: VoiceMailCellItem)
    func updatePlayerCurrentTime(_ sliderValue: Double)
    func audioPlayerDidFinishPlaying(success flag: Bool)
    func rewindAudio(forward: Bool)
    func didSelect(item: VoiceMailCellItem)
}

protocol VoiceMailViewProtocol: AnyObject {
    func updateDataSource(items: [VoiceMailCellItem], section: VoiceMailSection)
    func insertInDataSource(items: [VoiceMailCellItem], insertAfter: VoiceMailCellItem)
    func deleteInDataSource(items: [VoiceMailCellItem], reconfigure: [VoiceMailCellItem])
    func reloadItem(_ item: VoiceMailCellItem, animated: Bool)
    func updatePlaybackStatus()
    func startUpdatingPlaybackStatus()
    func stopUpdatingPlaybackStatus()
}
