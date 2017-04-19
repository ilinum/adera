//
//  DefaultSettings.swift
//  adera
//
//  Created by Nathan Chapman on 3/22/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

// All default user settings go here
import UIKit

public struct AccountDefaultSettings {
    static var lightOrange = UIColor(red: 253/255, green: 148/255, blue: 39/255, alpha: 1.0)
    static var lightYellow = UIColor(red: 1.0, green: 202/255, blue: 40/255, alpha: 1.0)
    static var lightGreen = UIColor(red: 81/255, green: 210/255, blue: 103/255, alpha: 1.0)
    static var seafoam = UIColor(red: 55/255, green: 214/255, blue: 182/255, alpha: 1.0)
    static var lightBlue = UIColor(red: 56/255, green: 190/255, blue: 253/255, alpha: 1.0)
    static var aqua = UIColor(red: 0, green: 122/255, blue: 1.0, alpha: 1.0)
    
    static var colors = [AccountDefaultSettings.lightOrange,
                         AccountDefaultSettings.lightYellow,
                         AccountDefaultSettings.lightGreen,
                         AccountDefaultSettings.seafoam,
                         AccountDefaultSettings.lightBlue,
                         AccountDefaultSettings.aqua]
    
    static var lightBackgroundColor = UIColor.white
    static var lightTextColor = UIColor.black
    static var darkBackgroundColor = UIColor.darkGray
    static var darkTextColor = UIColor.white
    
    static var fontSize = 17
    static var highlightColorIndex = 5
    static var colorScheme = "light"
    static var autoNightThemeEnabled = true
    
    static var channelSortingMethod = "date"
    static var topicSortingMethod = "date"
}
