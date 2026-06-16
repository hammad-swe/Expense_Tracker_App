//
//  statsViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 03/06/2026.
//

import UIKit
import DGCharts

class statsViewController: UIViewController {

    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var spentChart: PieChartView!
    @IBOutlet weak var budgetPercentageCard: UIStackView!
    @IBOutlet weak var catagoryChart: PieChartView!
    @IBOutlet weak var catagoryPercentageCard: UIStackView!
    @IBOutlet weak var monthlyTrendCard: UIStackView!
        
    @IBOutlet weak var monthlyTrendChart: LineChartView!
    override func viewDidLoad() {
        super.viewDidLoad()
     
        setupUi()
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            loadChartData() // ✅ Refresh every time screen appears
        }
    
    private func setupUi(){
        title = "Statistics"
                budgetPercentageCard.backgroundColor    = .white
                budgetPercentageCard.layer.cornerRadius = 10
                budgetPercentageCard.layer.shadowColor  = UIColor.black.cgColor
                budgetPercentageCard.layer.shadowOpacity = 0.1
                budgetPercentageCard.layer.shadowOffset  = CGSize(width: 0, height: 2)
                budgetPercentageCard.layer.shadowRadius  = 4
        
        catagoryPercentageCard.backgroundColor    = .white
        catagoryPercentageCard.layer.cornerRadius = 10
        catagoryPercentageCard.layer.shadowColor  = UIColor.black.cgColor
        catagoryPercentageCard.layer.shadowOpacity = 0.1
        catagoryPercentageCard.layer.shadowOffset  = CGSize(width: 0, height: 2)
        catagoryPercentageCard.layer.shadowRadius  = 4
    }
    
    // MARK: - Load Data
        private func loadChartData() {
            let manager = CoreDataManager.shared
            
            guard let budget = manager.fetchCurrentBudget() else {
                percentageLabel.text = "No Budget Set"
                spentChart.data      = nil
                spentChart.notifyDataSetChanged()
                return
            }
            
            let spent      = manager.totalSpent()
            let remaining  = max(manager.remainingBalance(), 0)
            let percentage = Int(manager.spentPercentage() * 100)
            
            // ✅ Update percentage label
            percentageLabel.text = "\(percentage)%"
            percentageLabel.textColor = manager.isOverBudget() ? .systemBlue : .black
            
            // ✅ Setup chart
            setupPieChart(spent: spent, remaining: remaining)
            setupCategoryChart() // ✅ Category breakdown
            setupMonthlyTrendChart() // monthly

        }
        
        // MARK: - Pie Chart
    private func setupPieChart(spent: Double, remaining: Double) {
        
        guard spent > 0 || remaining > 0 else {
            spentChart.data = nil
            let     noData = NSAttributedString(
                string: "No Expenses",
                attributes: [
                    .foregroundColor: UIColor.label,
                    .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
                ]
            )
            spentChart.centerAttributedText = nil
            spentChart.notifyDataSetChanged()
            return
        }
        
        // ✅ Entries
        let entries = [
            PieChartDataEntry(value: spent),
            PieChartDataEntry(value: remaining)
        ]
        
        // ✅ Dataset
        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors             = [UIColor.systemBlue, UIColor.systemGray]
        dataSet.sliceSpace         = 3
        dataSet.drawValuesEnabled  = false  // ✅ No values on slices
        
        // ✅ Data
        let data = PieChartData(dataSet: dataSet)
        
        // ✅ Center text
        let percentage   = Int(CoreDataManager.shared.spentPercentage() * 100)
        let centerString = "\(percentage)%\nSpent"
        let attributed   = NSMutableAttributedString(string: centerString)
        attributed.addAttributes([
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 16, weight: .bold)
        ], range: NSRange(location: 0, length: centerString.count))
        
        // ✅ Chart config
        spentChart.data                           = data
        spentChart.holeRadiusPercent              = 0.8
        spentChart.holeColor                      = .systemBackground
        spentChart.transparentCircleRadiusPercent = 0.10
        spentChart.centerAttributedText           = nil
        spentChart.drawEntryLabelsEnabled         = false  // ✅ No labels on slices
        spentChart.legend.enabled                 = false  // ✅ No legend below
        spentChart.rotationEnabled                = false
        spentChart.highlightPerTapEnabled         = false
        
        // ✅ Animation
        spentChart.animate(xAxisDuration: 0.8, easingOption: .easeInOutQuart)
        spentChart.notifyDataSetChanged()
    }
    
    
    // MARK: - Category Breakdown Chart
    private func setupCategoryChart() {
        let expenses = CoreDataManager.shared.fetchExpenses()
        let total    = expenses.reduce(0) { $0 + $1.amount }

        // Group by category
        var categoryTotals: [String: Double] = [:]
        for expense in expenses {
            let cat = expense.category ?? "Other"
            categoryTotals[cat, default: 0] += expense.amount
        }

        guard !categoryTotals.isEmpty else {
            catagoryChart.data = nil
            let noData = NSAttributedString(
                string: "No Expenses",
                attributes: [
                    .foregroundColor: UIColor.secondaryLabel,
                    .font: UIFont.systemFont(ofSize: 13, weight: .medium)
                ]
            )
            catagoryChart.centerAttributedText = noData
            catagoryChart.notifyDataSetChanged()
            return
        }

        // ✅ Sort by value descending
        let sorted  = categoryTotals.sorted { $0.value > $1.value }

        // ✅ Entries with percentage in label
        let entries = sorted.map { item -> PieChartDataEntry in
            let percentage = total > 0 ? (item.value / total) * 100 : 0
            return PieChartDataEntry(
                value: item.value,
                label: "\(item.key)\n\(String(format: "%.0f", percentage))%"
            )
        }

        // ✅ Colors
        let colors: [UIColor] = [
            UIColor(red: 0.91, green: 0.39, blue: 0.31, alpha: 1),
            UIColor(red: 0.85, green: 0.75, blue: 0.35, alpha: 1),
            UIColor(red: 0.18, green: 0.27, blue: 0.33, alpha: 1),
            UIColor(red: 0.18, green: 0.55, blue: 0.53, alpha: 1),
            UIColor(red: 0.45, green: 0.60, blue: 0.75, alpha: 1),
            UIColor(red: 0.75, green: 0.45, blue: 0.70, alpha: 1),
            UIColor(red: 0.95, green: 0.60, blue: 0.30, alpha: 1),
            UIColor(red: 0.40, green: 0.75, blue: 0.50, alpha: 1),
            UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1),
        ]

        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors            = colors
        dataSet.sliceSpace        = 3
        dataSet.selectionShift    = 6
        dataSet.drawValuesEnabled = false

        // ✅ Chart config
        catagoryChart.data                           = PieChartData(dataSet: dataSet)
        catagoryChart.holeRadiusPercent              = 0.7
        catagoryChart.holeColor                      = .systemBackground
        catagoryChart.transparentCircleRadiusPercent = 0.20
        catagoryChart.centerAttributedText           = nil
        catagoryChart.drawEntryLabelsEnabled         = false
        catagoryChart.rotationEnabled                = false
        catagoryChart.highlightPerTapEnabled         = true

        // ✅ Custom legend — "● Food     39%"
                let legendEntries: [LegendEntry] = sorted.enumerated().map { index, item in
                    let percentage  = total > 0 ? (item.value / total) * 100 : 0
                    let entry       = LegendEntry()
                    entry.label     = "\(item.key)     \(String(format: "%.0f", percentage))%"
                    entry.form      = .circle
                    entry.formSize  = 10
                    entry.formColor = colors[index % colors.count]
                    return entry
                }

                catagoryChart.legend.setCustom(entries: legendEntries)
                catagoryChart.legend.enabled             = true
                catagoryChart.legend.horizontalAlignment = .center
                catagoryChart.legend.verticalAlignment   = .bottom
                catagoryChart.legend.orientation         = .horizontal
                catagoryChart.legend.font                = .systemFont(ofSize: 12, weight: .medium)
                catagoryChart.legend.textColor           = .label
                catagoryChart.legend.formSize            = 10
                catagoryChart.legend.formToTextSpace     = 6
                catagoryChart.legend.xEntrySpace         = 20
                catagoryChart.legend.yEntrySpace         = 8
                catagoryChart.legend.wordWrapEnabled     = true
            

        catagoryChart.animate(xAxisDuration: 0.8, easingOption: .easeInOutQuart)
        catagoryChart.notifyDataSetChanged()
    }
    
    
    // MARK: - Monthly Trend Chart
    private func setupMonthlyTrendChart() {
        let expenses = CoreDataManager.shared.fetchExpenses()

        // Group expenses by month
        var monthlyTotals: [Int: Double] = [:]
        let calendar = Calendar.current

        for expense in expenses {
            guard let date = expense.date else { continue }
            let month = calendar.component(.month, from: date)
            monthlyTotals[month, default: 0] += expense.amount
        }

        guard !monthlyTotals.isEmpty else {
            monthlyTrendChart.data = nil
            monthlyTrendChart.notifyDataSetChanged()
            return
        }

        // ✅ Sort by month
        let sorted  = monthlyTotals.sorted { $0.key < $1.key }
        let entries = sorted.enumerated().map { index, item in
            ChartDataEntry(x: Double(index), y: item.value)
        }

        // ✅ Month labels
        let monthNames = ["Jan","Feb","Mar","Apr","May","Jun",
                          "Jul","Aug","Sep","Oct","Nov","Dec"]
        let xLabels = sorted.map { monthNames[$0.key - 1] }

        // ✅ Dataset
        let dataSet = LineChartDataSet(entries: entries, label: "")
        dataSet.colors                  = [UIColor.systemBlue]
        dataSet.circleColors            = [UIColor.systemBlue]
        dataSet.circleRadius            = 4
        dataSet.circleHoleRadius        = 2
        dataSet.circleHoleColor         = .systemBackground
        dataSet.lineWidth               = 2.5
        dataSet.drawValuesEnabled       = false
        dataSet.mode                    = .cubicBezier  // smooth curve
        dataSet.cubicIntensity          = 0.2

        // ✅ Gradient fill under line
        let gradientColors = [UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
                              UIColor.systemBlue.withAlphaComponent(0.0).cgColor]
        let gradient       = CGGradient(colorsSpace: nil,
                                        colors: gradientColors as CFArray,
                                        locations: nil)!
        dataSet.fill                    = LinearGradientFill(gradient: gradient, angle: 90)
        dataSet.drawFilledEnabled       = true

        // ✅ Chart config
        monthlyTrendChart.data          = LineChartData(dataSet: dataSet)
        monthlyTrendChart.rightAxis.enabled        = false
        monthlyTrendChart.legend.enabled           = false
        monthlyTrendChart.doubleTapToZoomEnabled   = false
        monthlyTrendChart.pinchZoomEnabled         = false
        monthlyTrendChart.dragEnabled              = false

        // ✅ X Axis
        monthlyTrendChart.xAxis.valueFormatter     = IndexAxisValueFormatter(values: xLabels)
        monthlyTrendChart.xAxis.labelPosition      = .bottom
        monthlyTrendChart.xAxis.granularity        = 1
        monthlyTrendChart.xAxis.drawGridLinesEnabled = true
        monthlyTrendChart.xAxis.gridColor          = .systemGray5
        monthlyTrendChart.xAxis.gridLineDashLengths = [4, 4]
        monthlyTrendChart.xAxis.labelTextColor     = .secondaryLabel
        monthlyTrendChart.xAxis.axisLineColor      = .clear

        // ✅ Y Axis
        monthlyTrendChart.leftAxis.drawGridLinesEnabled = true
        monthlyTrendChart.leftAxis.gridColor            = .systemGray5
        monthlyTrendChart.leftAxis.gridLineDashLengths  = [4, 4]
        monthlyTrendChart.leftAxis.labelTextColor       = .secondaryLabel
        monthlyTrendChart.leftAxis.axisLineColor        = .clear
        monthlyTrendChart.leftAxis.drawAxisLineEnabled  = false

        monthlyTrendChart.animate(xAxisDuration: 0.8, easingOption: .easeInOutQuart)
        monthlyTrendChart.notifyDataSetChanged()
    }

    
        
        // MARK: - Format Amount
        func formatAmount(_ amount: Double) -> String {
            let formatter                   = NumberFormatter()
            formatter.numberStyle           = .decimal
            formatter.groupingSeparator     = ","
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: amount)) ?? "0"
        }
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

