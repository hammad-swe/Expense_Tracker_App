//
//  InterstitialAdManager.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 19/06/2026.
//

import GoogleMobileAds
import UIKit

class InterstitialAdManager: NSObject {
    static let shared = InterstitialAdManager()

    private var interstitialAd: InterstitialAd?
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910" // test ID
    private var completionHandler: (() -> Void)?

    private override init() {}

    func loadAd() {
        let request = Request()
        InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Interstitial ad failed to load: \(error.localizedDescription)")
                return
            }
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    func showAdIfAvailable(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard let ad = interstitialAd else {
            print("Interstitial ad not ready, skipping")
            completion()
            return
        }

        self.completionHandler = completion
        ad.present(from: viewController)
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitialAd = nil
        completionHandler?()
        loadAd() // preload next one
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialAd = nil
        completionHandler?()
        loadAd() // preload next one
    }
}
