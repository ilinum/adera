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
