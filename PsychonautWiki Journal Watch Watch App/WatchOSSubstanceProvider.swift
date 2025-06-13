//
//  WatchOSSubstanceProvider.swift
//  PsychonautWiki Journal Watch Watch App
//
//  Created by Michael Young on 7/17/24.
//

import CoreData
import Foundation

class WatchOSSubstanceProvider {
    static let shared = WatchOSSubstanceProvider()

    private let substanceRepo = SubstanceRepo.shared

    func getAllSubstances() -> [Substance] {
        return substanceRepo.substances
    }

    func getSuggestions(for substanceName: String) -> [any SuggestionProtocol] {
        let sortedIngestions = getSortedIngestions(for: substanceName)
        return PsychonautWiki_Journal_Watch_Watch_App.getSuggestions(
            sortedIngestions: sortedIngestions, customUnits: []
        )
        .filter { suggestion in
            if let pureSuggestion = suggestion as? PureSubstanceSuggestions {
                return pureSuggestion.substance.name == substanceName
            }
            if let customSuggestion = suggestion as? CustomUnitSuggestions {
                return customSuggestion.customUnit.substanceNameUnwrapped == substanceName
            }
            if let customSubstanceSuggestion = suggestion as? CustomSubstanceSuggestions {
                return customSubstanceSuggestion.customSubstanceName == substanceName
            }
            return false
        }
    }

    private func getSortedIngestions(for substanceName: String) -> [Ingestion] {
        let ingestionFetchRequest = Ingestion.fetchRequest()
        ingestionFetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Ingestion.creationDate, ascending: false)
        ]
        ingestionFetchRequest.predicate = NSPredicate(format: "substanceName == %@", substanceName)
        ingestionFetchRequest.fetchLimit = 100
        do {
            return try PersistenceController.shared.viewContext.fetch(ingestionFetchRequest)
        } catch {
            print("Failed to fetch ingestions: \(error)")
            return []
        }
    }
}
