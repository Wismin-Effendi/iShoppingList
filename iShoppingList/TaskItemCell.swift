//
//  TaskItemCell.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/26/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit

protocol ItemCellCompletionStateDelegate: class {
    func persist(title: String, completed: Bool)
}


class TaskItemCell: UITableViewCell {

    
    @IBOutlet weak var completionButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    weak var delegate: ItemCellCompletionStateDelegate?
    
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
        
        guard let title = titleLabel.text else { return }
        delegate?.persist(title: title, completed: completed)
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
