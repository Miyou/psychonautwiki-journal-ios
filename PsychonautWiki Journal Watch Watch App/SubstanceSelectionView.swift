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

struct SubstanceSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var path = NavigationPath()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SubstanceCompanion.substanceName, ascending: true)],
        animation: .default)
    private var substanceCompanions: FetchedResults<SubstanceCompanion>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingestion.time, ascending: false)],
        predicate: NSPredicate(format: "time >= %@", (Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()) as NSDate),
        animation: .default)
    private var recentIngestions: FetchedResults<Ingestion>

    private var recentSubstances: [String] {
        let recentSubstanceNames = Array(Set(recentIngestions.compactMap { $0.substanceName })).prefix(5)
        let fallbackSubstances = ["Cannabis", "LSD", "Psilocybin mushrooms", "MDMA", "DMT"]
        return recentSubstanceNames.isEmpty ? fallbackSubstances : Array(recentSubstanceNames)
    }

    private var allSubstances: [String] {
        let allKnownSubstances = [
            "Cannabis", "LSD", "Psilocybin mushrooms", "MDMA", "DMT", "Cocaine", "Alcohol",
            "Caffeine", "Nicotine", "Amphetamine", "Methamphetamine", "Ketamine", "GHB",
            "2C-B", "Mescaline", "Ayahuasca", "5-MeO-DMT", "Salvia divinorum"
        ]
        return allKnownSubstances.sorted()
    }

    private var filteredSubstances: [String] {
        if searchText.isEmpty {
            return allSubstances
        } else {
            return allSubstances.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                recentSubstancesSection
                searchResultsSection
            }
            .navigationDestination(for: String.self) { substanceName in
                DoseSelectionView(substanceName: substanceName, onSave: {
                    path.removeLast()
                    dismiss()
                })
            }
            .navigationTitle("Substance")
            .searchable(text: $searchText, prompt: "Search substances")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var recentSubstancesSection: some View {
        Group {
            if !recentSubstances.isEmpty && searchText.isEmpty {
                Section("Recent") {
                    ForEach(recentSubstances, id: \.self) { substance in
                        NavigationLink(value: substance) {
                            HStack {
                                Circle()
                                    .fill(getSubstanceColor(substance))
                                    .frame(width: 8, height: 8)
                                Text(substance)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
        }
    }

    private var searchResultsSection: some View {
        Section(searchText.isEmpty ? "All Substances" : "Search Results") {
            ForEach(filteredSubstances, id: \.self) { substance in
                NavigationLink(value: substance) {
                    HStack {
                        Circle()
                            .fill(getSubstanceColor(substance))
                            .frame(width: 8, height: 8)
                        Text(substance)
                            .font(.body)
                    }
                }
            }
        }
    }

    private func getSubstanceColor(_ substanceName: String) -> Color {
        if let companion = substanceCompanions.first(where: { $0.substanceName == substanceName }),
           let colorString = companion.colorAsText,
           let substanceColor = SubstanceColor(rawValue: colorString) {
            return substanceColor.swiftUIColor
        }
        return .blue
    }
}

#Preview {
    SubstanceSelectionView()
}
