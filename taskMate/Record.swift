//
//  Record.swift
//  taskMate
//
//  Created by Shalev on 23/08/2024.
//

import Foundation

struct Record {
    var id: String
    var recordName: String
    var items: [Item]
    var users: [String]
    
    init(recordName: String, items: [Item] = [], users: [String] = [], id: String) {
        self.recordName = recordName
        self.items = items
        self.users = users
        self.id = id
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "recordName": recordName,
            "items": items.map { ["text": $0.text, "isChecked": $0.isChecked] },
            "users": users
        ]
    }
}

