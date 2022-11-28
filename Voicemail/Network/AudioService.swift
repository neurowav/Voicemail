//
//  AudioService.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 27.11.2022.
//

import Combine
import Foundation

protocol AudioService {
    func downloadAudio(url: URL) -> AnyPublisher<URL, AppError>
}

final class AudioServiceImpl: AudioService {
    
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func downloadAudio(url: URL) -> AnyPublisher<URL, AppError> {
        client.download(from: url)
            .receive(on: DispatchQueue.main)
            .flatMap { tempUrl -> AnyPublisher<URL, AppError> in
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                guard let audioId = components?.queryItems?.first(where: { $0.name == "id" })?.value else {
                    return Fail(error: NoAudioIdError()).eraseToAnyPublisher()
                }
                var updatedTemporaryFileURL = tempUrl.deletingLastPathComponent()
                updatedTemporaryFileURL.appendPathComponent(audioId)
                do {
                    try FileManager.default.moveItem(at: tempUrl, to: updatedTemporaryFileURL)
                    return Just(updatedTemporaryFileURL).setFailureType(to: AppError.self).eraseToAnyPublisher()
                } catch {
                    return Fail(error: MoveFileAudioErorr()).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
}
