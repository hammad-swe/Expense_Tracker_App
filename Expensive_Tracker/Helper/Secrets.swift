//
//  Secrets.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 17/06/2026.
//

import Foundation

enum Secrets {
    static var exchangeRateAPIKey: String {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let key = plist["ExchangeRateAPIKey"] as? String else {
            assertionFailure("Secrets.plist missing or ExchangeRateAPIKey not found")
            return ""
        }
        return key
    }
}
