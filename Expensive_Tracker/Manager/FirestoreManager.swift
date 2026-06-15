//
//  FirestoreManager.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 15/06/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
internal import CoreData

class FirestoreManager {

    static let shared = FirestoreManager()
    private init() {}

    private let db = Firestore.firestore()

    // ✅ User document reference
    private var userRef: DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid)
    }

    // MARK: - Save Profile
    func saveProfile(name: String, email: String,
                     completion: ((Error?) -> Void)? = nil) {
        guard let ref = userRef else { return }

        let data: [String: Any] = [
            "name":      name,
            "email":     email,
            "updatedAt": Timestamp()
        ]
        ref.setData(data, merge: true) { error in
            completion?(error)
        }
    }

    // MARK: - Sync Budget
    func syncBudget(_ budget: Budget,
                    completion: ((Error?) -> Void)? = nil) {
        guard let ref = userRef else { return }

        let data: [String: Any] = [
            "totalAmount": budget.totalAmount,
            "month":       budget.month,
            "year":        budget.year,
            "updatedAt":   Timestamp()
        ]

        ref.collection("budgets")
           .document("\(budget.year)-\(budget.month)")
           .setData(data) { error in
               completion?(error)
           }
    }

    // MARK: - Sync All Expenses
    func syncAllExpenses(completion: ((Error?) -> Void)? = nil) {
        guard let ref = userRef else {
            completion?(nil)
            return
        }

        let expenses = CoreDataManager.shared.fetchExpenses()

        guard !expenses.isEmpty else {
            completion?(nil)
            return
        }

        let batch = db.batch()

        for expense in expenses {
            // ✅ Use CoreData objectID as document ID
            let id     = expense.objectID.uriRepresentation()
                           .absoluteString
                           .replacingOccurrences(of: "/", with: "_")
                           .replacingOccurrences(of: ":", with: "_")

            let docRef = ref.collection("expenses").document(id)

            let data: [String: Any] = [
                "title":     expense.title    ?? "",
                "amount":    expense.amount,
                "category":  expense.category ?? "",
                "note":      expense.note     ?? "",
                "date":      expense.date.map { Timestamp(date: $0) } ?? Timestamp(),
                "updatedAt": Timestamp()
            ]

            batch.setData(data, forDocument: docRef)
        }

        batch.commit { error in
            completion?(error)
        }
    }

    // MARK: - Sync Single Expense
    func syncExpense(_ expense: Expense,
                     completion: ((Error?) -> Void)? = nil) {
        guard let ref = userRef else { return }

        let id = expense.objectID.uriRepresentation()
                   .absoluteString
                   .replacingOccurrences(of: "/", with: "_")
                   .replacingOccurrences(of: ":", with: "_")

        let data: [String: Any] = [
            "title":     expense.title    ?? "",
            "amount":    expense.amount,
            "category":  expense.category ?? "",
            "note":      expense.note     ?? "",
            "date":      expense.date.map { Timestamp(date: $0) } ?? Timestamp(),
            "updatedAt": Timestamp()
        ]

        ref.collection("expenses").document(id).setData(data) { error in
            completion?(error)
        }
    }

    // MARK: - Delete Expense from Firestore
    func deleteExpense(_ expense: Expense,
                       completion: ((Error?) -> Void)? = nil) {
        guard let ref = userRef else { return }

        let id = expense.objectID.uriRepresentation()
                   .absoluteString
                   .replacingOccurrences(of: "/", with: "_")
                   .replacingOccurrences(of: ":", with: "_")

        ref.collection("expenses").document(id).delete { error in
            completion?(error)
        }
    }

    // MARK: - Fetch Profile
    func fetchProfile(completion: @escaping ([String: Any]?) -> Void) {
        guard let ref = userRef else {
            completion(nil)
            return
        }
        ref.getDocument { snapshot, _ in
            completion(snapshot?.data())
        }
    }
}
