//
//  CoreDataManager.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 02/06/2026.
//

import Foundation
internal import CoreData

class CoreDataManager{
    static let shared = CoreDataManager()
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
           let container = NSPersistentContainer(name: "ExpenseTracker")
           container.loadPersistentStores { _, error in
               if let error = error {
                   fatalError("Core Data failed: \(error.localizedDescription)")
               }
           }
           return container
       }()
    var context: NSManagedObjectContext {
            return persistentContainer.viewContext
        }
        
        func saveContext() {
            if context.hasChanges {
                do {
                    try context.save()
                    print("Save Succesfully")
                } catch {
                    print("Save error: \(error)")
                }
            }
        }
    
    // MARK: - Current Month/Year Helper
        var currentMonth: Int { Calendar.current.component(.month, from: Date()) }
        var currentYear: Int  { Calendar.current.component(.year,  from: Date()) }
    
    
    // Fetch current month budget only
        func fetchCurrentBudget() -> Budget? {
            let request: NSFetchRequest<Budget> = Budget.fetchRequest()
            request.predicate = NSPredicate(
                format: "month == %d AND year == %d",
                currentMonth, currentYear
            )
            request.fetchLimit = 1
            do {
                return try context.fetch(request).first
            } catch {
                print("Budget fetch error: \(error)")
                return nil
            }
        }
    
    // Save or Edit budget for current month
        func saveOrUpdateBudget(amount: Double) {
            if let existing = fetchCurrentBudget() {
                // ✅ Edit existing budget
                existing.totalAmount = amount
            } else {
                // ✅ New month — create fresh budget
                let budget = Budget(context: context)
                budget.totalAmount = amount
                budget.month       = Int32(currentMonth)
                budget.year        = Int32(currentYear)
                budget.createAt   = Date()
            }
            saveContext()
        }
    
    func checkAndResetIfNewMonth() {
            let request: NSFetchRequest<Budget> = Budget.fetchRequest()
            // Fetch budgets NOT from current month
            request.predicate = NSPredicate(
                format: "NOT (month == %d AND year == %d)",
                currentMonth, currentYear
            )
            do {
                let oldBudgets = try context.fetch(request)
                if !oldBudgets.isEmpty {
                    // Delete all old expenses
                  //  deleteAllExpenses()
                    // Delete old budgets
                    oldBudgets.forEach { context.delete($0) }
                    saveContext()
                    print("✅ New month detected — reset complete")
                }
            } catch {
                print("Reset check error: \(error)")
            }
        }
    
    func updateCurrency(_ currencyCode: String) {
        guard let budget = fetchCurrentBudget() else { return }
        budget.currency = currencyCode
        saveContext()
    }
    
    // MARK: - ✅ EXPENSE
        
        func createExpense(title: String, amount: Double, category: String, note: String, date: Date) {
            let expense      = Expense(context: context)
            expense.title    = title
            expense.amount   = amount
            expense.category = category
            expense.note     = note
            expense.date     = date
            saveContext()
        }
        
        func fetchExpenses() -> [Expense] {
            let request: NSFetchRequest<Expense> = Expense.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            do {
                return try context.fetch(request)
            } catch {
                print("Fetch error: \(error)")
                return []
            }
        }
        
        func updateExpense(_ expense: Expense, title: String, amount: Double, category: String, note: String) {
            expense.title    = title
            expense.amount   = amount
            expense.category = category
            expense.note     = note
            saveContext()
        }
        
        func deleteExpense(_ expense: Expense) {
            context.delete(expense)
            saveContext()
        }
        
        func deleteAllExpenses() {
            fetchExpenses().forEach { context.delete($0) }
            saveContext()
        }
        
        // MARK: - ✅ CALCULATIONS
        
        func totalSpent() -> Double {
            return fetchExpenses().reduce(0) { $0 + $1.amount }
        }
        
        func remainingBalance() -> Double {
            let budget = fetchCurrentBudget()?.totalAmount ?? 0
            return budget - totalSpent()
        }
        
        func isOverBudget() -> Bool {
            return remainingBalance() < 0
        }
        
        func spentPercentage() -> Float {
            let budget = fetchCurrentBudget()?.totalAmount ?? 0
            guard budget > 0 else { return 0 }
            return Float(totalSpent() / budget)
        }
    
    func fetchTodayExpenses() -> [Expense] {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch today's expenses: \(error)")
            return []
        }
    }
}
