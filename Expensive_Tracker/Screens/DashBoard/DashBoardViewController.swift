//
//  DashBoardViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 02/06/2026.
//

import UIKit
import Charts
import DGCharts

class DashBoardViewController: UIViewController {
    
    
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
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("scrollView: \(String(describing: scrollView))")
            print("spentVsRemainingChartView: \(String(describing: spentVsRemainingChartView))")
            print("totalBudgetLabel: \(String(describing: totalBudgetLabel))")
            print("remainingLabel: \(String(describing: remainingLabel))")
            print("totalSpentLabel: \(String(describing: totalSpentLabel))")
        
        setUpUI()
        setupCardTap()
        NotificationCenter.default.addObserver(self, selector: #selector(currencyChanged), name: CurrencyManager.notificationName, object: nil)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showBudget() // ✅ Refreshes every time you come back to dashboard
        refreshDashboardLabels()
        setupRecentTableView()
    }
    
    func showBudget() {
        let manager = CoreDataManager.shared
            
            if let budget = manager.fetchCurrentBudget() {
                let spent     = manager.totalSpent()
                let remaining = manager.remainingBalance()

                totalBudgetLabel.text = "Rs \(String(format: "%.0f", budget.totalAmount))"
                totalSpentLabel.text  = "Rs \(String(format: "%.0f", spent))"
                remainingLabel.text   = "Rs \(String(format: "%.0f", remaining))"

                budgetUsageLabel.text = "PKR \(formatAmount(spent)) out of PKR \(formatAmount(budget.totalAmount))"
                // ✅ Color indicator
                remainingLabel.textColor = manager.isOverBudget() ? .red : .white
                
                if spentVsRemainingChartView != nil {
                            setupSpentVsRemainingChart(spent: spent, remaining: max(remaining, 0))
                        }
                
            } else {
                totalBudgetLabel.text = "No Budget Set"
                totalSpentLabel.text  = "Rs 0"
                remainingLabel.text   = "Rs 0"
                
                if spentVsRemainingChartView != nil {
                            setupSpentVsRemainingChart(spent: 0, remaining: 0)
                        }
            }
        recentTableView.reloadData()
    }
    
    @objc func currencyChanged() {
        refreshDashboardLabels()
    }
    
    func refreshDashboardLabels() {
        // ✅ All three values are ALWAYS stored/calculated in PKR under the hood
        let totalPKR = CoreDataManager.shared.fetchCurrentBudget()?.totalAmount ?? 0
        let spentPKR = CoreDataManager.shared.totalSpent()
        let remainingPKR = CoreDataManager.shared.remainingBalance()

        // ✅ Convert only for display, in whatever currency is currently selected
        totalBudgetLabel.text  = CurrencyManager.shared.displayString(forPKRAmount: totalPKR)
        totalSpentLabel.text   = CurrencyManager.shared.displayString(forPKRAmount: spentPKR)
        remainingLabel.text    = CurrencyManager.shared.displayString(forPKRAmount: remainingPKR)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Recent Expenses Table
    func setupRecentTableView() {
        let nib = UINib(nibName: "ExpenseCell", bundle: nil)
        recentTableView.register(nib, forCellReuseIdentifier: "ExpenseCell")
        recentTableView.delegate        = self
        recentTableView.dataSource      = self
        recentTableView.separatorStyle  = .none
        recentTableView.isScrollEnabled = false // ✅ inside scrollview
        recentTableView.backgroundColor = .clear
    }
    
    // MARK: - Pie Chart
        func setupSpentVsRemainingChart(spent: Double, remaining: Double) {
            
            // ✅ Empty state
            guard spent > 0 || remaining > 0 else {
                spentVsRemainingChartView.data = nil
                let noData = NSAttributedString(
                    string: "No Data",
                    attributes: [
                        .foregroundColor: UIColor.label,
                        .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
                    ]
                )
                spentVsRemainingChartView.centerAttributedText = noData
                spentVsRemainingChartView.notifyDataSetChanged()
                return
            }
            
            // ✅ Entries
            let entries = [
                PieChartDataEntry(value: spent     ),
                PieChartDataEntry(value: remaining)
            ]
            
            // ✅ Dataset
            let dataSet = PieChartDataSet(entries: entries, label: "")
            dataSet.colors               = [UIColor.systemBlue, UIColor.systemGray]
            dataSet.sliceSpace           = 3
            dataSet.selectionShift       = 6
            dataSet.valueTextColor       = .white
            dataSet.valueFont            = .systemFont(ofSize: 12, weight: .bold)
            dataSet.xValuePosition       = .outsideSlice
            dataSet.yValuePosition       = .outsideSlice
            dataSet.valueLineColor       = .label
            dataSet.valueLineWidth       = 1.0
            dataSet.valueLinePart1Length = 0.4
            dataSet.valueLinePart2Length = 0.4
            
            // ✅ Data
            let data = PieChartData(dataSet: dataSet)
            data.setValueFormatter(PKRValueFormatter())
            
            // ✅ Center text
            let percentage   = Int(CoreDataManager.shared.spentPercentage() * 100)
            let centerString = "\(percentage)%"
            let attributed   = NSMutableAttributedString(string: centerString)
            attributed.addAttributes([
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 14, weight: .bold)
            ], range: NSRange(location: 0, length: centerString.count))

            spentVsRemainingChartView.centerAttributedText = attributed
            
            // ✅ Chart config
            spentVsRemainingChartView.data                           = data
            spentVsRemainingChartView.holeRadiusPercent              = 0.8
            spentVsRemainingChartView.holeColor                      = .systemBackground
            spentVsRemainingChartView.transparentCircleRadiusPercent = 0.20
            spentVsRemainingChartView.transparentCircleColor         = .systemBackground.withAlphaComponent(0.3)
            spentVsRemainingChartView.centerAttributedText           = attributed
            spentVsRemainingChartView.drawEntryLabelsEnabled         = false
            spentVsRemainingChartView.usePercentValuesEnabled        = false
            spentVsRemainingChartView.rotationEnabled                = false
            spentVsRemainingChartView.highlightPerTapEnabled         = false
            
            // ✅ Legend
            spentVsRemainingChartView.legend.enabled             = false
//            spentVsRemainingChartView.legend.horizontalAlignment = .center
//            spentVsRemainingChartView.legend.verticalAlignment   = .bottom
//            spentVsRemainingChartView.legend.orientation         = .horizontal
//            spentVsRemainingChartView.legend.font                = .systemFont(ofSize: 12)
//            spentVsRemainingChartView.legend.textColor           = .label
//            spentVsRemainingChartView.legend.formSize            = 12
//            spentVsRemainingChartView.legend.formToTextSpace     = 5
//            spentVsRemainingChartView.legend.xEntrySpace         = 15
            
            // ✅ Animation
            spentVsRemainingChartView.animate(xAxisDuration: 0.8, easingOption: .easeInOutQuart)
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
    
    
    func setupCardTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        card1.addGestureRecognizer(tap)
        card1.isUserInteractionEnabled = true // crucial!
    }

    @objc func cardTapped() {
        let VC = SetBudgetViewController() // or load from XIB
        VC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(VC, animated: true)
    }
    
    private func setUpUI(){
        title = "Dashboard"
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        card1.layer.cornerRadius = 12
        card2.layer.cornerRadius = 12
        card3.layer.cornerRadius = 12
        
        styleButton()
    }
    
    private func styleButton() {
        addbutton.layer.cornerRadius =   addbutton.frame.height / 2
        addbutton.layer.masksToBounds = true
        addbutton.backgroundColor = .systemBlue
        addbutton.setImage(UIImage(systemName: "plus"), for: .normal)
        addbutton.tintColor = .white
       }
    
    
    
    @IBAction func addTapped(_ sender: UIButton) {
        
        let vc = AddExpenseViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    @IBAction func viewAllTapped(_ sender: Any) {
        let VC = ExpenseListViewController()
        VC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(VC, animated: true)
    }
    
    
    // MARK: - PKR Value Formatter
    class PKRValueFormatter: NSObject, ValueFormatter {
        func stringForValue(_ value: Double,
                            entry: ChartDataEntry,
                            dataSetIndex: Int,
                            viewPortHandler: ViewPortHandler?) -> String {
            let formatter                   = NumberFormatter()
            formatter.numberStyle           = .decimal
            formatter.maximumFractionDigits = 0
            formatter.groupingSeparator     = ","
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
            return "PKR \(formatted)"
        }
    }
    
}

// MARK: - TableView
extension DashBoardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        // ✅ Show max 3 recent expenses
        let expenses = CoreDataManager.shared.fetchExpenses()
        return min(expenses.count, 3)
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell    = tableView.dequeueReusableCell(
                        withIdentifier: "ExpenseCell",
                        for: indexPath) as! ExpenseCell
        let expenses = CoreDataManager.shared.fetchExpenses()
        cell.configure(with: expenses[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let vc = ExpenseListViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
