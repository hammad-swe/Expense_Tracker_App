//
//  BannerAdView.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 18/06/2026.
//

import UIKit
import GoogleMobileAds

class BannerAdView: UIView {
    
    private var bannerView: BannerView!
    private weak var rootVC: UIViewController?
    
    func configure(rootViewController: UIViewController,
                   adUnitID: String = "ca-app-pub-3940256099942544/2934735716") {
        self.rootVC = rootViewController
        
        bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        bannerView.delegate = self                           // ✅ Add delegate
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.isHidden = true                                 // ✅ Hide until ad loads
        
        addSubview(bannerView)
        
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        bannerView.load(Request())                        // ✅ GADRequest()
    }
}

// MARK: - BannerViewDelegate
extension BannerAdView: BannerViewDelegate {
    
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("✅ Banner ad loaded")
        self.isHidden = false                                // ✅ Show when ready
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("❌ Banner ad failed: \(error.localizedDescription)")
        self.isHidden = true                                 // ✅ Hide on failure
    }
}
