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

struct AddIngestionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedSubstance: String = ""
    @State private var selectedRoute: AdministrationRoute = .oral
    @State private var dose: String = ""
    @State private var selectedUnits: String = "g"
    @State private var ingestionTime: Date = Date()
    
    // Recent substances based on user's SubstanceCompanions
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SubstanceCompanion.substanceName, ascending: true)],
        animation: .default)
    private var substanceCompanions: FetchedResults<SubstanceCompanion>
    
    private var recentSubstances: [String] {
        let companionNames = substanceCompanions.prefix(10).map { $0.substanceName ?? "Unknown" }
        let fallbackSubstances = ["Cannabis", "LSD", "Psilocybin mushrooms", "MDMA", "DMT"]
        return companionNames.isEmpty ? fallbackSubstances : Array(companionNames)
    }
    
    private var availableUnits: [String] {
        // Basic units for different substances
        switch selectedSubstance.lowercased() {
        case "cannabis":
            return ["mg THC", "g", "joint", "bowl"]
        case "lsd":
            return ["μg", "tab", "drop"]
        case "psilocybin mushrooms":
            return ["mg Psilocybin", "g", "cap"]
        case "mdma":
            return ["mg", "pill"]
        case "dmt":
            return ["mg", "ml"]
        default:
            return ["mg", "g", "ml", "pill", "tab"]
        }
    }
    
    init() {
        // Will be set when view appears based on recent substances
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Substance")) {
                    Picker("Substance", selection: $selectedSubstance) {
                        ForEach(recentSubstances, id: \.self) { substance in
                            Text(substance).tag(substance)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section(header: Text("Route")) {
                    Picker("Route", selection: $selectedRoute) {
                        ForEach(AdministrationRoute.allCases, id: \.self) { route in
                            Text(route.displayName).tag(route)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section(header: Text("Dose")) {
                    HStack {
                        TextField("Amount", text: $dose)
                        
                        Picker("Units", selection: $selectedUnits) {
                            ForEach(availableUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }

                Section(header: Text("Time")) {
                    DatePicker("Time", selection: $ingestionTime, displayedComponents: [.hourAndMinute])
                }
            }
            .navigationTitle("Add Ingestion")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addIngestion()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(dose.isEmpty || selectedSubstance.isEmpty)
                }
            }
        }
        .onAppear {
            if selectedSubstance.isEmpty && !recentSubstances.isEmpty {
                selectedSubstance = recentSubstances[0]
            }
        }
        .onChange(of: selectedSubstance) {
            // Update units when substance changes
            if !availableUnits.contains(selectedUnits) {
                selectedUnits = availableUnits.first ?? "mg"
            }
        }
    }

    private func addIngestion() {
        withAnimation {
            let experience = getExperienceFor(date: ingestionTime)

            let newIngestion = Ingestion(context: viewContext)
            newIngestion.identifier = UUID()
            newIngestion.time = ingestionTime
            newIngestion.creationDate = Date()
            newIngestion.substanceName = selectedSubstance
            newIngestion.dose = Double(dose) ?? 0
            newIngestion.units = selectedUnits
            newIngestion.administrationRoute = selectedRoute.rawValue
            newIngestion.experience = experience

            // Get or create substance companion
            let companion = getOrCreateCompanion(for: selectedSubstance)
            newIngestion.substanceCompanion = companion
            newIngestion.color = companion.colorAsText

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func getExperienceFor(date: Date) -> Experience {
        if let latestExperience = PersistenceController.shared.getLatestActiveExperience() {
            // If the latest experience is recent (e.g. within 12 hours), use it.
            let twelveHours: TimeInterval = 12 * 60 * 60
            if let lastIngestionTime = latestExperience.ingestionsSorted.last?.time,
               date.timeIntervalSince(lastIngestionTime) < twelveHours {
                latestExperience.sortDate = date // Update sort date to keep it recent
                return latestExperience
            }
        }

        // Otherwise, create a new experience.
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