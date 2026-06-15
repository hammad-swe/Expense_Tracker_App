//
//  ExpenseListViewController.swift
//  Expensive_Tracker
//
//  Created by Hammad Ali on 03/06/2026.
//

import UIKit

class ExpenseListViewController: UIViewController {

 
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var monthCollectionView: UICollectionView!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var addButton: UIButton!
    
    
    // MARK: - Properties
        var allExpenses: [Expense]         = []
        var filteredExpenses: [Expense]    = []
        var groupedExpenses: [(String, [Expense])] = []

        let months     = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                          "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        let categories = ["All", "Food", "Transport", "Shopping",
                          "Health", "Entertainment", "Education", "Rent", "Utilities"]

        // ✅ Default to current month
        var selectedMonth: String    = {
            let formatter        = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: Date()).uppercased()
        }()
        var selectedCategory: String = "All"
        var searchText: String       = ""

        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            setupTableView()
            setupCollectionViews()
            setupSearchBar()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            // ✅ Correct place for corner radius
            styleButton()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            loadExpenses()
        }

        // MARK: - Setup
        func setupUI() {
            title = "Transactions"
            navigationController?.navigationBar.prefersLargeTitles = false
        }

        private func styleButton() {
            addButton.layer.cornerRadius  = addButton.frame.height / 2
            addButton.layer.masksToBounds = true
            addButton.backgroundColor     = .systemBlue
            addButton.setImage(UIImage(systemName: "plus"), for: .normal)
            addButton.tintColor           = .white
        }

        func setupTableView() {
            let nib = UINib(nibName: "ExpenseCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "ExpenseCell")
            tableView.delegate        = self
            tableView.dataSource      = self
            tableView.separatorStyle  = .none
            tableView.backgroundColor = .white
        }

        func setupCollectionViews() {
            // Month filter
            let monthLayout                          = UICollectionViewFlowLayout()
            monthLayout.scrollDirection              = .horizontal
            monthLayout.minimumInteritemSpacing      = 8
            monthLayout.estimatedItemSize            = UICollectionViewFlowLayout.automaticSize
            monthCollectionView.collectionViewLayout = monthLayout
            monthCollectionView.showsHorizontalScrollIndicator = false
            monthCollectionView.register(FilterCell.self, forCellWithReuseIdentifier: "FilterCell")
            monthCollectionView.delegate             = self
            monthCollectionView.dataSource           = self
            monthCollectionView.tag                  = 1

            // Category filter
            let catLayout                                = UICollectionViewFlowLayout()
            catLayout.scrollDirection                    = .horizontal
            catLayout.minimumInteritemSpacing            = 8
            catLayout.estimatedItemSize                  = UICollectionViewFlowLayout.automaticSize
            categoryCollectionView.collectionViewLayout  = catLayout
            categoryCollectionView.showsHorizontalScrollIndicator = false
            categoryCollectionView.register(FilterCell.self, forCellWithReuseIdentifier: "FilterCell")
            categoryCollectionView.delegate              = self
            categoryCollectionView.dataSource            = self
            categoryCollectionView.tag                   = 2
        }

        func setupSearchBar() {
            searchBar.delegate        = self
            searchBar.placeholder     = "Search transactions..."
            searchBar.backgroundImage = UIImage()
        }

        // MARK: - Load & Filter
        func loadExpenses() {
            allExpenses = CoreDataManager.shared.fetchExpenses()
            applyFilters()
        }

        func applyFilters() {
            var result = allExpenses

            // ✅ Month filter — uppercase match
            let monthMap = ["JAN": 1, "FEB": 2, "MAR": 3, "APR": 4,
                            "MAY": 5, "JUN": 6, "JUL": 7, "AUG": 8,
                            "SEP": 9, "OCT": 10, "NOV": 11, "DEC": 12]

            if let monthNum = monthMap[selectedMonth] {
                result = result.filter {
                    guard let date = $0.date else { return false }
                    return Calendar.current.component(.month, from: date) == monthNum
                }
            }

            // Category filter
            if selectedCategory != "All" {
                result = result.filter {
                    ($0.category ?? "").contains(selectedCategory)
                }
            }

            // Search filter
            if !searchText.isEmpty {
                result = result.filter {
                    ($0.title ?? "").lowercased().contains(searchText.lowercased()) ||
                    ($0.category ?? "").lowercased().contains(searchText.lowercased())
                }
            }

            filteredExpenses = result
            groupExpenses()
        }

        func groupExpenses() {
            let calendar  = Calendar.current
            let today     = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

            var todayExpenses:     [Expense] = []
            var yesterdayExpenses: [Expense] = []
            var earlierExpenses:   [Expense] = []

            for expense in filteredExpenses {
                guard let date = expense.date else { continue }
                let day = calendar.startOfDay(for: date)
                if day == today {
                    todayExpenses.append(expense)
                } else if day == yesterday {
                    yesterdayExpenses.append(expense)
                } else {
                    earlierExpenses.append(expense)
                }
            }

            groupedExpenses = []
            if !todayExpenses.isEmpty     { groupedExpenses.append(("TODAY", todayExpenses)) }
            if !yesterdayExpenses.isEmpty { groupedExpenses.append(("YESTERDAY", yesterdayExpenses)) }
            if !earlierExpenses.isEmpty   { groupedExpenses.append(("EARLIER THIS MONTH", earlierExpenses)) }

            tableView.reloadData()
            showEmptyStateIfNeeded() // ✅
        }

        // MARK: - ✅ Empty State
        func showEmptyStateIfNeeded() {
            if groupedExpenses.isEmpty {
                let emptyView              = UIView(frame: tableView.bounds)

                let imageView              = UIImageView()
                imageView.image            = UIImage(systemName: "tray")
                imageView.tintColor        = .systemGray3
                imageView.contentMode      = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false

                let label                  = UILabel()
                label.text                 = "No expenses found"
                label.textColor            = .secondaryLabel
                label.font                 = .systemFont(ofSize: 16, weight: .medium)
                label.textAlignment        = .center
                label.translatesAutoresizingMaskIntoConstraints = false

                let subLabel               = UILabel()
                subLabel.text              = "Try a different month or category"
                subLabel.textColor         = .tertiaryLabel
                subLabel.font              = .systemFont(ofSize: 13)
                subLabel.textAlignment     = .center
                subLabel.translatesAutoresizingMaskIntoConstraints = false

                emptyView.addSubview(imageView)
                emptyView.addSubview(label)
                emptyView.addSubview(subLabel)

                NSLayoutConstraint.activate([
                    imageView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -40),
                    imageView.widthAnchor.constraint(equalToConstant: 60),
                    imageView.heightAnchor.constraint(equalToConstant: 60),

                    label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
                    label.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),

                    subLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
                    subLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor)
                ])

                tableView.backgroundView = emptyView
            } else {
                tableView.backgroundView = nil
            }
        }

        // MARK: - Actions
        @IBAction func addTapped(_ sender: Any) {
            let vc = AddExpenseViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - TableView
    extension ExpenseListViewController: UITableViewDataSource, UITableViewDelegate {

        func numberOfSections(in tableView: UITableView) -> Int {
            return groupedExpenses.count
        }

        func tableView(_ tableView: UITableView,
                       numberOfRowsInSection section: Int) -> Int {
            return groupedExpenses[section].1.count
        }

        func tableView(_ tableView: UITableView,
                       titleForHeaderInSection section: Int) -> String? {
            return groupedExpenses[section].0
        }

        func tableView(_ tableView: UITableView,
                       willDisplayHeaderView view: UIView, forSection section: Int) {
            guard let header = view as? UITableViewHeaderFooterView else { return }
            header.textLabel?.font      = .systemFont(ofSize: 13, weight: .bold)
            header.textLabel?.textColor = .secondaryLabel
        }

        func tableView(_ tableView: UITableView,
                       cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell    = tableView.dequeueReusableCell(
                            withIdentifier: "ExpenseCell", for: indexPath) as! ExpenseCell
            let expense = groupedExpenses[indexPath.section].1[indexPath.row]
            cell.configure(with: expense)
            return cell
        }

        func tableView(_ tableView: UITableView,
                       heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80
        }

        func tableView(_ tableView: UITableView,
                       commit editingStyle: UITableViewCell.EditingStyle,
                       forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let expense = groupedExpenses[indexPath.section].1[indexPath.row]
                CoreDataManager.shared.deleteExpense(expense)
                loadExpenses()
            }
        }
        
        func tableView(_ tableView: UITableView,
                       didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let expense    = groupedExpenses[indexPath.section].1[indexPath.row]

            // ✅ Reuse AddExpenseViewController in edit mode
            let vc         = AddExpenseViewController(nibName: "AddExpenseViewController", bundle: nil)
            vc.expenseToEdit = expense  // ✅ Pass expense to edit
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
        
        // ✅ Swipe left → Delete
           func tableView(_ tableView: UITableView,
                          trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
                          -> UISwipeActionsConfiguration? {

               let deleteAction = UIContextualAction(
                   style: .destructive, title: nil) { _, _, completion in

                   let expense = self.groupedExpenses[indexPath.section].1[indexPath.row]

                   let alert = UIAlertController(
                       title: "Delete Expense",
                       message: "Are you sure you want to delete \"\(expense.title ?? "this expense")\"?",
                       preferredStyle: .alert)
                   alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                       completion(false)
                   })
                   alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                       CoreDataManager.shared.deleteExpense(expense)
                       self.loadExpenses()
                       completion(true)
                   })
                   self.present(alert, animated: true)
               }

               deleteAction.image           = UIImage(systemName: "trash")
               deleteAction.backgroundColor = .systemRed

               return UISwipeActionsConfiguration(actions: [deleteAction])
           }
    }

    // MARK: - CollectionView
    extension ExpenseListViewController: UICollectionViewDataSource, UICollectionViewDelegate {

        func collectionView(_ collectionView: UICollectionView,
                            numberOfItemsInSection section: Int) -> Int {
            return collectionView.tag == 1 ? months.count : categories.count
        }

        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell

            if collectionView.tag == 1 {
                let month      = months[indexPath.item]
                let isSelected = month == selectedMonth
                cell.configure(title: month, isSelected: isSelected)
            } else {
                let category   = categories[indexPath.item]
                let isSelected = category == selectedCategory
                cell.configure(title: category, isSelected: isSelected)
            }
            return cell
        }

        func collectionView(_ collectionView: UICollectionView,
                            didSelectItemAt indexPath: IndexPath) {
            if collectionView.tag == 1 {
                selectedMonth = months[indexPath.item]        // ✅ updates month
                monthCollectionView.reloadData()
            } else {
                selectedCategory = categories[indexPath.item] // ✅ updates category
                categoryCollectionView.reloadData()
            }
            applyFilters() // ✅ always refresh table
        }
    }

    // MARK: - SearchBar
    extension ExpenseListViewController: UISearchBarDelegate {
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            self.searchText = searchText
            applyFilters()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

    
    }
