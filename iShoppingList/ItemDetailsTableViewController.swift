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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var repeatSwitch: UISwitch!
    @IBOutlet weak var repetitionIntervalPicker: UIPickerView!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!

    var item: GroceryItems!
    
    var managedObjectContext: NSManagedObjectContext!
    var coreDataObjectID: NSManagedObjectID!
    
    let rangeForRepeatInterval = Array(1...26).map { String($0) }
    let repeatIntervalUnits = ["Day","Week","Month"]

    var repeatInterval = "2"
    var repeatIntervalUnit = "Week"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveItemDetailsAndPopulate()
        
        repetitionIntervalPicker.dataSource = self
        repetitionIntervalPicker.delegate = self
        repetitionIntervalPicker.selectRow(1, inComponent: 0, animated: true)
        repetitionIntervalPicker.selectRow(1, inComponent: 1, animated: true)
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        case 2:
            return 2
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
    }
}

extension ItemDetailsTableViewController {
    
    fileprivate func retrieveItemDetailsAndPopulate() {
        let currentItemFetch: NSFetchRequest<GroceryItems> = GroceryItems.fetchRequest()
        currentItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItems.objectID), coreDataObjectID)
        
        do {
            let results = try managedObjectContext.fetch(currentItemFetch)
            if let item = results.first {
                populateItemDetails(item)
            }
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
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