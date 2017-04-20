//
//  extensions.swift
//  adera
//
//  Created by Nathan Chapman on 4/5/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit

// From http://stackoverflow.com/a/34540310/3931300
extension String {
    func indexDistance(of character: Character) -> Int? {
        guard let index = characters.index(of: character) else { return nil }
        return distance(from: startIndex, to: index)
    }
}

// From https://bencoding.com/2015/07/30/how-to-tint-an-uiimageview-image/
extension UIImageView {
    func tintImageColor(color : UIColor) {
        self.image = self.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.tintColor = color
    }
}

// From http://stackoverflow.com/a/39425959/3931300
extension UnicodeScalar {
    var isEmoji: Bool {
        switch value {
        case 0x3030, 0x00AE, 0x00A9, // Special Characters
        0x1D000 ... 0x1F77F, // Emoticons
        0x2100 ... 0x27BF, // Misc symbols and Dingbats
        0xFE00 ... 0xFE0F, // Variation Selectors
        0x1F900 ... 0x1F9FF: // Supplemental Symbols and Pictographs
            return true
        default: return false
        }
    }
    
    var isZeroWidthJoiner: Bool {
        return value == 8205
    }
}

// From http://stackoverflow.com/a/39425959/3931300
extension String {
    var glyphCount: Int {
        let richText = NSAttributedString(string: self)
        let line = CTLineCreateWithAttributedString(richText)
        return CTLineGetGlyphCount(line)
    }
    
    var isSingleEmoji: Bool {
        return glyphCount == 1 && containsEmoji
    }

    var containsEmoji: Bool {
        return !unicodeScalars.filter { $0.isEmoji }.isEmpty
    }
    
    var containsOnlyEmoji: Bool {
        return unicodeScalars.first(where: { !$0.isEmoji && !$0.isZeroWidthJoiner }) == nil
    }
    
    // The next tricks are mostly to demonstrate how tricky it can be to determine emoji's
    // If anyone has suggestions how to improve this, please let me know
    var emojiString: String {
        return emojiScalars.map { String($0) }.reduce("", +)
    }
    
    var emojis: [String] {
        var scalars: [[UnicodeScalar]] = []
        var currentScalarSet: [UnicodeScalar] = []
        var previousScalar: UnicodeScalar?
        
        for scalar in emojiScalars {
            if let prev = previousScalar, !prev.isZeroWidthJoiner && !scalar.isZeroWidthJoiner {
                scalars.append(currentScalarSet)
                currentScalarSet = []
            }
            currentScalarSet.append(scalar)
            previousScalar = scalar
        }
        
        scalars.append(currentScalarSet)
        return scalars.map { $0.map{ String($0) } .reduce("", +) }
    }
    
    fileprivate var emojiScalars: [UnicodeScalar] {
        var chars: [UnicodeScalar] = []
        var previous: UnicodeScalar?
        for cur in unicodeScalars {
            if let previous = previous, previous.isZeroWidthJoiner && cur.isEmoji {
                chars.append(previous)
                chars.append(cur)
            } else if cur.isEmoji {
                chars.append(cur)
            }
            previous = cur
        }
        return chars
    }
}

// From: http://stackoverflow.com/a/34695037/3931300 with modification
public extension UIView {
    func fadeIn(withDuration duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    
    func fadeOut(withDuration duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
    
    func fadeOutRemove(withDuration duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        }, completion: {(value: Bool) in
            self.removeFromSuperview()
        })
    }
}

extension UIImageView {
    func loadFromCache(imageURL: String) {
        if let cachedImage = AppDelegate.cache.object(forKey: imageURL as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        let url = URL(string: imageURL)
        let request = URLRequest(url: url!)
        let dataTask = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil { return }
            DispatchQueue.main.async {
                if let networkImage = UIImage(data: data!) {
                    AppDelegate.cache.setObject(networkImage, forKey: imageURL as AnyObject)
                    self.image = networkImage
                }
            }
        }
        dataTask.resume()
    }
    
    func storeInCache(imageURL: String, image: UIImage) {
        AppDelegate.cache.setObject(image, forKey: imageURL as AnyObject)
    }
}

// From: http://stackoverflow.com/a/32824659/3931300
extension UIView {
    func bindFrameToSuperviewBounds() {
        guard let superview = self.superview else {
            print("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
    }
}
