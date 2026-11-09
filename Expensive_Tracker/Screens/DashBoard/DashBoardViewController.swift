//
//  DashBoardViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 02/06/2026.
//

import UIKit
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
    
    // MARK: - State
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
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
        refreshDashboardLabels()
        showBudget()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Dashboard"
        view.backgroundColor = .systemGroupedBackground
        
        // Pull to refresh
        refreshControl.tintColor = .systemBlue
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
        // Configure floating action button shadow
        addbutton.layer.shadowColor = UIColor.black.cgColor
        addbutton.layer.shadowOpacity = 0.25
        addbutton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addbutton.layer.shadowRadius = 8
        addbutton.layer.masksToBounds = false
    }
    
    func setupRecentTableView() {
        let nib = UINib(nibName: "ExpenseCell", bundle: nil)
        recentTableView.register(nib, forCellReuseIdentifier: "ExpenseCell")
        recentTableView.delegate = self
        recentTableView.dataSource = self
        recentTableView.isScrollEnabled = false
    }
    
    func setupCardTap() {
        let budgetTap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        card1.addGestureRecognizer(budgetTap)
        card1.isUserInteractionEnabled = true
        
        let remainingTap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        card2.addGestureRecognizer(remainingTap)
        card2.isUserInteractionEnabled = true
        
        let spentTap = UITapGestureRecognizer(target: self, action: #selector(viewAllTapped(_:)))
        card3.addGestureRecognizer(spentTap)
        card3.isUserInteractionEnabled = true
    }
    
    // MARK: - Actions
    @objc func cardTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        let vc = SetBudgetViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func addTapped(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.12, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
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
        
        let vc = ExpenseListViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func handlePullToRefresh() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        refreshDashboardLabels()
        showBudget()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    @objc func currencyChanged() {
        refreshDashboardLabels()
        showBudget()
    }
    
    // MARK: - Data Binding
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
        
        budgetUsageLabel.text = "\(spentStr) out of \(totalStr)"
    }
    
    func showBudget() {
        let manager = CoreDataManager.shared
        
        if manager.fetchCurrentBudget() != nil {
            let spent = manager.totalSpent()
            let remaining = manager.remainingBalance()
            let overBudget = manager.isOverBudget()
            
            remainingLabel.textColor = overBudget ? .systemRed : .label
            
            if spentVsRemainingChartView != nil {
                setupSpentVsRemainingChart(spent: spent, remaining: max(remaining, 0))
            }
        } else {
            remainingLabel.textColor = .label
            if spentVsRemainingChartView != nil {
                setupSpentVsRemainingChart(spent: 0, remaining: 0)
            }
        }
        
        recentTableView.reloadData()
    }
    
    // MARK: - Pie Chart Setup
    func setupSpentVsRemainingChart(spent: Double, remaining: Double) {
        guard spent > 0 || remaining > 0 else {
            spentVsRemainingChartView.data = nil
            let emptyText = NSMutableAttributedString(
                string: "No Data\n",
                attributes: [
                    .foregroundColor: UIColor.label,
                    .font: UIFont.systemFont(ofSize: 16, weight: .bold)
                ]
            )
            emptyText.append(NSAttributedString(
                string: "Set budget or add expense",
                attributes: [
                    .foregroundColor: UIColor.secondaryLabel,
                    .font: UIFont.systemFont(ofSize: 12, weight: .medium)
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
        let spentColor = isOver ? UIColor.systemRed : UIColor.systemBlue
        let remainingColor = UIColor.systemGray5
        
        dataSet.colors = [spentColor, remainingColor]
        dataSet.sliceSpace = 3
        dataSet.selectionShift = 4
        dataSet.drawValuesEnabled = false
        
        let data = PieChartData(dataSet: dataSet)
        data.setValueFormatter(CurrencyValueFormatter())
        
        let percentage = min(max(Int(CoreDataManager.shared.spentPercentage() * 100), 0), 999)
        let centerAttr = NSMutableAttributedString(
            string: "\(percentage)%\n",
            attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 26, weight: .bold)
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
        
        spentVsRemainingChartView.data = data
        spentVsRemainingChartView.holeRadiusPercent = 0.72
        spentVsRemainingChartView.holeColor = .clear
        spentVsRemainingChartView.transparentCircleRadiusPercent = 0.76
        spentVsRemainingChartView.transparentCircleColor = spentColor.withAlphaComponent(0.08)
        spentVsRemainingChartView.centerAttributedText = centerAttr
        spentVsRemainingChartView.drawEntryLabelsEnabled = false
        spentVsRemainingChartView.usePercentValuesEnabled = false
        spentVsRemainingChartView.rotationEnabled = true
        spentVsRemainingChartView.highlightPerTapEnabled = true
        spentVsRemainingChartView.legend.enabled = false
        
        spentVsRemainingChartView.animate(xAxisDuration: 0.65, easingOption: .easeOutCubic)
        spentVsRemainingChartView.notifyDataSetChanged()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let expenses = CoreDataManager.shared.fetchExpenses()
        return min(expenses.count, 3)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ExpenseCell",
            for: indexPath
        ) as! ExpenseCell
        let expenses = CoreDataManager.shared.fetchExpenses()
        cell.configure(with: expenses[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ExpenseListViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
