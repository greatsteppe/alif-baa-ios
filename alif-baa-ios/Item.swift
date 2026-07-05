//
//  Item.swift
//  alif-baa-ios
//
//  Created by Janadilov Azamat on 06.07.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
