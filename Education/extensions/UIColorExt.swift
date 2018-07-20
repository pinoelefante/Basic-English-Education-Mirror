//
//  UIColorExt.swift
//  Education
//
//  Created by Elefante Giuseppe on 20/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit

extension UIColor {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        return getRed(&r, green: &g, blue: &b, alpha: &a) ? (r,g,b,a) : nil
    }
}
