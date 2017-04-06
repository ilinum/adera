//
//  extensions.swift
//  adera
//
//  Created by Nathan Chapman on 4/5/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation

// From http://stackoverflow.com/a/34540310/3931300
extension String {
    func indexDistance(of character: Character) -> Int? {
        guard let index = characters.index(of: character) else { return nil }
        return distance(from: startIndex, to: index)
    }
}
