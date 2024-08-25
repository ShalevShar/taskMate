//
//  User.swift
//  taskMate
//
//  Created by Shalev on 23/08/2024.
//

import Foundation

class User {
    var username: String
    var password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func toDictionary() -> [String: Any] {
        return ["username": username, "password": password]
    }
}
