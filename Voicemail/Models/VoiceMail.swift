//
//  VoiceMail.swift
//  Voicemail
//
//  Created by Vlad Evsegneev on 19.11.2022.
//

import Foundation

struct VoiceMail: Codable {
    let from: String
    let to: String
    var contact: String?
    let recordingSid: String
    let callSid: String?
    let accountSid: String?
    let dateCreated: Int?
    let dateUpdated: Int?
    let duration: Int
    let startTime: Int?
    let uri: String?
    
    var audioFileName: String? {
        if let uri = uri, let urlComponents = URLComponents(string: uri) {
            return urlComponents.queryItems?.first(where: { $0.name == "id" })?.value
        }
        return nil
    }
    
    var audioFileLocalUrl: URL? {
        if let fileName = audioFileName {
            let tmpDirectory = FileManager.default.temporaryDirectory
            return tmpDirectory.appendingPathComponent(fileName)
        }
        return nil
    }
    
    var audioFileExistLocally: Bool {
        if let fileUrl = audioFileLocalUrl {
            return FileManager.default.fileExists(atPath: fileUrl.path)
        }
        return false
    }
    
    static func generateMocks() -> [VoiceMail] {
        [
            .init(
                from: "+7-988-123-45-78",
                to: "+7-988-123-45-78",
                recordingSid: "1",
                callSid: "1",
                accountSid: "1",
                dateCreated: 1668344433,
                dateUpdated: 1668344433,
                duration: 10,
                startTime: 1668344433,
                uri: "https://drive.google.com/uc?export=open&id=1zlb6Vec39grKMeHsuEX165pWae3e2BO3"
            ),
            .init(
                from: "+7-988-123-45-78",
                to: "+7-988-123-45-78",
                contact: "Mihail",
                recordingSid: "2",
                callSid: "2",
                accountSid: "2",
                dateCreated: 1668344433,
                dateUpdated: 1668344433,
                duration: 7,
                startTime: 1668344433,
                uri: "https://drive.google.com/uc?export=open&id=1HVMXMKw-kl2N_QajgENUTRTh98jnf4S4"
            ),
            .init(
                from: "+7-988-123-45-78",
                to: "+7-988-123-45-78",
                contact: "Alexandr",
                recordingSid: "3",
                callSid: "3",
                accountSid: "3",
                dateCreated: 1668344433,
                dateUpdated: 1668344433,
                duration: 7,
                startTime: 1668344433,
                uri: "https://drive.google.com/uc?export=open&id=17PrAVDtUzBjT81q2xBbDhfAVWr5QdkVc"
            ),
            .init(
                from: "+7-988-123-45-78",
                to: "+7-988-123-45-78",
                recordingSid: "4",
                callSid: "4",
                accountSid: "4",
                dateCreated: 1668344433,
                dateUpdated: 1668344433,
                duration: 7,
                startTime: 1668344433,
                uri: "https://drive.google.com/uc?export=open&id=1YeXoPRSj56sh7NQ3x0FjSYCv5bWziHbk"
            ),
            .init(
                from: "+7-988-123-45-78",
                to: "+7-988-123-45-78",
                contact: "Shawn",
                recordingSid: "5",
                callSid: "5",
                accountSid: "5",
                dateCreated: 1668344433,
                dateUpdated: 1668344433,
                duration: 7,
                startTime: 1668344433,
                uri: "https://drive.google.com/uc?export=open&id=1FDzlj2OcSAVhaGUTgsgqW88DWjA0Su0s"
            ),
            .init(
                from: "+7-988-123-45-78",
                to: "+7-988-123-45-78",
                recordingSid: "6",
                callSid: "6",
                accountSid: "6",
                dateCreated: 1668344433,
                dateUpdated: 1668344433,
                duration: 7,
                startTime: 1668344433,
                uri: "https://drive.google.com/uc?export=open&id=15CooyF7-3skuEZbN3XxIeze004ZN9XqG"
            )
        ]
    }

}
extension VoiceMail: Equatable {

    static func == (lhs: VoiceMail, rhs: VoiceMail) -> Bool {
        lhs.callSid == rhs.callSid
    }

}
