//
//  RewardedAdManager.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 19/06/2026.
//

import GoogleMobileAds
import UIKit

class RewardedAdManager: NSObject {
    static let shared = RewardedAdManager()

    private var rewardedAd: RewardedAd?
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313" // test ID
    private var completionHandler: (() -> Void)?

    private override init() {}

    func loadAd() {
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Rewarded ad failed to load: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }

    func showAdIfAvailable(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard let ad = rewardedAd else {
            print("Rewarded ad not ready, skipping")
            completion() // save expense anyway if ad not ready
            return
        }

        self.completionHandler = completion
        ad.present(from: viewController) { [weak self] in
            // This block fires only when the user earns the reward (watched the full ad)
            print("✅ Reward earned — saving expense now")
            self?.completionHandler?()
            self?.completionHandler = nil
        }
    }
}

extension RewardedAdManager: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedAd = nil
        completionHandler?()
        completionHandler = nil
        loadAd()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
        loadAd()
        // Note: completionHandler is NOT called here
        // It only fires inside the reward block above (user must watch fully)
    }
}
