//
//  AddNewItemView.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import UIKit


class AddNewItemView: UIView, UITextFieldDelegate {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var staticCircleView: CircleView!
    @IBOutlet weak var staticText: UITextField!
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var inputTextCircleView: CircleView!
    
    
    var placeHolderText: String!
    var addNewItemViewClosure: (String) -> ()
    
    init(controller: UIViewController, itemType: String, addNewItemViewClosure: @escaping (String) -> ()) {
        
        self.placeHolderText = AddItemAttributeText[itemType]?[AddItem.Attribute.placeHolder.rawValue]
        self.addNewItemViewClosure = addNewItemViewClosure
        
        super.init(frame: controller.view.frame)
        
        setupView()
        staticText.text = AddItemAttributeText[itemType]?[AddItem.Attribute.staticText.rawValue]
        inputText.placeholder = placeHolderText
        inputText.delegate = self
        
        // Switch color if GroceryItem
        if itemType == AddItem.groceryItem.rawValue {
            (staticCircleView.backgroundColor, inputTextCircleView.backgroundColor) = (inputTextCircleView.backgroundColor, staticCircleView.backgroundColor)
            (staticCircleView.borderColor, inputTextCircleView.borderColor) = (inputTextCircleView.borderColor, staticCircleView.borderColor)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.placeHolderText = ""
        self.addNewItemViewClosure = { _ in }
        super.init(coder: aDecoder)
        setupView()
    }
    
    // Performs the initial setup
    private func setupView() {
        Bundle.main.loadNibNamed("AddNewItemView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        
        contentView.autoresizingMask = [
            UIViewAutoresizing.flexibleWidth,
            UIViewAutoresizing.flexibleHeight
        ]
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let text = textField.text!
        guard text != "" else { return true }
        
        self.addNewItemViewClosure(text)
        textField.text = ""
        return true
    }
    
}
