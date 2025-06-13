// Copyright (c) 2025. Michael Young.
// This file is part of PsychonautWiki Journal Watch Watch App.
//
// PsychonautWiki Journal Watch Watch App is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public Licence as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// PsychonautWiki Journal Watch Watch App is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with PsychonautWiki Journal Watch Watch App. If not, see https://www.gnu.org/licenses/gpl-3.0.en.html.

import SwiftUI
import CoreData

fileprivate struct DoseInfo: Hashable, Identifiable {
    var id: String { "\(dose)\(units)" }
    let dose: Double
    let units: String
}

struct DoseSelectionView: View {
    let substanceName: String
    @Environment(\.managedObjectContext) private var viewContext
    let onSave: () -> Void

    @FetchRequest
    private var recentIngestions: FetchedResults<Ingestion>

    private let defaultUnits: String

    init(substanceName: String, onSave: @escaping () -> Void) {
        self.substanceName = substanceName
        self.onSave = onSave
        self.defaultUnits = DoseSelectionView.getDefaultUnits(for: substanceName)

        self._recentIngestions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Ingestion.time, ascending: false)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "substanceName == %@", substanceName),
                NSPredicate(format: "time >= %@", (Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()) as NSDate)
            ]),
            animation: .default
        )
    }

    private var recentDoses: [DoseInfo] {
        let uniqueDoses = Array(Set(recentIngestions.compactMap { ingestion -> DoseInfo? in
            guard let dose = ingestion.doseUnwrapped, dose > 0,
                  let units = ingestion.units else { return nil }
            return DoseInfo(dose: dose, units: units)
        })).prefix(3)
        return Array(uniqueDoses)
    }

    private static func getDefaultUnits(for substanceName: String) -> String {
        switch substanceName.lowercased() {
        case "cannabis":
            return "g"
        case "lsd":
            return "μg"
        case "psilocybin mushrooms":
            return "g"
        case "mdma":
            return "mg"
        case "dmt":
            return "mg"
        case "cocaine":
            return "mg"
        case "alcohol":
            return "ml"
        case "caffeine":
            return "mg"
        case "ketamine":
            return "mg"
        default:
            return "mg"
        }
    }

    var body: some View {
        List {
            if !recentDoses.isEmpty {
                Section("Recent Doses") {
                    ForEach(recentDoses) { doseInfo in
                        NavigationLink(doseInfo.dose.asRoundedReadableString + " " + doseInfo.units) {
                            CustomDoseEntryView(
                                substanceName: substanceName,
                                initialDose: doseInfo.dose,
                                initialUnits: doseInfo.units,
                                onSave: onSave
                            )
                        }
                    }
                }
            }

            Section("Dose Options") {
                NavigationLink("Enter Custom Dose") {
                    CustomDoseEntryView(
                        substanceName: substanceName,
                        initialDose: 0,
                        initialUnits: defaultUnits,
                        onSave: onSave
                    )
                }
            }
        }
        .navigationTitle(substanceName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DoseSelectionView(substanceName: "MDMA", onSave: {})
}
