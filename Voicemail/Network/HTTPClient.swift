//
//  HTTPClient.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 27.11.2022.
//

import Combine
import Foundation

protocol HTTPClient {
    func download(from url: URL) -> AnyPublisher<URL, AppError>
}

final class URLSessionHTTPClient: HTTPClient {

    private let urlSession: URLSession

    init(urlSessionConfiguration: URLSessionConfiguration) {
        self.urlSession = .init(configuration: urlSessionConfiguration)
    }

    func download(from url: URL) -> AnyPublisher<URL, AppError> {
        let request = URLRequest(url: url)
        return Deferred {
            Future { promise in
                self.urlSession.downloadTask(with: request) { url, _, error in
                    if let url = url {
                        promise(.success(url))
                    } else if error != nil {
                        promise(.failure(CannotDownloadError()))
                    }
                }.resume()
            }
        }.eraseToAnyPublisher()
    }

}
