//
//  SceneDelegate.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        Services.register()
        window = UIWindow(windowScene: scene)
        let vc = VoiceMailController()
        let presenter = VoiceMailPresenter()
        vc.presenter = presenter
        presenter.view = vc
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }

}

