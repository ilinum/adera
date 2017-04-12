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

let cache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    func loadFromCache(imageURL: String) {
        if let cachedImage = cache.object(forKey: imageURL as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        let url = URL(string: imageURL)
        let request = URLRequest(url: url!)
        let dataTask = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil {
                print(error ?? "error")
                return
            }
            
            DispatchQueue.main.async {
                if let networkImage = UIImage(data: data!) {
                    cache.setObject(networkImage, forKey: imageURL as AnyObject)
                    self.image = networkImage
                }
            }
        }
        dataTask.resume()
    }
    
    func storeInCache(imageURL: String, image: UIImage) {
        cache.setObject(image, forKey: imageURL as AnyObject)
    }
}
