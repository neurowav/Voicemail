//
//  Formatters.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//

import Foundation

enum Formatters {

    static let dateComponentsFormatter = DateComponentsFormatter()
    
    static func formattedAudioDuration(
        seconds: TimeInterval,
        unitStyle: DateComponentsFormatter.UnitsStyle = .positional,
        zeroFormattingBehavior: DateComponentsFormatter.ZeroFormattingBehavior = .pad
    ) -> String? {
        dateComponentsFormatter.allowedUnits = [.minute, .second]
        dateComponentsFormatter.unitsStyle = unitStyle
        dateComponentsFormatter.zeroFormattingBehavior = zeroFormattingBehavior
        var formattedTime = dateComponentsFormatter.string(from: seconds)
        if unitStyle == .positional && formattedTime?.first == "0" {
            formattedTime?.removeFirst()
        }
        return formattedTime
    }

    static let dateFormatter = DateFormatter()

    static func voiceMailDateFormatted(callTime: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: callTime)
        dateFormatter.dateFormat = nil
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        let relativeDate = dateFormatter.string(from: date)
        dateFormatter.doesRelativeDateFormatting = false
        let commonDate = dateFormatter.string(from: date)
        if relativeDate == commonDate {
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .none
            dateFormatter.dateFormat = "MMM d, h:mm"
            return dateFormatter.string(from: date)
        } else {
            return relativeDate
        }
    }

}
