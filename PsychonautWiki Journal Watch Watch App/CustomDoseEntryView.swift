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
import SwiftUI_Apple_Watch_Decimal_Pad

struct CustomDoseEntryView: View {
    let substanceName: String
    @State private var doseText: String
    @State private var selectedUnits: String
    @State private var selectedRoute: AdministrationRoute = .oral
    @State private var ingestionTime: Date = Date()
    let onSave: () -> Void

    @Environment(\.managedObjectContext) private var viewContext

    @State private var showingAlert = false
    @State private var alertMessage = ""

    init(substanceName: String, initialDose: Double, initialUnits: String, onSave: @escaping () -> Void) {
        self.substanceName = substanceName
        if initialDose > 0 {
            _doseText = State(initialValue: String(initialDose))
        } else {
            _doseText = State(initialValue: "")
        }
        _selectedUnits = State(initialValue: initialUnits)
        self.onSave = onSave
    }

    private var dose: Double {
        Double(doseText) ?? 0.0
    }

    private var availableUnits: [String] {
        switch substanceName.lowercased() {
        case "cannabis":
            return ["g", "mg", "joint", "bowl"]
        case "lsd":
            return ["μg", "tab", "drop"]
        case "psilocybin mushrooms":
            return ["g", "mg", "cap"]
        case "mdma":
            return ["mg", "pill"]
        case "dmt":
            return ["mg", "ml"]
        case "alcohol":
            return ["ml", "drink", "shot"]
        case "caffeine":
            return ["mg", "cup"]
        case "cocaine":
            return ["mg", "line", "g"]
        case "ketamine":
            return ["mg", "bump", "line"]
        default:
            return ["mg", "g", "ml", "pill", "tab"]
        }
    }

    private var commonRoutes: [AdministrationRoute] {
        switch substanceName.lowercased() {
        case "cannabis":
            return [.smoked, .oral, .sublingual, .inhaled]
        case "lsd":
            return [.oral, .sublingual]
        case "psilocybin mushrooms":
            return [.oral]
        case "mdma":
            return [.oral, .insufflated]
        case "dmt":
            return [.smoked, .inhaled, .insufflated]
        case "alcohol":
            return [.oral]
        case "cocaine":
            return [.insufflated, .smoked, .oral]
        case "ketamine":
            return [.insufflated, .intramuscular, .oral]
        default:
            return [.oral, .insufflated, .smoked, .inhaled]
        }
    }

    var body: some View {
        Form {
            Section("Dose") {
                DigiTextView(placeholder: "0.0",
                     text: $doseText,
                     presentingModal: false,
                     alignment: .leading,
                     style: .decimal
                )

                Picker("Units", selection: $selectedUnits) {
                    ForEach(availableUnits, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
            }

            Section("Route") {
                Picker("Route", selection: $selectedRoute) {
                    ForEach(commonRoutes, id: \.self) { route in
                        Text(route.displayName).tag(route)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .padding(.vertical, 8)
            }

            Section("Time") {
                DatePicker("Time", selection: $ingestionTime, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveIngestion()
                }
                .disabled(dose <= 0)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveIngestion() {
        guard dose > 0 else {
            alertMessage = "Please enter a valid dose amount"
            showingAlert = true
            return
        }

        withAnimation {
            let experience = getExperienceFor(date: ingestionTime)

            let newIngestion = Ingestion(context: viewContext)
            newIngestion.identifier = UUID()
            newIngestion.time = ingestionTime
            newIngestion.creationDate = Date()
            newIngestion.substanceName = substanceName
            newIngestion.dose = dose
            newIngestion.units = selectedUnits
            newIngestion.administrationRoute = selectedRoute.rawValue
            newIngestion.experience = experience

            let companion = getOrCreateCompanion(for: substanceName)
            newIngestion.substanceCompanion = companion
            newIngestion.color = companion.colorAsText

            do {
                try viewContext.save()
                onSave()
            } catch {
                alertMessage = "Failed to save ingestion: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func getExperienceFor(date: Date) -> Experience {
        if let latestExperience = PersistenceController.shared.getLatestActiveExperience() {
            let twelveHours: TimeInterval = 12 * 60 * 60
            if let lastIngestionTime = latestExperience.ingestionsSorted.last?.time,
               date.timeIntervalSince(lastIngestionTime) < twelveHours {
                latestExperience.sortDate = date
                return latestExperience
            }
        }

        let newExperience = Experience(context: viewContext)
        newExperience.creationDate = Date()
        newExperience.sortDate = date
        newExperience.title = date.asDateString
        return newExperience
    }

    private func getOrCreateCompanion(for substanceName: String) -> SubstanceCompanion {
        let fetchRequest = SubstanceCompanion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "substanceName == %@", substanceName)

        if let existingCompanion = try? viewContext.fetch(fetchRequest).first {
            return existingCompanion
        } else {
            let newCompanion = SubstanceCompanion(context: viewContext)
            newCompanion.substanceName = substanceName
            newCompanion.colorAsText = SubstanceColor.allCases.randomElement()?.rawValue ?? "BLUE"
            return newCompanion
        }
    }
}

#Preview {
    CustomDoseEntryView(substanceName: "MDMA", initialDose: 100, initialUnits: "mg", onSave: {})
}
