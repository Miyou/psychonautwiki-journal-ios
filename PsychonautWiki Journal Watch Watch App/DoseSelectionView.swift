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
    let substance: Substance
    @Environment(\.managedObjectContext) private var viewContext
    let onSave: () -> Void

    @State private var suggestions: [any SuggestionProtocol] = []

    init(substance: Substance, onSave: @escaping () -> Void) {
        self.substance = substance
        self.onSave = onSave
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
                                            substance: substance,
                                            initialDose: doseInfo.dose ?? 0.0,
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
                        substance: substance,
                        initialDose: 0,
                        onSave: onSave
                    )
                }
            }
        }
        .onAppear {
            self.suggestions = WatchOSSubstanceProvider.shared.getSuggestions(for: substance.name)
        }
        .navigationTitle(substance.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DoseSelectionView(substance: SubstanceRepo.shared.getSubstance(name: "MDMA")!, onSave: {})
}
