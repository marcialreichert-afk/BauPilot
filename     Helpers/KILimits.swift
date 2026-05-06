//
//  KILimits.swift
//  BauPilot
//
//  Created by Marcial Reichert on 24.04.26.
//

import Foundation

enum KILimits {
    static let maxTextActionsPerMonth = 500
}

final class KIUsageManager {
    static let shared = KIUsageManager()

    private let countKey = "kiTextUsageCount"
    private let monthKey = "kiTextUsageMonth"

    private init() {}

    var currentMonthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    var usedTextActions: Int {
        resetIfNeeded()
        return UserDefaults.standard.integer(forKey: countKey)
    }

    var remainingTextActions: Int {
        max(0, KILimits.maxTextActionsPerMonth - usedTextActions)
    }

    var canUseKIText: Bool {
        AppConfig.isProUser && remainingTextActions > 0
    }

    func registerKITextAction() {
        resetIfNeeded()
        let current = UserDefaults.standard.integer(forKey: countKey)
        UserDefaults.standard.set(current + 1, forKey: countKey)
    }

    func resetIfNeeded() {
        let savedMonth = UserDefaults.standard.string(forKey: monthKey)

        if savedMonth != currentMonthKey {
            UserDefaults.standard.set(currentMonthKey, forKey: monthKey)
            UserDefaults.standard.set(0, forKey: countKey)
        }
    }
}
