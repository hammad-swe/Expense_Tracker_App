//
//  AppOpenAdManager.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 18/06/2026.
//

import GoogleMobileAds

class AppOpenAdManager: NSObject {
    static let shared = AppOpenAdManager()

    private var appOpenAd: AppOpenAd?
    private var loadTime: Date?
    private let adUnitID = "ca-app-pub-3940256099942544/5575463023" // test ID for now
    private var isLoadingAd = false
    var isShowingAd = false
    private var completionHandler: (() -> Void)?

    private override init() {}

    func loadAd() {
        if isLoadingAd || isAdAvailable() { return }
        isLoadingAd = true

        let request = Request()
        AppOpenAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            self?.isLoadingAd = false
            if let error = error {
                print("App open ad failed to load: \(error.localizedDescription)")
                return
            }
            self?.appOpenAd = ad
            self?.appOpenAd?.fullScreenContentDelegate = self
            self?.loadTime = Date()
        }
    }

    private func isAdAvailable() -> Bool {
        guard let loadTime = loadTime else { return false }
        return appOpenAd != nil && Date().timeIntervalSince(loadTime) < 4 * 3600
    }

    func showAdIfAvailable(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard isAdAvailable(), let ad = appOpenAd else {
            print("App open ad not ready, skipping")
            completion()
            return
        }

        self.completionHandler = completion
        isShowingAd = true
        ad.present(from: viewController)
    }
}

extension AppOpenAdManager: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isShowingAd = false
        appOpenAd = nil
        completionHandler?()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isShowingAd = false
        appOpenAd = nil
        completionHandler?()
    }
}
