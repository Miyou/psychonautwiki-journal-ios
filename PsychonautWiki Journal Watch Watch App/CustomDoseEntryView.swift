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
import SwiftUI_Apple_Watch_Decimal_Pad

struct CustomDoseEntryView: View {
    let substance: Substance
    @State private var doseText: String
    @State private var selectedUnits: String
    @State private var selectedRoute: AdministrationRoute
    @State private var ingestionTime: Date = Date()
    let onSave: () -> Void

    @Environment(\.managedObjectContext) private var viewContext

    @State private var showingAlert = false
    @State private var alertMessage = ""

    init(
        substance: Substance, initialDose: Double,
        onSave: @escaping () -> Void
    ) {
        self.substance = substance
        if initialDose > 0 {
            _doseText = State(initialValue: String(initialDose))
        } else {
            _doseText = State(initialValue: "")
        }

        let initialRoute = substance.roas.first?.name ?? .oral
        _selectedRoute = State(initialValue: initialRoute)

        let allUnits = substance.roas.compactMap { $0.dose?.units }
        let initialUnits =
            substance.getDose(for: initialRoute)?.units ?? Array(Set(allUnits)).first ?? ""
        _selectedUnits = State(initialValue: initialUnits)

        self.onSave = onSave
    }

    private var dose: Double {
        Double(doseText) ?? 0.0
    }

    private var availableUnits: [String] {
        let documentedUnits = substance.roas.compactMap { $0.dose?.units }
        let otherUnits = UnitPickerOptions.allCases.map { $0.rawValue }.filter { $0 != "custom" }
        let allUnits = documentedUnits + otherUnits
        return allUnits.removingDuplicates()
    }

    private var commonRoutes: [AdministrationRoute] {
        let documentedRoutes = substance.roas.map { $0.name }
        let otherRoutes = AdministrationRoute.allCases.filter { !documentedRoutes.contains($0) }
        return documentedRoutes + otherRoutes
    }

    var body: some View {
        Form {
            Section("Dose") {
                DigiTextView(
                    placeholder: "0.0",
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
        .onChange(of: selectedRoute) { _, newRoute in
            if let newUnits = substance.getDose(for: newRoute)?.units {
                selectedUnits = newUnits
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
            Button("OK") {}
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
            newIngestion.substanceName = substance.name
            newIngestion.dose = dose
            newIngestion.units = selectedUnits
            newIngestion.administrationRoute = selectedRoute.rawValue
            newIngestion.experience = experience

            let companion = getOrCreateCompanion(for: substance.name)
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
                date.timeIntervalSince(lastIngestionTime) < twelveHours
            {
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

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
}

#Preview {
    CustomDoseEntryView(
        substance: SubstanceRepo.shared.getSubstance(name: "MDMA")!, initialDose: 100,
        onSave: {})
}
