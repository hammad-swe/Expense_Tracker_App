//
//  PDFExportManager.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 18/06/2026.
//

import UIKit
import PDFKit

class PDFExportManager {

    static let shared = PDFExportManager()
    private init() {}

    func exportExpensesToPDF() -> URL? {
        let expenses = CoreDataManager.shared.fetchExpenses()
        let budget   = CoreDataManager.shared.fetchCurrentBudget()

        let pdfMetaData = [
            kCGPDFContextCreator: "Expensive Tracker",
            kCGPDFContextTitle: "Expense Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat  = 612
        let pageHeight: CGFloat = 792
        let pageRect             = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 40
            let leftMargin: CGFloat = 40

            // ✅ Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            "Expense Report".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttrs)
            yPosition += 36

            // ✅ Date
            let dateFormatter        = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy"
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            "Generated on \(dateFormatter.string(from: Date()))"
                .draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: dateAttrs)
            yPosition += 30

            // ✅ Budget Summary Box
            if let budget = budget {
                let spent     = CoreDataManager.shared.totalSpent()
                let remaining = budget.totalAmount - spent

                let summaryRect = CGRect(x: leftMargin, y: yPosition, width: pageWidth - 80, height: 70)
                let path        = UIBezierPath(roundedRect: summaryRect, cornerRadius: 8)
                UIColor(white: 0.95, alpha: 1).setFill()
                path.fill()

                let summaryAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]

                "Total Budget: Rs \(formatAmount(budget.totalAmount))"
                    .draw(at: CGPoint(x: leftMargin + 16, y: yPosition + 12), withAttributes: summaryAttrs)
                "Total Spent: Rs \(formatAmount(spent))"
                    .draw(at: CGPoint(x: leftMargin + 16, y: yPosition + 32), withAttributes: summaryAttrs)
                "Remaining: Rs \(formatAmount(remaining))"
                    .draw(at: CGPoint(x: leftMargin + 16, y: yPosition + 52), withAttributes: summaryAttrs)

                yPosition += 90
            }

            // ✅ Table Header
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            let col1: CGFloat = leftMargin
            let col2: CGFloat = leftMargin + 140
            let col3: CGFloat = leftMargin + 280
            let col4: CGFloat = leftMargin + 380
            let col5: CGFloat = leftMargin + 460

            "Date".draw(at: CGPoint(x: col1, y: yPosition), withAttributes: headerAttrs)
            "Title".draw(at: CGPoint(x: col2, y: yPosition), withAttributes: headerAttrs)
            "Category".draw(at: CGPoint(x: col3, y: yPosition), withAttributes: headerAttrs)
            "Amount".draw(at: CGPoint(x: col4, y: yPosition), withAttributes: headerAttrs)
            yPosition += 20

            // Divider line
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: leftMargin, y: yPosition))
            linePath.addLine(to: CGPoint(x: pageWidth - leftMargin, y: yPosition))
            UIColor.gray.setStroke()
            linePath.lineWidth = 0.5
            linePath.stroke()
            yPosition += 12

            // ✅ Table Rows
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black
            ]

            let dateRowFormatter        = DateFormatter()
            dateRowFormatter.dateFormat = "MMM d, yyyy"

            for expense in expenses {
                // ✅ New page if needed
                if yPosition > pageHeight - 60 {
                    context.beginPage()
                    yPosition = 40
                }

                let dateStr = expense.date.map { dateRowFormatter.string(from: $0) } ?? ""
                dateStr.draw(at: CGPoint(x: col1, y: yPosition), withAttributes: rowAttrs)

                (expense.title ?? "").draw(at: CGPoint(x: col2, y: yPosition), withAttributes: rowAttrs)
                (expense.category ?? "").draw(at: CGPoint(x: col3, y: yPosition), withAttributes: rowAttrs)
                "Rs \(formatAmount(expense.amount))".draw(at: CGPoint(x: col4, y: yPosition), withAttributes: rowAttrs)

                yPosition += 22
            }
        }

        // ✅ Save to file
        let fileName = "ExpenseReport_\(Int(Date().timeIntervalSince1970)).pdf"
        let url      = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url)
            return url
        } catch {
            print("PDF save error: \(error)")
            return nil
        }
    }

    func formatAmount(_ amount: Double) -> String {
        let formatter                   = NumberFormatter()
        formatter.numberStyle           = .decimal
        formatter.groupingSeparator     = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}
