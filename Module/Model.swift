//
//  Module.swift
//  FridayFinish
//
//  Created by Duong Bao Long on 11/17/21.
//

import UIKit
import Alamofire
class Model {
    static let main = Model()
    
    var projects: [Project] = []
    
    func addProject(_ name: String) {
        let newItem = Project(id: UUID().uuidString, name: name)
        projects.append(newItem)
    }
    func loadProject() {
        
        AF.request("https://tapuniverse.com/xproject")
            .validate()
            .responseJSON { (response) in
                let value = response.value
                if let json = value as? [String: Any],
                 let project = json["projects"] as? [[String: Any]]{
                    for i in 0..<project.count {
                        if let id = project[i]["id"] as? Int,
                           let name = project[i]["name"] as? String {
                            let project = Project(id: "\(id)", name: name)
                            self.projects.append(project)
                        }
                    }
                    NotificationCenter.default.post(name: Notification.Name("NotiPostApi"), object: nil)
                }
            }
    }
}
