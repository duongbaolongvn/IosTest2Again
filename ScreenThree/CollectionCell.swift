//
//  ScreenThreeViewControllerCell.swift
//  FridayFinish
//
//  Created by Duong Bao Long on 11/18/21.
//

import UIKit
class CollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var fillView: UIView!
    @IBOutlet weak var photoImage: UIImageView!
    override func draw(_ rect: CGRect) {
        layer.borderColor = UIColor.blue.cgColor
        fillView.alpha = 0.2
        layer.masksToBounds = true
    }
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 3: 0
            fillView.layer.backgroundColor = isSelected ? UIColor.blue.cgColor: nil
        }
    }
}

