//
//  CircleView.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 10/9/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import UIKit

@IBDesignable
class CircleView: UIView {

    @IBInspectable var borderColor: UIColor? {
        didSet {
            setupView()
        }
    }
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = borderColor?.cgColor
    }

}
