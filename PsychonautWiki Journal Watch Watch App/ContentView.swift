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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch today's ingestions only
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingestion.time, ascending: false)],
        predicate: NSPredicate(format: "time >= %@", Calendar.current.startOfDay(for: Date()) as NSDate),
        animation: .default)
    private var todaysIngestions: FetchedResults<Ingestion>

    @State private var showingAddIngestionSheet = false

    var body: some View {
        NavigationView {
            List {
                if todaysIngestions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "pill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No ingestions today")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("Tap + to add one")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(todaysIngestions) { ingestion in
                        IngestionRowView(ingestion: ingestion)
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddIngestionSheet.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddIngestionSheet) {
                AddIngestionView()
                    .environment(\.managedObjectContext, self.viewContext)
            }
        }
    }
}

struct IngestionRowView: View {
    let ingestion: Ingestion
    
    private var substanceColor: Color {
        if let colorString = ingestion.color,
           let substanceColor = SubstanceColor(rawValue: colorString) {
            return substanceColor.swiftUIColor
        }
        return .blue
    }
    
    private var timeAgo: String {
        guard let time = ingestion.time else { return "" }
        let now = Date()
        let timeInterval = now.timeIntervalSince(time)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 { // Less than 24 hours
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: time)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Rectangle()
                .fill(substanceColor)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingestion.substanceName ?? "Unknown")
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let dose = ingestion.doseUnwrapped {
                        Text("\(dose.asRoundedReadableString) \(ingestion.units ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let route = ingestion.administrationRoute {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(route.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}