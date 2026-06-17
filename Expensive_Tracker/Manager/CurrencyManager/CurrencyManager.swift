//
//  CurrencyManager.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 17/06/2026.
//

import Foundation

struct ExchangeRateResponse: Decodable {
    let result: String
    let base_code: String
    let conversion_rates: [String: Double]
}

struct SupportedCodesResponse: Decodable {
    let result: String
    let supported_codes: [[String]]
}

final class CurrencyManager {
    static let shared = CurrencyManager()
    static let notificationName = Notification.Name("CurrencyDidChange")

    private init() {
        loadSelectedCurrency()
    }

    // ✅ "PKR" or "USD" — what the user wants to SEE numbers in right now
    private(set) var selectedCurrencyCode: String = "PKR"

    // ✅ Cached PKR -> USD rate, refreshed periodically, never blocks UI if stale
    private var pkrToUsdRate: Double = 0.0036 // rough fallback if API has never succeeded yet
    private var lastFetchDate: Date?
    private let cacheLifetime: TimeInterval = 60 * 60 // 1 hour (free tier updates daily anyway)

    // ✅ Currency full names — hardcoded fallback shown instantly, replaced live if API succeeds
    private(set) var currencyDisplayNames: [String: String] = [
        "PKR": "Pakistani Rupee",
        "USD": "US Dollar"
    ]

    private let defaults = UserDefaults.standard
    private let selectedCurrencyKey = "selectedCurrencyCode"
    private let migrationKey = "didMigrateToPKRBase"

    // MARK: - Selected currency persistence (UserDefaults, app-wide UI preference)

    private func loadSelectedCurrency() {
        selectedCurrencyCode = defaults.string(forKey: selectedCurrencyKey) ?? "PKR"
    }

    func setSelectedCurrency(_ code: String) {
        selectedCurrencyCode = code
        defaults.set(code, forKey: selectedCurrencyKey)
        NotificationCenter.default.post(name: CurrencyManager.notificationName, object: nil)
    }

    // MARK: - Rate fetching

    /// Ensures we have a reasonably fresh PKR->USD rate, fetching only if cache is stale or empty.
    func ensureFreshRate(completion: @escaping () -> Void) {
        if let last = lastFetchDate, Date().timeIntervalSince(last) < cacheLifetime {
            completion()
            return
        }
        fetchRate(completion: completion)
    }

    /// Forces a fetch regardless of cache age — use when user explicitly switches currency.
    func fetchRate(completion: @escaping () -> Void) {
        let apiKey = Secrets.exchangeRateAPIKey
        guard !apiKey.isEmpty,
              let url = URL(string: "https://v6.exchangerate-api.com/v6/\(apiKey)/latest/PKR") else {
            completion()
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            defer { DispatchQueue.main.async { completion() } }
            guard let self = self, let data = data, error == nil else { return }
            do {
                let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
                if let usdRate = decoded.conversion_rates["USD"] {
                    self.pkrToUsdRate = usdRate
                    self.lastFetchDate = Date()
                }
            } catch {
                // keep last known/fallback rate, fail silently for display purposes
            }
        }.resume()
    }

    // MARK: - Currency display names (optional live fetch — hardcoded fallback used until/unless this succeeds)

    /// Fetches full currency names from the API in the background. Non-blocking:
    /// hardcoded fallback names in `currencyDisplayNames` are used immediately,
    /// and this just quietly upgrades them if/when the network call succeeds.
    func fetchSupportedCurrencyNames(completion: (() -> Void)? = nil) {
        let apiKey = Secrets.exchangeRateAPIKey
        guard !apiKey.isEmpty,
              let url = URL(string: "https://v6.exchangerate-api.com/v6/\(apiKey)/codes") else {
            completion?()
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            defer { DispatchQueue.main.async { completion?() } }
            guard let self = self, let data = data, error == nil else { return }
            do {
                let decoded = try JSONDecoder().decode(SupportedCodesResponse.self, from: data)
                for pair in decoded.supported_codes where pair.count == 2 {
                    self.currencyDisplayNames[pair[0]] = pair[1]
                }
            } catch {
                // keep hardcoded fallback names, fail silently
            }
        }.resume()
    }

    /// Builds a (full, short) display tuple for a given currency code.
    /// IMPORTANT: `short` here is ALWAYS the real ISO currency code (e.g. "USD", "PKR") —
    /// never an abbreviated display-only label. Conversion math and CurrencyManager calls
    /// depend on this being the real code. Display-only shortening (e.g. showing "US" instead
    /// of "USD" in a tiny label) should happen at the call site, not here.
    func currencyOption(forCode code: String) -> (full: String, short: String) {
        let name = currencyDisplayNames[code] ?? code
        let suffix = code == "USD" ? " ($)" : " (\(code))"
        return ("\(name)\(suffix)", code)
    }

    // MARK: - Conversion helpers (explicit currency codes — never implicitly trust `selectedCurrencyCode`)

    /// Converts a PKR amount into a specific target currency code.
    func convertFromPKR(_ pkrAmount: Double, to code: String) -> Double {
        switch code {
        case "USD":
            return pkrAmount * pkrToUsdRate
        default:
            return pkrAmount
        }
    }

    /// Converts an amount in a specific source currency code into PKR.
    func convertToPKR(_ amount: Double, from code: String) -> Double {
        switch code {
        case "USD":
            return pkrToUsdRate > 0 ? amount / pkrToUsdRate : amount
        default:
            return amount
        }
    }

    /// Convenience: converts a PKR amount into whatever is CURRENTLY selected, for display.
    func displayAmount(forPKRAmount pkrAmount: Double) -> Double {
        convertFromPKR(pkrAmount, to: selectedCurrencyCode)
    }

    /// Convenience: formats a PKR-stored amount as a string in the currently selected currency.
    func displayString(forPKRAmount pkrAmount: Double) -> String {
        let converted = displayAmount(forPKRAmount: pkrAmount)
        switch selectedCurrencyCode {
        case "USD":
            return String(format: "$%.2f", converted)
        default:
            return String(format: "Rs %.0f", converted)
        }
    }

    // MARK: - One-time migration: normalize old Budget records to PKR

    func migrateExistingRecordsToPKRIfNeeded(completion: @escaping () -> Void) {
        guard !defaults.bool(forKey: migrationKey) else {
            completion()
            return
        }

        fetchRate { [weak self] in
            guard let self = self else { completion(); return }

            // Budget has a currency property — normalize old USD budgets to PKR
            if let budget = CoreDataManager.shared.fetchCurrentBudget(),
               let recordCurrency = budget.currency, recordCurrency == "USD" {
                budget.totalAmount = self.convertToPKR(budget.totalAmount, from: "USD")
                budget.currency = "PKR"
            }

            // Expense has no currency field — nothing to migrate there.

            CoreDataManager.shared.saveContext()
            self.defaults.set(true, forKey: self.migrationKey)
            completion()
        }
    }
}
