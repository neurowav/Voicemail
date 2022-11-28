//
//  Services.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 27.11.2022.
//

import Swinject

class Services {

    static let container = Container()

    static func register() {
        container.register(HTTPClient.self) { _ in
            URLSessionHTTPClient(urlSessionConfiguration: .default)
        }.inObjectScope(.container)
        container.register(AudioService.self) { resolver in
            AudioServiceImpl(client: resolver.resolve())
        }.inObjectScope(.container)
    }

}
extension Services {

    static var networkService: HTTPClient {
        container.resolve()
    }

    static var audioService: AudioService {
        container.resolve()
    }

}
private extension Resolver {
    
    func resolve<Service>() -> Service {
        resolve(Service.self)!
    }
    
}
