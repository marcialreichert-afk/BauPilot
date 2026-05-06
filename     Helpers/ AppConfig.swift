//
//  AppConfig.swift
//  BauPilot
//
//  Created by Marcial Reichert on 24.04.26.
//

import Foundation

struct AppConfig {
    
    // MARK: - Pro Status
    // Wichtig: Diese App liest nur noch den vom Server synchronisierten Pro-Status.
    // Der alte Key "isProUser" wird bewusst nicht mehr verwendet, damit frühere Testwerte
    // nicht mehr fälschlich als Pro gelten.
    
    private static let serverProKey = "serverIsProUser"
    
    static var isProUser: Bool {
        UserDefaults.standard.bool(forKey: serverProKey)
    }
    
    static func setPro(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: serverProKey)
    }
    
    static func clearOldLocalProFlag() {
        UserDefaults.standard.removeObject(forKey: "isProUser")
    }
}
