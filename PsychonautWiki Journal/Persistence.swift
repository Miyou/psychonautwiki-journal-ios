// Copyright (c) 2022. Isaak Hanimann.
// This file is part of PsychonautWiki Journal.
//
// PsychonautWiki Journal is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public Licence as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// PsychonautWiki Journal is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with PsychonautWiki Journal. If not, see https://www.gnu.org/licenses/gpl-3.0.en.html.

import CloudKit
import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = .init(inMemory: true)

    let container: NSPersistentCloudKitContainer
    static let needsToSeeWelcomeKey = "needsToSeeWelcome"
    static let isEyeOpenKey1 = "isEyeOpen"
    static let isEyeOpenKey2 = "isEyeOpen2"
    static let timeDisplayStyleKey = "timeDisplayStyle"
    static let timeDisplayStyleDurationSectionKey = "timeDisplayStyleDurationSection"
    static let isHidingDosageDotsKey = "isHidingDosageDots"
    static let isHidingToleranceChartInExperienceKey = "isHidingToleranceChartInExperience"
    static let isHidingSubstanceInfoInExperienceKey = "isHidingSubstanceInfoInExperience"
    static let areRedosesDrawnIndividuallyKey = "areRedosesDrawnIndividually"
    static let shouldAutomaticallyStartLiveActivityKey = "shouldAutomaticallyStartLiveActivity"
    static let independentSubstanceHeightKey = "independentSubstanceHeight"
    static let lastIngestionTimeOfExperienceWhereAddIngestionTappedKey =
        "lastIngestionTimeOfExperienceWhereAddIngestionTapped"
    static let clonedIngestionTimeKey = "clonedIngestionTimeKey"
    static let iCloudSyncEnabledKey = "iCloudSyncEnabled"

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private static let modelName = "Main"
    private static let appGroupIdentifier = "group.com.isaakhanimann.journal"
    private static let localStoreName = "\(modelName)-local.sqlite"
    private static let cloudStoreName = "\(modelName)-cloud.sqlite"

    private var localStoreDescription: NSPersistentStoreDescription {
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier)!
        let localStoreURL = appGroupURL.appendingPathComponent(PersistenceController.localStoreName)
        let description = NSPersistentStoreDescription(url: localStoreURL)
        description.configuration = "Local"
        #if APP_WIDGET
            description.setOption(true as NSNumber, forKey: NSReadOnlyPersistentStoreOption)
        #endif
        return description
    }

    private var cloudStoreDescription: NSPersistentStoreDescription {
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier)!
        let cloudStoreURL = appGroupURL.appendingPathComponent(PersistenceController.cloudStoreName)
        let description = NSPersistentStoreDescription(url: cloudStoreURL)
        description.configuration = "Cloud"

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(
            true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.isaakhanimann.journal")
        cloudKitContainerOptions.databaseScope = .private
        description.cloudKitContainerOptions = cloudKitContainerOptions

        #if APP_WIDGET
            description.setOption(true as NSNumber, forKey: NSReadOnlyPersistentStoreOption)
        #endif

        return description
    }

    init(inMemory: Bool = false) {
        guard
            let modelURL = Bundle.main.url(
                forResource: PersistenceController.modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("Failed to load Core Data model")
        }

        // Set up configurations on the model
        model.setEntities(model.entities, forConfigurationName: "Local")
        model.setEntities(model.entities, forConfigurationName: "Cloud")

        container = NSPersistentCloudKitContainer(
            name: PersistenceController.modelName, managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // One-time migration for users updating to the version with the toggle
            let migrationKey = "hasPerformedStoreLayoutMigration"
            if !UserDefaults.standard.bool(forKey: migrationKey) {
                migrateToOptionaliCloudStore(migrationKey: migrationKey)
            }

            let iCloudSyncEnabled = UserDefaults.standard.bool(
                forKey: PersistenceController.iCloudSyncEnabledKey)

            if iCloudSyncEnabled {
                container.persistentStoreDescriptions = [cloudStoreDescription]
            } else {
                container.persistentStoreDescriptions = [localStoreDescription]
            }
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                if error.code == 134081 && error.domain == "NSCocoaErrorDomain" {
                    // This can happen during migration if the store is already loaded.
                    // We will ignore it here, as a restart is recommended anyway.
                    print("Ignoring error 134081, assuming it's a post-migration artifact.")
                    return
                }
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        // Configure for synchronization
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Set up proper remote change notifications following Apple's best practices
        let viewContext = self.viewContext

        // Listen for remote changes from CloudKit
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { notification in
            print("📡 Remote change notification received")

            // Process the remote change on the main context
            viewContext.perform {
                // Merge changes from the persistent store coordinator
                viewContext.mergeChanges(fromContextDidSave: notification)
                print("🔄 Remote changes merged into view context")

                // Ensure all fault objects are refreshed
                viewContext.refreshAllObjects()
                print("🔄 All objects refreshed")
            }
        }

        // Also listen for context did save notifications to catch all changes
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { notification in
            guard let context = notification.object as? NSManagedObjectContext,
                context != viewContext,
                context.persistentStoreCoordinator == viewContext.persistentStoreCoordinator
            else {
                return
            }

            print("📡 Context save notification from background context")
            viewContext.perform {
                viewContext.mergeChanges(fromContextDidSave: notification)
                print("🔄 Background changes merged into view context")
            }
        }
    }

    func toggleiCloudSync(enabled: Bool, completion: @escaping (Error?) -> Void) {
        if enabled {
            enableiCloudSync(completion: completion)
        } else {
            disableiCloudSync(completion: completion)
        }
    }

    private func enableiCloudSync(completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let coordinator = self.container.persistentStoreCoordinator
            guard let currentStore = coordinator.persistentStores.first,
                let oldStoreURL = currentStore.url
            else {
                DispatchQueue.main.async {
                    completion(
                        NSError(
                            domain: "PersistenceController", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "No persistent store found."]))
                }
                return
            }
            let newDescription = self.cloudStoreDescription

            do {
                // Migrate the store from local to cloud
                try coordinator.migratePersistentStore(
                    currentStore, to: newDescription.url!, options: newDescription.options,
                    withType: NSSQLiteStoreType)

                self.container.persistentStoreDescriptions = [newDescription]
                self.container.loadPersistentStores { _, error in
                    if let error = error as NSError?,
                        error.code == 134081 && error.domain == "NSCocoaErrorDomain"
                    {
                        print(
                            "Ignoring error 134081 during toggle, assuming it's a post-migration artifact that will resolve on restart."
                        )
                        self.deleteStore(at: oldStoreURL)  // Clean up the old local store file
                        DispatchQueue.main.async {
                            completion(nil)  // Report success to user
                        }
                        return
                    }

                    if let error = error {
                        DispatchQueue.main.async {
                            completion(error)
                        }
                    } else {
                        // Success! Clean up the old store file.
                        self.deleteStore(at: oldStoreURL)
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    private func disableiCloudSync(completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Step 1: Delete the CloudKit zone to wipe server data
            let containerIdentifier = "iCloud.com.isaakhanimann.journal"
            let container = CKContainer(identifier: containerIdentifier)
            let database = container.privateCloudDatabase
            let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone")

            database.delete(withRecordZoneID: zoneID) { _, error in
                if let ckError = error as? CKError, ckError.code == .zoneNotFound {
                    print(
                        "CloudKit zone not found, which is okay when disabling sync. Proceeding with local migration."
                    )
                } else if let error = error {
                    print("Failed to delete CloudKit zone: \(error)")
                    DispatchQueue.main.async {
                        completion(error)
                    }
                    return
                } else {
                    print("Successfully deleted CloudKit zone.")
                }

                // Step 2: Proceed with migrating the store from cloud to local
                let coordinator = self.container.persistentStoreCoordinator
                guard let currentStore = coordinator.persistentStores.first,
                    let oldStoreURL = currentStore.url
                else {
                    DispatchQueue.main.async {
                        completion(
                            NSError(
                                domain: "PersistenceController", code: 2,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Store went away during cloud zone deletion."
                                ]))
                    }
                    return
                }
                let newDescription = self.localStoreDescription

                do {
                    try coordinator.migratePersistentStore(
                        currentStore, to: newDescription.url!, options: newDescription.options,
                        withType: NSSQLiteStoreType)

                    self.container.persistentStoreDescriptions = [newDescription]
                    self.container.loadPersistentStores { _, error in
                        if let error = error as NSError?,
                            error.code == 134081 && error.domain == "NSCocoaErrorDomain"
                        {
                            print(
                                "Ignoring error 134081 during toggle, assuming it's a post-migration artifact that will resolve on restart."
                            )
                            self.deleteStore(at: oldStoreURL)  // Clean up the old cloud store file
                            DispatchQueue.main.async {
                                completion(nil)  // Report success to user
                            }
                            return
                        }

                        if let error = error {
                            DispatchQueue.main.async {
                                completion(error)
                            }
                        } else {
                            // Success! Clean up the old store file.
                            self.deleteStore(at: oldStoreURL)
                            DispatchQueue.main.async {
                                completion(nil)
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }
    }

    private func deleteStore(at url: URL) {
        let fileManager = FileManager.default
        let storePath = url.path
        let shmPath = storePath + "-shm"
        let walPath = storePath + "-wal"

        for path in [storePath, shmPath, walPath] {
            if fileManager.fileExists(atPath: path) {
                do {
                    try fileManager.removeItem(atPath: path)
                    print("Successfully deleted old store file at \(path)")
                } catch {
                    print("Failed to delete old store file at \(path): \(error)")
                }
            }
        }
    }

    private func migrateToOptionaliCloudStore(migrationKey: String) {
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier)!
        let oldStoreURL = appGroupURL.appendingPathComponent(
            "\(PersistenceController.modelName).sqlite")
        let cloudStoreURL = appGroupURL.appendingPathComponent(
            PersistenceController.cloudStoreName)

        let oldStoreExists = FileManager.default.fileExists(atPath: oldStoreURL.path)
        let cloudStoreExists = FileManager.default.fileExists(atPath: cloudStoreURL.path)

        if oldStoreExists || cloudStoreExists {
            // User has existing data. Assume they were using iCloud.
            UserDefaults.standard.set(
                true, forKey: PersistenceController.iCloudSyncEnabledKey)

            if oldStoreExists && !cloudStoreExists {
                // Rename old store to new cloud store name
                do {
                    try FileManager.default.moveItem(at: oldStoreURL, to: cloudStoreURL)
                    print("Successfully migrated pre-existing iCloud store name.")
                } catch {
                    print("Could not rename old store to cloud store: \(error)")
                }
            } else if oldStoreExists && cloudStoreExists {
                // If both exist, the new one is the source of truth. Remove the old one.
                do {
                    try FileManager.default.removeItem(at: oldStoreURL)
                    print("Removed redundant old store file.")
                } catch {
                    print("Could not remove redundant old store file: \(error)")
                }
            }
        } else {
            // A true new user with no data.
            UserDefaults.standard.set(
                false, forKey: PersistenceController.iCloudSyncEnabledKey)
        }

        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    func deleteEverything() throws {
        let experienceDeleteRequest = Experience.fetchRequest()
        experienceDeleteRequest.includesPropertyValues = false
        let experiences = try viewContext.fetch(experienceDeleteRequest)
        for exp in experiences {
            viewContext.delete(exp)
        }
        let ingestionDeleteRequest = Ingestion.fetchRequest()
        ingestionDeleteRequest.includesPropertyValues = false
        let ingestions = try viewContext.fetch(ingestionDeleteRequest)
        for ing in ingestions {
            viewContext.delete(ing)
        }
        let customDeleteRequest = CustomSubstance.fetchRequest()
        customDeleteRequest.includesPropertyValues = false
        let customs = try viewContext.fetch(customDeleteRequest)
        for cust in customs {
            viewContext.delete(cust)
        }
        let companionDeleteRequest = SubstanceCompanion.fetchRequest()
        companionDeleteRequest.includesPropertyValues = false
        let companions = try viewContext.fetch(companionDeleteRequest)
        for com in companions {
            viewContext.delete(com)
        }
        let unitDeleteRequest = CustomUnit.fetchRequest()
        unitDeleteRequest.includesPropertyValues = false
        let customUnits = try viewContext.fetch(unitDeleteRequest)
        for unit in customUnits {
            viewContext.delete(unit)
        }
        let sprayDeleteRequest = Spray.fetchRequest()
        sprayDeleteRequest.includesPropertyValues = false
        let sprays = try viewContext.fetch(sprayDeleteRequest)
        for spray in sprays {
            viewContext.delete(spray)
        }
        try viewContext.save()
    }

    func migrateCompanionsAndExperienceSortDates() {
        viewContext.performAndWait {
            let ingestionFetchRequest = Ingestion.fetchRequest()
            let allIngestions = (try? viewContext.fetch(ingestionFetchRequest)) ?? []
            var companionsDict: [String: SubstanceCompanion] = [:]
            for ingestion in allIngestions {
                guard let name = ingestion.substanceName else { continue }
                guard let colorUnwrap = ingestion.color else { continue }
                if let companion = companionsDict[name] {
                    ingestion.substanceCompanion = companion
                } else {
                    let companion = SubstanceCompanion(context: viewContext)
                    companion.substanceName = name
                    companion.colorAsText = colorUnwrap
                    ingestion.substanceCompanion = companion
                    companionsDict[name] = companion
                }
            }
            let experienceFetchRequest = Experience.fetchRequest()
            let allExperiences = (try? viewContext.fetch(experienceFetchRequest)) ?? []
            for experience in allExperiences {
                experience.sortDate = experience.ingestionsSorted.first?.time ?? experience.creationDate
            }
            try? viewContext.save()
        }
    }

    func migrateIngestionNamesAndUnits() {
        viewContext.performAndWait {
            let ingestionFetchRequest = Ingestion.fetchRequest()
            let allIngestions = (try? viewContext.fetch(ingestionFetchRequest)) ?? []
            for ingestion in allIngestions {
                if ingestion.substanceName == "Psilocybin Mushrooms" {
                    ingestion.substanceName = "Psilocybin mushrooms"
                }
                if ingestion.units == "mg (THC)" {
                    ingestion.units = "mg"
                }
                if ingestion.units == "70" {
                    ingestion.units = "mg"
                }
            }
            try? viewContext.save()
        }
    }

    func migrateBenzydamineUnits() {
        viewContext.performAndWait {
            let ingestionFetchRequest = Ingestion.fetchRequest()
            let allIngestions = (try? viewContext.fetch(ingestionFetchRequest)) ?? []
            for ingestion in allIngestions {
                if ingestion.substanceName == "Benzydamine" && ingestion.units == "g" {
                    ingestion.units = "mg"
                    ingestion.dose = ingestion.dose * 1000
                }
            }
            try? viewContext.save()
        }
    }

    func migrateCannabisAndMushroomUnits() {
        viewContext.performAndWait {
            let ingestionFetchRequest = Ingestion.fetchRequest()
            let allIngestions = (try? viewContext.fetch(ingestionFetchRequest)) ?? []
            for ingestion in allIngestions {
                if ingestion.substanceName == "Cannabis" && ingestion.units == "mg" {
                    ingestion.units = "mg THC"
                }
                if ingestion.substanceName == "Psilocybin mushrooms" && ingestion.units == "mg" {
                    ingestion.units = "mg Psilocybin"
                }
            }

            let customUnitFetchRequest = CustomUnit.fetchRequest()
            let customUnits = (try? viewContext.fetch(customUnitFetchRequest)) ?? []
            for customUnit in customUnits {
                if customUnit.substanceName == "Cannabis" && customUnit.originalUnit == "mg" {
                    customUnit.originalUnit = "mg THC"
                }
                if customUnit.substanceName == "Psilocybin mushrooms" && customUnit.originalUnit == "mg" {
                    customUnit.originalUnit = "mg Psilocybin"
                }
            }

            try? viewContext.save()
        }
    }

    func migrateColors() {
        viewContext.performAndWait {
            let companionFetchRequest = SubstanceCompanion.fetchRequest()
            let allCompanions = (try? viewContext.fetch(companionFetchRequest)) ?? []
            for companion in allCompanions {
                companion.colorAsText = companion.colorAsText?.uppercased()
            }
            let timedNotesFetchRequest = TimedNote.fetchRequest()
            let allTimedNotes = (try? viewContext.fetch(timedNotesFetchRequest)) ?? []
            for timedNote in allTimedNotes {
                timedNote.colorAsText = timedNote.colorAsText?.uppercased()
            }
            try? viewContext.save()
        }
    }

    func saveViewContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                assertionFailure("Failed to save viewContext: \(error)")
            }
        }
    }

    func getIngestionsBetween(startDate: Date, endDate: Date) -> [Ingestion] {
        let fetchRequest = Ingestion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "(time >= %@) AND (time <= %@)", startDate as NSDate, endDate as NSDate)
        return (try? viewContext.fetch(fetchRequest)) ?? []
    }

    func getLatestActiveExperience() -> Experience? {
        let fetchRequest = Experience.fetchRequest()
        let minusThreeDays: TimeInterval = -3*24*60*60
        let startDate = Date.now.addingTimeInterval(minusThreeDays)
        fetchRequest.predicate = NSPredicate(format: "sortDate >= %@", startDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Experience.sortDate, ascending: false)]
        let experiences = (try? viewContext.fetch(fetchRequest)) ?? []
        return experiences.first { experience in
            experience.isCurrent
        }
    }

    func getLatestExperience() -> Experience? {
        let fetchRequest = Experience.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Experience.sortDate, ascending: false)]
        fetchRequest.fetchLimit = 1
        let experiences = (try? viewContext.fetch(fetchRequest)) ?? []
        return experiences.first
    }

    func getSubstanceCompanions() -> [SubstanceCompanion] {
        let fetchRequest = SubstanceCompanion.fetchRequest()
        return (try? viewContext.fetch(fetchRequest)) ?? []
    }

    func getCustomSubstance(name: String) -> CustomSubstance? {
        let fetchRequest = CustomSubstance.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        let results = try? viewContext.fetch(fetchRequest)
        return results?.first
    }
}
