//
//  AudioServiceError.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 27.11.2022.
//

class AppError: Error {}

class NoAudioIdError: AppError {}

class MoveFileAudioErorr: AppError {}

class CannotDownloadError: AppError {}
