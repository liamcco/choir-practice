//
//  Item.swift
//  practice
//
//  Created by Liam Cotton on 31/03/2026.
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
