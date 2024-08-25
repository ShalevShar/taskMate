//
//  Item.swift
//  taskMate
//
//  Created by Shalev on 23/08/2024.
//

import Foundation

struct Item {
    let id: String
    var text: String
    var isChecked: Bool
    
    init(text: String, isChecked: Bool, id: String) {
        self.id = id
        self.text = text
        self.isChecked = isChecked
    }
}
