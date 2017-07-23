//
//  AddNewItemView.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit


class AddNewItemView: UIView, UITextFieldDelegate {

    var placeHolderText: String!
    var addNewItemViewClosure: (String) -> ()
    
    init(controller: UIViewController, placeHolderText: String, addNewItemViewClosure: @escaping (String) -> ()) {
        
        self.placeHolderText = placeHolderText
        self.addNewItemViewClosure = addNewItemViewClosure
        
        super.init(frame: controller.view.frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        self.backgroundColor = UIColor.lightGray
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 48))
        headerView.backgroundColor = UIColor.groupTableViewBackground
        
        let textField = UITextField(frame: CGRect(x: 8, y: 4, width: headerView.frame.size.width - 16, height: 40))
        textField.backgroundColor = UIColor.white
        textField.textColor = UIColor.darkGray
        textField.layer.cornerRadius = 20.0
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.lightGray.cgColor
        
        textField.placeholder = self.placeHolderText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.clearButtonMode = .always
        textField.delegate = self
        
        headerView.addSubview(textField)
        
        self.addSubview(headerView)
    
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let text = textField.text!
        
        self.addNewItemViewClosure(text)
        textField.text = ""
        
        return true
    }
    
}
