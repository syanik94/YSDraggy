//
//  UIView+Extensions.swift
//  
//
//  Created by Yanik Simpson on 8/9/20.
//

import UIKit

extension UIView {
    
    func roundTopCorners(radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topRight, .topLeft],
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
