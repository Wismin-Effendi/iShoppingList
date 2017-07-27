//
//  ItemDetailsTableViewController.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData

class ItemDetailsTableViewController: UITableViewController {
    
    struct TimeIntervalConst {
        static let oneDay: Float = 3600.0 * 24.0
        static let oneWeek: Float  = 7.0 * oneDay
        static let oneMonth: Float = 30.0 * oneDay
    }
    
    struct IndexPathOfCell {
        static let completionDate           = IndexPath.init(row: 1, section: 0)
        static let repetitionIntervalPicker = IndexPath.init(row: 1, section: 1)
        static let reminderDatePicker       = IndexPath.init(row: 1, section: 2)
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var repeatSwitch: UISwitch!
    @IBOutlet weak var repetitionIntervalPicker: UIPickerView!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!

    @IBOutlet weak var completionDate: UILabel!
    
    var item: GroceryItems!
    
    var managedObjectContext: NSManagedObjectContext!
    var itemIdentifier: String!
    
    let rangeForRepeatInterval = Array(1...26).map { String($0) }
    let repeatIntervalUnits = ["Day","Week","Month"]

    var repeatInterval = "2"
    var repeatIntervalUnit = "Week"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        repetitionIntervalPicker.dataSource = self
        repetitionIntervalPicker.delegate = self
        repetitionIntervalPicker.selectRow(1, inComponent: 0, animated: true)
        repetitionIntervalPicker.selectRow(1, inComponent: 1, animated: true)
        
        retrieveItemDetailsAndPopulate()
        
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(ItemDetailsTableViewController.persistItemDetails))
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
            return item.isCompleted ?  2 : 1
        case 1:
            return item.isRepeatedItem ?  2 : 1
         case 2:
            return item.isCompleted ?  0 : (item.hasReminder ? 2 : 1)
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
        
        switch (repeatInterval, repeatIntervalUnit) {
        case let (n,"Week"):
            item.repetitionInterval = Float(n)! * TimeIntervalConst.oneWeek
        case let (n, "Day"):
            item.repetitionInterval = Float(n)! * TimeIntervalConst.oneDay
        case let (n, "Month"):
            item.repetitionInterval = Float(n)! * TimeIntervalConst.oneMonth
        default: break
        }
    }
}

extension ItemDetailsTableViewController {
    
    fileprivate func retrieveItemDetailsAndPopulate() {
        let currentItemFetch: NSFetchRequest<GroceryItems> = GroceryItems.fetchRequest()
        currentItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItems.identifier), itemIdentifier)
        
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
    
    func persistItemDetails() {
        item.isRepeatedItem = repeatSwitch.isOn
        item.hasReminder = repeatSwitch.isOn
        item.reminderDate = datePicker.date as NSDate
        
        // item.repetitionInterval is updated in pickerView delegate
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            fatalError("Failed to save item details \(error.localizedDescription)")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    private func populateItemDetails(_ item: GroceryItems) {
        titleLabel.text = item.title
        repeatSwitch.isOn = item.isRepeatedItem
        reminderSwitch.isOn = item.hasReminder
        
        if let reminderDate = item.reminderDate {
            datePicker.date = reminderDate as Date
        }
        
        if item.isRepeatedItem {
            setRepetitionIntervalPicker(from: item.repetitionInterval)
        }
        
        if item.isCompleted {
            setCompletionDate(item.completionDate! as Date)
        }
    }
    
    private func setCompletionDate(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "en_US")
        
        completionDate.text = dateFormatter.string(from: date)
    }
    
    private func setRepetitionIntervalPicker(from interval: Float) {
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



// MARK: - Show or hide details option conditionally

extension ItemDetailsTableViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Section 2 is for reminder. Completed items don't need reminder anymore. So hide the section.
        guard  section == 2 else { return 44 }
        
        return item.isCompleted ? 0 : 44
    }
}
