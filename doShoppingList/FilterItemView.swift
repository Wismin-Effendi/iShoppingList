//
//  FilterItemView.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/27/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import UIKit

class FilterItemView: UIView {
    
    var filterItemViewClosure: (ItemCategory) -> ()
    
    init(controller: UIViewController, filterItemViewClosure: @escaping (ItemCategory) -> ()) {
        
        self.filterItemViewClosure = filterItemViewClosure
        
        super.init(frame: controller.view.frame)
        
        setup()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 96))
        footerView.backgroundColor = UIColor.groupTableViewBackground
        
        let mySegmentedControl = UISegmentedControl (items: [ItemCategory.todo.rawValue,
                                                             ItemCategory.completed.rawValue])
        
        let elementWidth:CGFloat = 300
        let elementHeight:CGFloat = 40
        
        mySegmentedControl.frame.size =  CGSize(width: elementWidth, height: elementHeight)
        mySegmentedControl.center = footerView.center
        mySegmentedControl.layer.cornerRadius = 20.0
        mySegmentedControl.layer.borderColor = UIColor.darkGray.cgColor
        mySegmentedControl.layer.borderWidth = 1.0
        mySegmentedControl.layer.masksToBounds = true
        
        mySegmentedControl.isMomentary = false
        
        mySegmentedControl.tintColor = UIColor.green
        mySegmentedControl.backgroundColor = UIColor.darkGray
                
        // Add function to handle Value Changed events
        mySegmentedControl.addTarget(self, action: #selector(FilterItemView.segmentedValueChanged(_:)), for: .valueChanged)
        
        footerView.addSubview(mySegmentedControl)
        
        self.addSubview(footerView)
    }
    
    @objc func segmentedValueChanged(_ sender:UISegmentedControl!)
    {
        let index = sender.selectedSegmentIndex
    
        print("Selected Segment Index is : \(index)")
        
        filterItemViewClosure(ItemCategory.byIndex(index))
    }
}
