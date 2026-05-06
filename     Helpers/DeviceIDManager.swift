//
//  DeviceIDManager.swift
//  BauPilot
//
//  Created by Marcial Reichert on 25.04.26.
//


//
//  DeviceIDManager.swift
//  BauPilot
//
//  Created by Marcial Reichert on 25.04.26.
//

import Foundation

final class DeviceIDManager {
    static let shared = DeviceIDManager()

    private let key = "baupilot_device_id"

    private init() {}

    var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: key)
            return newID
        }
    }
}
