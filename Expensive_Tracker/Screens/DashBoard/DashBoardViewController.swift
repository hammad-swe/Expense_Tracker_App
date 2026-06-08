//
//  DashBoardViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 02/06/2026.
//

import UIKit
import DGCharts

class DashBoardViewController: UIViewController {
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var card1: UIStackView!
    @IBOutlet weak var card2: UIStackView!
    @IBOutlet weak var card3: UIStackView!
    @IBOutlet weak var addbutton: UIButton!
 //   @IBOutlet weak var viewallButton: UIButton!
  //  @IBOutlet weak var dashBoardTable: UITableView!
    @IBOutlet weak var totalBudgetLabel: UILabel!
    @IBOutlet weak var remainingLabel: UILabel!
    @IBOutlet weak var totalSpentLabel: UILabel!
    @IBOutlet weak var budgetUsageLabel: UILabel!
    
    @IBOutlet weak var spentVsRemainingChartView: PieChartView!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("scrollView: \(String(describing: scrollView))")
            print("spentVsRemainingChartView: \(String(describing: spentVsRemainingChartView))")
            print("totalBudgetLabel: \(String(describing: totalBudgetLabel))")
            print("remainingLabel: \(String(describing: remainingLabel))")
            print("totalSpentLabel: \(String(describing: totalSpentLabel))")
        
        setUpUI()
        setupCardTap()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showBudget() // ✅ Refreshes every time you come back to dashboard
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
                PieChartDataEntry(value: spent,     label: "Spent"),
                PieChartDataEntry(value: remaining, label: "Remaining")
            ]
            
            // ✅ Dataset
            let dataSet = PieChartDataSet(entries: entries, label: "")
            dataSet.colors               = [UIColor.systemRed, UIColor.systemGreen]
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
            let centerString = "Budget"
            let attributed = NSMutableAttributedString(string: centerString)
            attributed.addAttributes([
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 14, weight: .bold)
            ], range: NSRange(location: 0, length: centerString.count))
            
            // ✅ Chart config
            spentVsRemainingChartView.data                           = data
            spentVsRemainingChartView.holeRadiusPercent              = 0.5
            spentVsRemainingChartView.holeColor                      = .systemBackground
            spentVsRemainingChartView.transparentCircleRadiusPercent = 0.52
            spentVsRemainingChartView.transparentCircleColor         = .systemBackground.withAlphaComponent(0.3)
            spentVsRemainingChartView.centerAttributedText           = attributed
            spentVsRemainingChartView.drawEntryLabelsEnabled         = false
            spentVsRemainingChartView.usePercentValuesEnabled        = false
            spentVsRemainingChartView.rotationEnabled                = false
            spentVsRemainingChartView.highlightPerTapEnabled         = true
            
            // ✅ Legend
            spentVsRemainingChartView.legend.enabled             = true
            spentVsRemainingChartView.legend.horizontalAlignment = .center
            spentVsRemainingChartView.legend.verticalAlignment   = .bottom
            spentVsRemainingChartView.legend.orientation         = .horizontal
            spentVsRemainingChartView.legend.font                = .systemFont(ofSize: 12)
            spentVsRemainingChartView.legend.textColor           = .label
            spentVsRemainingChartView.legend.formSize            = 12
            spentVsRemainingChartView.legend.formToTextSpace     = 5
            spentVsRemainingChartView.legend.xEntrySpace         = 15
            
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
        addbutton.backgroundColor = .blue
        addbutton.setImage(UIImage(systemName: "plus"), for: .normal)
        addbutton.tintColor = .systemBlue
       }
    
    
    
    @IBAction func addTapped(_ sender: UIButton) {
        
        let vc = AddExpenseViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    @IBAction func viewAllTapped(_ sender: Any) {
        let VC = ExpenseListViewController()
        VC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(VC, animated: true)
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
