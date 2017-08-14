//
//  TaskItemCell.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData

protocol ItemCellCompletionStateDelegate: class {
    func cloneToWarehouseIfRepeatedItem(identifier: String)
}


class TaskItemCell: UITableViewCell {

    
    @IBOutlet weak var completionButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    weak var delegate: ItemCellCompletionStateDelegate?
    
    var model: GroceryItem!  // need to make this generic, for now it's concrete.
    
    
    var completed = false {
        didSet {
            setCompletionCheckBoxWithAnimation()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func completionButtonTapped(_ sender: UIButton) {
        completed = !completed
        model.completed = completed
        print("Value of completed flag: \(completed)")
        let itemIdentifier = model.identifier
        delegate?.cloneToWarehouseIfRepeatedItem(identifier: itemIdentifier)
    }
    
    private func setCompletionCheckBoxWithAnimation() {
        let image: UIImage = completed ?  #imageLiteral(resourceName: "check_icon") : #imageLiteral(resourceName: "uncheck")
        let oldImage: UIImage = completed ? #imageLiteral(resourceName: "uncheck") : #imageLiteral(resourceName: "check_icon")
        let button = self.completionButton
        UIView.animate(withDuration: 0.15, animations: {
            button?.alpha = 0.0
        }, completion: { finished in
            button?.imageView?.animationImages = [oldImage, image]
            button?.imageView?.startAnimating()
            UIView.animate(withDuration: 0.25, animations: {
                button?.alpha = 1.0
                button?.imageView?.stopAnimating()
            })
            self.completionButton.setImage(image, for: .normal)
        })
    }
}
