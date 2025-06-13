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

import CoreData
import SwiftUI

struct DoseSelectionView: View {
    let substanceName: String
    @Environment(\.managedObjectContext) private var viewContext
    let onSave: () -> Void

    @State private var suggestions: [any SuggestionProtocol] = []

    private let defaultUnits: String

    init(substanceName: String, onSave: @escaping () -> Void) {
        self.substanceName = substanceName
        self.onSave = onSave
        self.defaultUnits = DoseSelectionView.getDefaultUnits(for: substanceName)
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
            if !suggestions.isEmpty {
                Section("Suggestions") {
                    ForEach(suggestions, id: \.id) { suggestion in
                        if let pureSuggestion = suggestion as? PureSubstanceSuggestions {
                            ForEach(pureSuggestion.dosesAndUnit, id: \.dose) { doseInfo in
                                if let doseDescription = doseInfo.doseDescription {
                                    let linkTitle =
                                        doseDescription + " " + pureSuggestion.route.displayName
                                    NavigationLink(linkTitle) {
                                        CustomDoseEntryView(
                                            substanceName: substanceName,
                                            initialDose: doseInfo.dose ?? 0.0,
                                            initialUnits: doseInfo.units,
                                            onSave: onSave
                                        )
                                    }
                                }
                            }
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
        .onAppear {
            self.suggestions = WatchOSSubstanceProvider.shared.getSuggestions(for: substanceName)
        }
        .navigationTitle(substanceName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DoseSelectionView(substanceName: "MDMA", onSave: {})
}
