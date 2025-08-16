//
//  Item.swift
//  Laplasian
//
//  Created by Andrii Ieroshevych on 16.08.2025.
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
