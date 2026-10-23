//
//  PersistenceController.swift
//  Spot
//
//  Created by Leon Böttger on 06.01.25.
//

import CoreData
import LUI
import UIKit

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                if error.code == NSMigrationError {
                    let storeURL = storeDescription.url
                    if let storeURL {
                        let fileManager = FileManager.default
                        do {
                            try fileManager.removeItem(at: storeURL)

                        } catch {}

                        // Retry loading the persistent store
                        container.loadPersistentStores { _, error in
                            if let error {
                                fatalError("Unresolved error \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        })

        return container
    }()

    /// background thread for database work in background.
    private let databaseBackgroundQueue = DispatchQueue(label: "databaseQueue", qos: .utility)

    func getDatabaseQueue() -> DispatchQueue {
        databaseBackgroundQueue
    }

    /// Peforms all work on a background queue and merges changes into main context afterwards (serialized).
    func modifyDatabaseBackground(task: @escaping (NSManagedObjectContext) -> Void) {
        /// perform all operations in background - serialized (!!!)
        getDatabaseQueue().async {
            /// create new background context
            let privateMOC = container.newBackgroundContext()

            /// serialize operations
            privateMOC.performAndWait {
                /// Perform task
                task(privateMOC)

                if privateMOC.hasChanges {
                    /// merge in main context
                    do {
                        try privateMOC.save()

                    } catch {}
                }
            }
        }
    }

    /// Writes any changes to CoreData model to disk
    func store() {
        let context = container.viewContext

        // perform action synchronously
        context.performAndWait {
            /// only perform if any changes made to model
            if context.hasChanges {
                do {
                    /// write to disk
                    try context.save()
                } catch {
                    /// some error occured
                }
            }
        }
    }
}
