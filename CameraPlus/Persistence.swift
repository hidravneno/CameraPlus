//
//  Persistence.swift
//  CameraPlus
//
//  Created by francisco eduardo aramburo reyes on 08/11/25.
//

import CoreData

struct PersistenceController {
    static let shared  = PersistenceController()
    
    let container : NSPersistentContainer
    
    init() {
            container = NSPersistentContainer(name: "Model")
            container.loadPersistentStores { description, error in
                if let error = error {
                    fatalError("Error loading Core Data: \(error)")
                }
            }
        }
    }
