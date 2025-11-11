//
//  CameraPlusApp.swift
//  CameraPlus
//
//  Created by Rafael GPL on 10/4/25.
//

import SwiftUI
import CoreData

@main
struct CameraPlusApp: App {
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CameraPlusView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)

        }
    }
}
