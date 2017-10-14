//
//  ItemDetailsTableViewController.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class ItemDetailsTableViewController: UITableViewController {
    
    struct IndexPathOfCell {
        static let completionDate           = IndexPath.init(row: 2, section: 0)
        static let repetitionIntervalPicker = IndexPath.init(row: 1, section: 1)
        static let reminderDatePicker       = IndexPath.init(row: 1, section: 2)
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var repeatSwitch: UISwitch!
    @IBOutlet weak var repetitionIntervalPicker: UIPickerView!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var completionDate: UILabel!
    @IBOutlet weak var moveToActive: UIButton!
    
    
    var item: GroceryItem!
    
    var coreDataStack: CoreDataStack!
    var managedObjectContext: NSManagedObjectContext!
    var itemIdentifier: String!
    
    let rangeForRepeatInterval = Array(1...26).map { String($0) }
    let repeatIntervalUnits = ["Day","Week","Month"]

    var repeatInterval = "2"
    var repeatIntervalUnit = "Week"
    
    var reminderDate: Date?
    
    var appDelegate = AppDelegate.getAppDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate.controller = self
        priceTextField.delegate = self
        repetitionIntervalPicker.dataSource = self
        repetitionIntervalPicker.delegate = self
        repetitionIntervalPicker.selectRow(1, inComponent: 0, animated: true)
        repetitionIntervalPicker.selectRow(1, inComponent: 1, animated: true)
        
        populateItemDetails(item)
        
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(ItemDetailsTableViewController.saveButtonTapped))
        navigationItem.rightBarButtonItem = saveButton
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func repeatItemSwitch(_ sender: UISwitch) {
        item.isRepeatedItem = sender.isOn
        insertOrDeleteRow(indexPath: IndexPathOfCell.repetitionIntervalPicker, state: sender.isOn)
    }
    
    @IBAction func reminderSwitch(_ sender: UISwitch) {
        item.hasReminder = sender.isOn
        insertOrDeleteRow(indexPath: IndexPathOfCell.reminderDatePicker, state: sender.isOn)
    }
    
    @IBAction func reminderDatePickerValueChange(_ sender: UIDatePicker) {
        reminderDate = sender.date
    }
    
    @IBAction func moveToActiveTapped(_ sender: UIButton) {
        // move this item to active by setting the completed to false
        item.completed = false
        persistItemDetails()
        
        UIView.animate(withDuration: 0.4, animations: {[weak self] in
            self?.moveToActive.frame.size = CGSize.zero
        }) {[weak self] (completed) in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func insertOrDeleteRow(indexPath: IndexPath, state: Bool) {
        switch state {
        case true:
            tableView.insertRows(at: [indexPath], with: .automatic)
        case false:
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return item.completed ? 4 : 2
        case 1:
            return item.isRepeatedItem ?  2 : 1
         case 2:
            return item.completed ? 0 : (item.hasReminder ? 2 : 1)
        default:
            return 0
        }
    }

}


extension ItemDetailsTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    // data source 
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ?  rangeForRepeatInterval.count : repeatIntervalUnits.count
    }
    
    // delegate 
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return component == 0 ? rangeForRepeatInterval[row] : repeatIntervalUnits[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            repeatInterval = rangeForRepeatInterval[row]
        default:
            repeatIntervalUnit = repeatIntervalUnits[row]
        }
        print("Selected \(repeatInterval) \(repeatIntervalUnit)")
        
        switch (Double(repeatInterval)!, repeatIntervalUnit) {
        case let (n,"Week"):
            item.repetitionInterval = n * TimeIntervalConst.oneWeek
        case let (n, "Day"):
            item.repetitionInterval = n * TimeIntervalConst.oneDay
        case let (n, "Month"):
            item.repetitionInterval = n * TimeIntervalConst.oneMonth
        default: break
        }
    }
}

extension ItemDetailsTableViewController {
    
    fileprivate func retrieveItemDetailsAndPopulate() {
        let currentItemFetch: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        currentItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItem.identifier), itemIdentifier)
        
        do {
            let results = try managedObjectContext.fetch(currentItemFetch)
            if let firstItem = results.first {
                item = firstItem
                populateItemDetails(firstItem)
            }
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }
    
    @objc func saveButtonTapped() {
        persistItemDetails()
        
        // set up reminder if needed
        setupNotificationForReminderIfNeeded()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func persistItemDetails() {
        item.isRepeatedItem = repeatSwitch.isOn
        item.hasReminder = reminderSwitch.isOn
        item.reminderDate = datePicker.date as NSDate
        item.localUpdate = NSDate()
        item.needsUpload = true
        if let priceText = priceTextField.text {
           item.price = Double(priceText) ?? 0.0
        }
        
        // item.repetitionInterval is updated in pickerView delegate
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            fatalError("Failed to save item details \(error.localizedDescription)")
        }
        // need to check if item was completed and we update the repeatSwitch or repetitionInterval
        synchronizeCloneToWarehouseAction()
    }
    
    private func synchronizeCloneToWarehouseAction() {
        let completed = item.completed
        let repeatNewValue = item.isRepeatedItem
        let title = item.title
        let identifier = item.identifier
        
        switch (completed, repeatNewValue) {
        case (false, _): break
        case (true, false):
            let backgroundContext = coreDataStack.newBackgroundContext()
            CoreDataUtil.deleteItemFromWarehouse(title: title, moc: backgroundContext)
            
        case (true, true):
            let backgroundContext = coreDataStack.newBackgroundContext()
            _ = CloneItemToWarehouse(identifier: identifier, moc: backgroundContext, completion: { print("cloning finished")} )
        }
    }
    
    private func setupNotificationForReminderIfNeeded() {
        let identifier = item.identifier
        
        if item.hasReminder {
            let reminderDate = item.reminderDate! as Date
            appDelegate.scheduleNotification(at: reminderDate, identifier: identifier, title: "ShoppingItem Reminder", body: item.title)
        } else {
            // cancel any pending notification by identifier 
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    
    fileprivate func populateItemDetails(_ item: GroceryItem) {
        titleLabel.text = item.title
        repeatSwitch.isOn = item.isRepeatedItem
        reminderSwitch.isOn = item.hasReminder
        priceTextField.text = String(item.price)
        
        datePicker.date = Date()
        if let reminderDate = item.reminderDate {
            datePicker.date = reminderDate as Date
        }
        
        if item.isRepeatedItem {
            setRepetitionIntervalPicker(from: item.repetitionInterval)
        }
        
        if item.completed {
            guard let completionDate = item.completionDate else { return }
            setCompletionDate(completionDate as Date)
        }
    }
    
    private func setCompletionDate(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "en_US")
        
        completionDate.text = dateFormatter.string(from: date)
    }
    
    private func setRepetitionIntervalPicker(from interval: Double) {
        if interval.truncatingRemainder(dividingBy: TimeIntervalConst.oneMonth) == 0.0 {
            let number = Int(interval / TimeIntervalConst.oneMonth)
            setRepetitionIntervalOnPicker(for: number)
            setRepetitionUnitOnPicker(for: "Month")
        } else if interval.truncatingRemainder(dividingBy: TimeIntervalConst.oneWeek) == 0.0 {
            let number = Int(interval / TimeIntervalConst.oneWeek)
            setRepetitionIntervalOnPicker(for: number)
            setRepetitionUnitOnPicker(for: "Week")
        } else {
            let number = Int(interval / TimeIntervalConst.oneDay)
            setRepetitionIntervalOnPicker(for: number)
            setRepetitionUnitOnPicker(for: "Day")
        }
    }
    
    
    private func setRepetitionIntervalOnPicker(for value: Int) {
        guard let index = rangeForRepeatInterval.index(of: String(value)) else { return }
        repetitionIntervalPicker.selectRow(index, inComponent: 0, animated: true)
    }
    
    private func setRepetitionUnitOnPicker(for value: String) {
        guard let index = repeatIntervalUnits.index(of: value) else { return }
        repetitionIntervalPicker.selectRow(index, inComponent: 1, animated: true)
    }
}

// MARK: - Text field delegate

extension ItemDetailsTableViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text ?? "") as NSString
        let newText = text.replacingCharacters(in: range, with: string)
        if let regex = try? NSRegularExpression(pattern: "^[0-9]*((\\.)[0-9]*)?$", options: .caseInsensitive) {
            return regex.numberOfMatches(in: newText, options: .reportProgress, range: NSRange(location: 0, length: (newText as NSString).length)) > 0
        }
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text,
            let price = Float(text) {
            textField.text = String(format: "%.2f", price)
        }
        textField.resignFirstResponder()
        return true
    }
}


// MARK: - Show or hide details option conditionally

extension ItemDetailsTableViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Section 2 is for reminder. Completed items don't need reminder anymore. So hide the section.
        guard  section == 2 else { return 44 }
        
        return item.completed ? 0 : 44
    }
}
