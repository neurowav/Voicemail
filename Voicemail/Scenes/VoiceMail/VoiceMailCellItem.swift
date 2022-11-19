//
//  VoiceMailCellItem.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//

import Foundation

final class VoiceMailCellItem: Hashable {
    let identifier = UUID()
    var itemType: VoiceMailCellItemType
    var viewModel: Any

    init(itemType: VoiceMailCellItemType, viewModel: Any) {
        self.itemType = itemType
        self.viewModel = viewModel
    }
    
    static func == (lhs: VoiceMailCellItem, rhs: VoiceMailCellItem) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.itemType == rhs.itemType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemType)
        hasher.combine(identifier)
    }

    static let recentsViewHeader = VoiceMailCellItem(
        itemType: .header,
        viewModel: "Voicemails"
    )

    static func listItemModel(
        _ voiceMail: VoiceMail,
        accessoryHidden: Bool
    ) -> VoiceMailCell.ViewModel {
        let name: String
        if let contact = voiceMail.contact {
            name = "\(contact)"
        } else {
            name = voiceMail.from
        }
        var callTime: String?
        if let startDate = voiceMail.startTime {
            callTime = Formatters.voiceMailDateFormatted(callTime: TimeInterval(startDate))
        }
        return .init(
            name: name,
            country: accessoryHidden ? nil : Formatters.formattedAudioDuration(seconds: TimeInterval(voiceMail.duration)),
            callTime: callTime,
            accessoryHidden: accessoryHidden,
            accessoryIconTitle: voiceMail.audioFileExistLocally ? "play-gray" : "play-blue",
            nameColor: .label
        )
    }

    static func audioModel(
        _ voiceMail: VoiceMail,
        currentTime: TimeInterval,
        isPlaying: Bool
    ) -> PlayAudioView.ViewModel {
        return .init(
            currentTime: Formatters.formattedAudioDuration(seconds: currentTime),
            duration: Formatters.formattedAudioDuration(seconds: TimeInterval(voiceMail.duration)),
            isPlaying: isPlaying,
            isEnabled: voiceMail.audioFileExistLocally
        )
    }
}

enum VoiceMailCellItemType {
    case listItem
    case audio
    case header
}
enum VoiceMailSection {
    case voiceMails
}
