//
//  DashBoardViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 02/06/2026.
//

import UIKit
import Charts
import DGCharts
import FirebaseAuth

class DashBoardViewController: UIViewController {
    
    // MARK: - Preserved XIB Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var card1: UIStackView!
    @IBOutlet weak var card2: UIStackView!
    @IBOutlet weak var card3: UIStackView!
    @IBOutlet weak var addbutton: UIButton!
    @IBOutlet weak var totalBudgetLabel: UILabel!
    @IBOutlet weak var remainingLabel: UILabel!
    @IBOutlet weak var totalSpentLabel: UILabel!
    @IBOutlet weak var budgetUsageLabel: UILabel!
    @IBOutlet weak var spentVsRemainingChartView: PieChartView!
    @IBOutlet weak var recentTableView: UITableView!
    
    @IBOutlet weak var bannerContainerView: BannerAdView!
    
    // MARK: - Modern Programmatic UI Components
    private let mainStackView = UIStackView()
    
    // Header
    private let greetingSubLabel = UILabel()
    private let greetingTitleLabel = UILabel()
    private let monthBadgeButton = UIButton(type: .system)
    
    // Hero Balance Card
    private let heroCardView = UIView()
    private let heroGradientLayer = CAGradientLayer()
    private let decorativeCircle1 = UIView()
    private let decorativeCircle2 = UIView()
    private let heroStatusPill = UILabel()
    private let heroProgressTrack = UIView()
    private let heroProgressFill = UIView()
    private var heroProgressWidthConstraint: NSLayoutConstraint?
    private let heroPercentageLabel = UILabel()
    
    // Side-by-side Stat Cards
    private let budgetMiniCard = UIView()
    private let spentMiniCard = UIView()
    
    // Chart Section Card
    private let chartContainerCard = UIView()
    private let chartLegendSpentDot = UIView()
    private let chartLegendRemainingDot = UIView()
    private let chartLegendSpentValue = UILabel()
    private let chartLegendRemainingValue = UILabel()
    
    // Recent Transactions Section
    private let recentContainerCard = UIView()
    private let emptyRecentView = UIView()
    private var recentTableHeightConstraint: NSLayoutConstraint?
    
    // Pull to Refresh & State
    private let refreshControl = UIRefreshControl()
    private var hasAnimatedInitialLoad = false
    private let fabGradientLayer = CAGradientLayer()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setupCardTap()
        setupRecentTableView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(currencyChanged),
            name: CurrencyManager.notificationName,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        bannerContainerView.configure(rootViewController: self)
        updateGreetingHeader()
        refreshDashboardLabels()
        showBudget()
        
        if !hasAnimatedInitialLoad {
            hasAnimatedInitialLoad = true
            animateDashboardEntrance()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        heroGradientLayer.frame = heroCardView.bounds
        fabGradientLayer.frame = addbutton.bounds
        addbutton.layer.cornerRadius = addbutton.bounds.height / 2
        
        updateProgressBarWidth(animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Data & Budget Logic
    
    func showBudget() {
        let manager = CoreDataManager.shared
        let expenses = manager.fetchExpenses()
        let visibleCount = min(expenses.count, 3)
        
        if manager.fetchCurrentBudget() != nil {
            let spent     = manager.totalSpent()
            let remaining = manager.remainingBalance()
            let overBudget = manager.isOverBudget()
            
            remainingLabel.textColor = .white
            heroGradientLayer.colors = overBudget ? Theme.overBudgetGradientColors : Theme.heroGradientColors
            
            if overBudget {
                heroStatusPill.text = "  ⚠️ Over Budget  "
                heroStatusPill.backgroundColor = UIColor.white.withAlphaComponent(0.22)
                heroProgressFill.backgroundColor = .white
            } else {
                let pct = Int(manager.spentPercentage() * 100)
                heroStatusPill.text = pct > 80 ? "  ⚡ Near Limit  " : "  ✓ On Track  "
                heroStatusPill.backgroundColor = UIColor.white.withAlphaComponent(0.18)
                heroProgressFill.backgroundColor = .white
            }
            
            if spentVsRemainingChartView != nil {
                setupSpentVsRemainingChart(spent: spent, remaining: max(remaining, 0))
            }
        } else {
            heroGradientLayer.colors = Theme.heroGradientColors
            heroStatusPill.text = "  Tap to Set Budget  "
            heroStatusPill.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            
            if spentVsRemainingChartView != nil {
                setupSpentVsRemainingChart(spent: 0, remaining: 0)
            }
        }
        
        // Toggle Empty State vs TableView
        let isEmpty = visibleCount == 0
        emptyRecentView.isHidden = !isEmpty
        recentTableView.isHidden = isEmpty
        recentTableHeightConstraint?.constant = isEmpty ? 150 : CGFloat(visibleCount * 84)
        
        recentTableView.reloadData()
        updateProgressBarWidth(animated: true)
    }
    
    @objc func currencyChanged() {
        refreshDashboardLabels()
        showBudget()
    }
    
    @objc private func handlePullToRefresh() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        updateGreetingHeader()
        refreshDashboardLabels()
        showBudget()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    func refreshDashboardLabels() {
        let totalPKR     = CoreDataManager.shared.fetchCurrentBudget()?.totalAmount ?? 0
        let spentPKR     = CoreDataManager.shared.totalSpent()
        let remainingPKR = CoreDataManager.shared.remainingBalance()
        
        let totalStr     = CurrencyManager.shared.displayString(forPKRAmount: totalPKR)
        let spentStr     = CurrencyManager.shared.displayString(forPKRAmount: spentPKR)
        let remainingStr = CurrencyManager.shared.displayString(forPKRAmount: remainingPKR)
        
        totalBudgetLabel.text = totalStr
        totalSpentLabel.text  = spentStr
        remainingLabel.text   = remainingStr
        
        budgetUsageLabel.text = "\(spentStr) spent of \(totalStr)"
        
        let pct = min(max(Int(CoreDataManager.shared.spentPercentage() * 100), 0), 999)
        heroPercentageLabel.text = "\(pct)%"
        
        chartLegendSpentValue.text = spentStr
        chartLegendRemainingValue.text = CurrencyManager.shared.displayString(forPKRAmount: max(remainingPKR, 0))
    }
    
    private func updateGreetingHeader() {
        let info = Theme.timeBasedGreeting()
        greetingSubLabel.text = info.greeting.uppercased()
        
        if let displayName = AuthManager.shared.currentUser?.displayName, !displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            greetingTitleLabel.text = "Hi, \(displayName) 👋"
        } else {
            greetingTitleLabel.text = "My Finances 👋"
        }
        
        var config = UIButton.Configuration.filled()
        config.title = Theme.currentMonthYearString()
        config.image = UIImage(systemName: "calendar")
        config.imagePadding = 6
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        config.baseBackgroundColor = Theme.primaryIndigo.withAlphaComponent(0.12)
        config.baseForegroundColor = Theme.primaryIndigo
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            return out
        }
        monthBadgeButton.configuration = config
    }
    
    private func updateProgressBarWidth(animated: Bool) {
        let trackWidth = heroProgressTrack.bounds.width
        guard trackWidth > 0 else { return }
        
        let rawPct = CGFloat(CoreDataManager.shared.spentPercentage())
        let clampedPct = min(max(rawPct, 0.0), 1.0)
        let targetWidth = trackWidth * clampedPct
        
        heroProgressWidthConstraint?.constant = targetWidth
        if animated {
            UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.3, options: .curveEaseOut) {
                self.heroProgressTrack.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Recent Expenses Table
    
    func setupRecentTableView() {
        let nib = UINib(nibName: "ExpenseCell", bundle: nil)
        recentTableView.register(nib, forCellReuseIdentifier: "ExpenseCell")
        recentTableView.delegate        = self
        recentTableView.dataSource      = self
        recentTableView.separatorStyle  = .none
        recentTableView.isScrollEnabled = false
        recentTableView.backgroundColor = .clear
    }
    
    // MARK: - Pie Chart
    
    func setupSpentVsRemainingChart(spent: Double, remaining: Double) {
        guard spent > 0 || remaining > 0 else {
            spentVsRemainingChartView.data = nil
            let emptyText = NSMutableAttributedString(
                string: "No Data\n",
                attributes: [
                    .foregroundColor: UIColor.label,
                    .font: UIFont.systemFont(ofSize: 15, weight: .bold)
                ]
            )
            emptyText.append(NSAttributedString(
                string: "Add budget or expense",
                attributes: [
                    .foregroundColor: UIColor.secondaryLabel,
                    .font: UIFont.systemFont(ofSize: 11, weight: .medium)
                ]
            ))
            spentVsRemainingChartView.centerAttributedText = emptyText
            spentVsRemainingChartView.holeRadiusPercent = 0.72
            spentVsRemainingChartView.holeColor = .clear
            spentVsRemainingChartView.notifyDataSetChanged()
            return
        }
        
        let entries = [
            PieChartDataEntry(value: spent, label: "Spent"),
            PieChartDataEntry(value: remaining, label: "Remaining")
        ]
        
        let dataSet = PieChartDataSet(entries: entries, label: "")
        let isOver = CoreDataManager.shared.isOverBudget()
        let spentColor = isOver ? Theme.coralRed : Theme.primaryIndigo
        let remainingColor = UIColor.systemGray5
        
        dataSet.colors               = [spentColor, remainingColor]
        dataSet.sliceSpace           = 4
        dataSet.selectionShift       = 5
        dataSet.drawValuesEnabled    = false
        
        chartLegendSpentDot.backgroundColor = spentColor
        chartLegendRemainingDot.backgroundColor = Theme.emeraldGreen
        
        let data = PieChartData(dataSet: dataSet)
        data.setValueFormatter(CurrencyValueFormatter())
        
        let percentage = min(max(Int(CoreDataManager.shared.spentPercentage() * 100), 0), 999)
        let centerAttr = NSMutableAttributedString(
            string: "\(percentage)%\n",
            attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 24, weight: .heavy)
            ]
        )
        centerAttr.append(NSAttributedString(
            string: "USED",
            attributes: [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .kern: 1.2
            ]
        ))
        
        spentVsRemainingChartView.data                           = data
        spentVsRemainingChartView.holeRadiusPercent              = 0.72
        spentVsRemainingChartView.holeColor                      = .clear
        spentVsRemainingChartView.transparentCircleRadiusPercent = 0.76
        spentVsRemainingChartView.transparentCircleColor         = spentColor.withAlphaComponent(0.08)
        spentVsRemainingChartView.centerAttributedText           = centerAttr
        spentVsRemainingChartView.drawEntryLabelsEnabled         = false
        spentVsRemainingChartView.usePercentValuesEnabled        = false
        spentVsRemainingChartView.rotationEnabled                = true
        spentVsRemainingChartView.highlightPerTapEnabled         = true
        spentVsRemainingChartView.legend.enabled                 = false
        
        spentVsRemainingChartView.animate(xAxisDuration: 0.75, easingOption: .easeOutCubic)
        spentVsRemainingChartView.notifyDataSetChanged()
    }
    
    // MARK: - Format Amount
    
    func formatAmount(_ amount: Double) -> String {
        let formatter                   = NumberFormatter()
        formatter.numberStyle           = .decimal
        formatter.groupingSeparator     = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    // MARK: - Gestures & Actions
    
    func setupCardTap() {
        let heroTap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        heroCardView.addGestureRecognizer(heroTap)
        heroCardView.isUserInteractionEnabled = true
        
        let budgetTap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        budgetMiniCard.addGestureRecognizer(budgetTap)
        budgetMiniCard.isUserInteractionEnabled = true
        
        let spentTap = UITapGestureRecognizer(target: self, action: #selector(viewAllTapped(_:)))
        spentMiniCard.addGestureRecognizer(spentTap)
        spentMiniCard.isUserInteractionEnabled = true
    }
    
    @objc func cardTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        let VC = SetBudgetViewController()
        VC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(VC, animated: true)
    }
    
    @IBAction func addTapped(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.12, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.18) {
                sender.transform = .identity
            }
        }
        
        InterstitialAdManager.shared.showAdIfAvailable(from: self) { [weak self] in
            let vc = AddExpenseViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func viewAllTapped(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        let VC = ExpenseListViewController()
        VC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(VC, animated: true)
    }
    
    // MARK: - Complete Modern UI Construction
    
    private func setUpUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = Theme.screenBackground
        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        
        // Pull to refresh
        refreshControl.tintColor = Theme.primaryIndigo
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        // Detach old XIB subviews inside contentView while preserving IBOutlet references
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Configure Main Vertical Stack
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -100)
        ])
        
        // Build Dashboard Sections
        mainStackView.addArrangedSubview(buildHeaderSection())
        mainStackView.addArrangedSubview(buildHeroBalanceCard())
        mainStackView.addArrangedSubview(buildMiniStatsRow())
        mainStackView.addArrangedSubview(buildAnalyticsCard())
        mainStackView.addArrangedSubview(buildRecentTransactionsSection())
        
        styleFloatingActionButton()
    }
    
    private func buildHeaderSection() -> UIView {
        let container = UIView()
        
        greetingSubLabel.font = .systemFont(ofSize: 11, weight: .bold)
        greetingSubLabel.textColor = .secondaryLabel
        
        greetingTitleLabel.font = .systemFont(ofSize: 24, weight: .heavy)
        greetingTitleLabel.textColor = .label
        
        let leftStack = UIStackView(arrangedSubviews: [greetingSubLabel, greetingTitleLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 2
        
        monthBadgeButton.addTarget(self, action: #selector(cardTapped), for: .touchUpInside)
        monthBadgeButton.setContentHuggingPriority(.required, for: .horizontal)
        
        let hStack = UIStackView(arrangedSubviews: [leftStack, monthBadgeButton])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])
        return container
    }
    
    private func buildHeroBalanceCard() -> UIView {
        heroCardView.layer.cornerRadius = 24
        heroCardView.clipsToBounds = true
        heroCardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Gradient background
        heroGradientLayer.colors = Theme.heroGradientColors
        heroGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        heroGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        heroCardView.layer.insertSublayer(heroGradientLayer, at: 0)
        
        // Subtle decorative glass circles
        decorativeCircle1.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        decorativeCircle1.layer.cornerRadius = 75
        decorativeCircle1.translatesAutoresizingMaskIntoConstraints = false
        decorativeCircle1.isUserInteractionEnabled = false
        heroCardView.addSubview(decorativeCircle1)
        
        decorativeCircle2.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        decorativeCircle2.layer.cornerRadius = 55
        decorativeCircle2.translatesAutoresizingMaskIntoConstraints = false
        decorativeCircle2.isUserInteractionEnabled = false
        heroCardView.addSubview(decorativeCircle2)
        
        // Top row: Caption + Status Pill
        let titleCaption = UILabel()
        titleCaption.text = "REMAINING BALANCE"
        titleCaption.font = .systemFont(ofSize: 11, weight: .bold)
        titleCaption.textColor = UIColor.white.withAlphaComponent(0.75)
        
        heroStatusPill.font = .systemFont(ofSize: 11, weight: .bold)
        heroStatusPill.textColor = .white
        heroStatusPill.layer.cornerRadius = 11
        heroStatusPill.clipsToBounds = true
        heroStatusPill.setContentHuggingPriority(.required, for: .horizontal)
        
        let topRow = UIStackView(arrangedSubviews: [titleCaption, heroStatusPill])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.distribution = .equalSpacing
        
        // Main Balance Amount (re-using remainingLabel outlet)
        remainingLabel.removeFromSuperview()
        remainingLabel.font = .systemFont(ofSize: 34, weight: .heavy)
        remainingLabel.textColor = .white
        remainingLabel.adjustsFontSizeToFitWidth = true
        remainingLabel.minimumScaleFactor = 0.65
        
        // Progress Bar Track & Fill
        heroProgressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.20)
        heroProgressTrack.layer.cornerRadius = 4
        heroProgressTrack.clipsToBounds = true
        heroProgressTrack.translatesAutoresizingMaskIntoConstraints = false
        heroProgressTrack.heightAnchor.constraint(equalToConstant: 8).isActive = true
        
        heroProgressFill.backgroundColor = .white
        heroProgressFill.layer.cornerRadius = 4
        heroProgressFill.translatesAutoresizingMaskIntoConstraints = false
        heroProgressTrack.addSubview(heroProgressFill)
        
        let widthConstraint = heroProgressFill.widthAnchor.constraint(equalToConstant: 0)
        heroProgressWidthConstraint = widthConstraint
        NSLayoutConstraint.activate([
            heroProgressFill.leadingAnchor.constraint(equalTo: heroProgressTrack.leadingAnchor),
            heroProgressFill.topAnchor.constraint(equalTo: heroProgressTrack.topAnchor),
            heroProgressFill.bottomAnchor.constraint(equalTo: heroProgressTrack.bottomAnchor),
            widthConstraint
        ])
        
        // Bottom row: budgetUsageLabel + percentage + edit chevron
        budgetUsageLabel.removeFromSuperview()
        budgetUsageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        budgetUsageLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        budgetUsageLabel.textAlignment = .left
        
        heroPercentageLabel.font = .systemFont(ofSize: 13, weight: .bold)
        heroPercentageLabel.textColor = .white
        heroPercentageLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        let bottomRow = UIStackView(arrangedSubviews: [budgetUsageLabel, heroPercentageLabel])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.distribution = .fill
        
        let vStack = UIStackView(arrangedSubviews: [topRow, remainingLabel, heroProgressTrack, bottomRow])
        vStack.axis = .vertical
        vStack.spacing = 12
        vStack.setCustomSpacing(16, after: remainingLabel)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.isUserInteractionEnabled = false
        
        heroCardView.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            decorativeCircle1.widthAnchor.constraint(equalToConstant: 150),
            decorativeCircle1.heightAnchor.constraint(equalToConstant: 150),
            decorativeCircle1.topAnchor.constraint(equalTo: heroCardView.topAnchor, constant: -50),
            decorativeCircle1.trailingAnchor.constraint(equalTo: heroCardView.trailingAnchor, constant: 40),
            
            decorativeCircle2.widthAnchor.constraint(equalToConstant: 110),
            decorativeCircle2.heightAnchor.constraint(equalToConstant: 110),
            decorativeCircle2.bottomAnchor.constraint(equalTo: heroCardView.bottomAnchor, constant: 45),
            decorativeCircle2.trailingAnchor.constraint(equalTo: heroCardView.trailingAnchor, constant: -20),
            
            vStack.topAnchor.constraint(equalTo: heroCardView.topAnchor, constant: 22),
            vStack.leadingAnchor.constraint(equalTo: heroCardView.leadingAnchor, constant: 22),
            vStack.trailingAnchor.constraint(equalTo: heroCardView.trailingAnchor, constant: -22),
            vStack.bottomAnchor.constraint(equalTo: heroCardView.bottomAnchor, constant: -22)
        ])
        
        // Outer wrapper for shadow
        let shadowWrapper = UIView()
        shadowWrapper.layer.shadowColor = Theme.primaryIndigo.cgColor
        shadowWrapper.layer.shadowOpacity = 0.28
        shadowWrapper.layer.shadowOffset = CGSize(width: 0, height: 10)
        shadowWrapper.layer.shadowRadius = 18
        shadowWrapper.addSubview(heroCardView)
        
        NSLayoutConstraint.activate([
            heroCardView.topAnchor.constraint(equalTo: shadowWrapper.topAnchor),
            heroCardView.leadingAnchor.constraint(equalTo: shadowWrapper.leadingAnchor),
            heroCardView.trailingAnchor.constraint(equalTo: shadowWrapper.trailingAnchor),
            heroCardView.bottomAnchor.constraint(equalTo: shadowWrapper.bottomAnchor)
        ])
        
        return shadowWrapper
    }
    
    private func buildMiniStatsRow() -> UIView {
        // Monthly Budget Mini Card (re-using totalBudgetLabel)
        totalBudgetLabel.removeFromSuperview()
        configureMiniStatCard(
            card: budgetMiniCard,
            title: "Monthly Budget",
            subtitle: "Tap to edit",
            valueLabel: totalBudgetLabel,
            iconName: "arrow.down.left.circle.fill",
            tintColor: Theme.emeraldGreen
        )
        
        // Total Expenses Mini Card (re-using totalSpentLabel)
        totalSpentLabel.removeFromSuperview()
        configureMiniStatCard(
            card: spentMiniCard,
            title: "Total Spent",
            subtitle: "This month",
            valueLabel: totalSpentLabel,
            iconName: "arrow.up.right.circle.fill",
            tintColor: Theme.coralRed
        )
        
        let rowStack = UIStackView(arrangedSubviews: [budgetMiniCard, spentMiniCard])
        rowStack.axis = .horizontal
        rowStack.spacing = 14
        rowStack.distribution = .fillEqually
        return rowStack
    }
    
    private func configureMiniStatCard(
        card: UIView,
        title: String,
        subtitle: String,
        valueLabel: UILabel,
        iconName: String,
        tintColor: UIColor
    ) {
        card.applyElevatedCardStyle(cornerRadius: 20)
        
        let iconBadge = UIView()
        iconBadge.backgroundColor = tintColor.withAlphaComponent(0.14)
        iconBadge.layer.cornerRadius = 19
        iconBadge.translatesAutoresizingMaskIntoConstraints = false
        iconBadge.widthAnchor.constraint(equalToConstant: 38).isActive = true
        iconBadge.heightAnchor.constraint(equalToConstant: 38).isActive = true
        
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBadge.addSubview(iconView)
        
        let subCaption = UILabel()
        subCaption.text = subtitle
        subCaption.font = .systemFont(ofSize: 10, weight: .semibold)
        subCaption.textColor = .tertiaryLabel
        
        let topBar = UIStackView(arrangedSubviews: [iconBadge, subCaption])
        topBar.axis = .horizontal
        topBar.alignment = .center
        topBar.distribution = .equalSpacing
        
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 12, weight: .medium)
        titleLbl.textColor = .secondaryLabel
        
        valueLabel.font = .systemFont(ofSize: 19, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        
        let vStack = UIStackView(arrangedSubviews: [topBar, titleLbl, valueLabel])
        vStack.axis = .vertical
        vStack.spacing = 6
        vStack.setCustomSpacing(12, after: topBar)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.isUserInteractionEnabled = false
        card.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }
    
    private func buildAnalyticsCard() -> UIView {
        chartContainerCard.applyElevatedCardStyle(cornerRadius: 22)
        
        let sectionTitle = UILabel()
        sectionTitle.text = "Spending Breakdown"
        sectionTitle.font = .systemFont(ofSize: 17, weight: .bold)
        sectionTitle.textColor = .label
        
        let sectionSubtitle = UILabel()
        sectionSubtitle.text = "Visualizing your budget utilization"
        sectionSubtitle.font = .systemFont(ofSize: 12, weight: .regular)
        sectionSubtitle.textColor = .secondaryLabel
        
        let headerStack = UIStackView(arrangedSubviews: [sectionTitle, sectionSubtitle])
        headerStack.axis = .vertical
        headerStack.spacing = 2
        
        // Re-use spentVsRemainingChartView from XIB
        spentVsRemainingChartView.removeFromSuperview()
        spentVsRemainingChartView.backgroundColor = .clear
        spentVsRemainingChartView.translatesAutoresizingMaskIntoConstraints = false
        // Remove old rigid XIB size constraints on chart view
        spentVsRemainingChartView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                spentVsRemainingChartView.removeConstraint(constraint)
            }
        }
        spentVsRemainingChartView.heightAnchor.constraint(equalToConstant: 190).isActive = true
        
        // Custom Legend Row
        let spentLegendItem = buildLegendItem(
            dot: chartLegendSpentDot,
            title: "Spent",
            valueLabel: chartLegendSpentValue,
            defaultColor: Theme.primaryIndigo
        )
        let remainingLegendItem = buildLegendItem(
            dot: chartLegendRemainingDot,
            title: "Remaining",
            valueLabel: chartLegendRemainingValue,
            defaultColor: Theme.emeraldGreen
        )
        
        let legendStack = UIStackView(arrangedSubviews: [spentLegendItem, remainingLegendItem])
        legendStack.axis = .horizontal
        legendStack.distribution = .fillEqually
        legendStack.spacing = 12
        
        let cardStack = UIStackView(arrangedSubviews: [headerStack, spentVsRemainingChartView, legendStack])
        cardStack.axis = .vertical
        cardStack.spacing = 12
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        
        chartContainerCard.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: chartContainerCard.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: chartContainerCard.leadingAnchor, constant: 18),
            cardStack.trailingAnchor.constraint(equalTo: chartContainerCard.trailingAnchor, constant: -18),
            cardStack.bottomAnchor.constraint(equalTo: chartContainerCard.bottomAnchor, constant: -18)
        ])
        
        return chartContainerCard
    }
    
    private func buildLegendItem(dot: UIView, title: String, valueLabel: UILabel, defaultColor: UIColor) -> UIView {
        let box = UIView()
        box.backgroundColor = UIColor.secondarySystemFill.withAlphaComponent(0.5)
        box.layer.cornerRadius = 12
        
        dot.backgroundColor = defaultColor
        dot.layer.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        let lbl = UILabel()
        lbl.text = title
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = .secondaryLabel
        
        let topH = UIStackView(arrangedSubviews: [dot, lbl])
        topH.axis = .horizontal
        topH.spacing = 6
        topH.alignment = .center
        
        valueLabel.font = .systemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = .label
        
        let vStack = UIStackView(arrangedSubviews: [topH, valueLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        box.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: box.topAnchor, constant: 10),
            vStack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            vStack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),
            vStack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -10)
        ])
        return box
    }
    
    private func buildRecentTransactionsSection() -> UIView {
        let wrapper = UIView()
        
        let titleLbl = UILabel()
        titleLbl.text = "Recent Transactions"
        titleLbl.font = .systemFont(ofSize: 18, weight: .bold)
        titleLbl.textColor = .label
        
        let seeAllBtn = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "See All"
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 4
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        config.baseForegroundColor = Theme.primaryIndigo
        config.contentInsets = .zero
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            return out
        }
        seeAllBtn.configuration = config
        seeAllBtn.addTarget(self, action: #selector(viewAllTapped(_:)), for: .touchUpInside)
        
        let headerRow = UIStackView(arrangedSubviews: [titleLbl, seeAllBtn])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .equalSpacing
        
        // Re-use recentTableView from XIB
        recentTableView.removeFromSuperview()
        recentTableView.translatesAutoresizingMaskIntoConstraints = false
        recentTableView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                recentTableView.removeConstraint(constraint)
            }
        }
        let heightConstraint = recentTableView.heightAnchor.constraint(equalToConstant: 240)
        recentTableHeightConstraint = heightConstraint
        heightConstraint.isActive = true
        
        // Friendly Empty State View
        setupEmptyRecentView()
        
        let contentStack = UIStackView(arrangedSubviews: [headerRow, emptyRecentView, recentTableView])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        wrapper.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: wrapper.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        
        return wrapper
    }
    
    private func setupEmptyRecentView() {
        emptyRecentView.applyElevatedCardStyle(cornerRadius: 20)
        emptyRecentView.translatesAutoresizingMaskIntoConstraints = false
        emptyRecentView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        let iconView = UIImageView(image: UIImage(systemName: "tray.and.arrow.down.fill"))
        iconView.tintColor = Theme.primaryIndigo.withAlphaComponent(0.6)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.heightAnchor.constraint(equalToConstant: 34).isActive = true
        iconView.widthAnchor.constraint(equalToConstant: 34).isActive = true
        
        let titleLbl = UILabel()
        titleLbl.text = "No Expenses Recorded Yet"
        titleLbl.font = .systemFont(ofSize: 15, weight: .bold)
        titleLbl.textColor = .label
        
        let subLbl = UILabel()
        subLbl.text = "Tap the + button below to log your first expense."
        subLbl.font = .systemFont(ofSize: 12, weight: .regular)
        subLbl.textColor = .secondaryLabel
        subLbl.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [iconView, titleLbl, subLbl])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        emptyRecentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: emptyRecentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyRecentView.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: emptyRecentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: emptyRecentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func styleFloatingActionButton() {
        addbutton.backgroundColor = Theme.primaryIndigo
        addbutton.layer.masksToBounds = false
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        addbutton.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig), for: .normal)
        addbutton.tintColor = .white
        
        addbutton.layer.shadowColor = Theme.primaryIndigo.cgColor
        addbutton.layer.shadowOpacity = 0.42
        addbutton.layer.shadowOffset = CGSize(width: 0, height: 8)
        addbutton.layer.shadowRadius = 14
    }
    
    // MARK: - Entrance Animation
    
    private func animateDashboardEntrance() {
        let views = mainStackView.arrangedSubviews
        for (index, subview) in views.enumerated() {
            subview.alpha = 0
            subview.transform = CGAffineTransform(translationX: 0, y: 18)
            UIView.animate(
                withDuration: 0.5,
                delay: Double(index) * 0.06,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.3,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    subview.alpha = 1
                    subview.transform = .identity
                }
            )
        }
    }
    
    // MARK: - Dynamic Currency Value Formatter
    
    class CurrencyValueFormatter: NSObject, ValueFormatter {
        func stringForValue(_ value: Double,
                            entry: ChartDataEntry,
                            dataSetIndex: Int,
                            viewPortHandler: ViewPortHandler?) -> String {
            return CurrencyManager.shared.displayString(forPKRAmount: value)
        }
    }
}

// MARK: - TableView
extension DashBoardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        let expenses = CoreDataManager.shared.fetchExpenses()
        return min(expenses.count, 3)
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ExpenseCell",
            for: indexPath
        ) as! ExpenseCell
        let expenses = CoreDataManager.shared.fetchExpenses()
        cell.configure(with: expenses[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let vc = ExpenseListViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
