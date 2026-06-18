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

    func configure(rootViewController: UIViewController, adUnitID: String = "ca-app-pub-3940256099942544/2934735716") {
        self.rootVC = rootViewController

        bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        bannerView.load(Request())
    }
}
