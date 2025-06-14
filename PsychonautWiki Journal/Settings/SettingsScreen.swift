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

import AlertToast
import SwiftUI
import AppIntents
import CloudKitSyncMonitor

struct SettingsScreen: View {
    @AppStorage(PersistenceController.isEyeOpenKey2) var isEyeOpen: Bool = false
    @AppStorage(PersistenceController.isHidingDosageDotsKey) var isHidingDosageDots: Bool = false
    @AppStorage(PersistenceController.isHidingToleranceChartInExperienceKey) var isHidingToleranceChartInExperience: Bool = false
    @AppStorage(PersistenceController.isHidingSubstanceInfoInExperienceKey) var isHidingSubstanceInfoInExperience: Bool = false
    @AppStorage(Authenticator.hasToUnlockKey) var hasToUnlockApp: Bool = false
    @AppStorage(Authenticator.lockTimeOptionKey) var lockTimeOptionString: String = LockTimeOption.after5Minutes.rawValue
    @AppStorage(PersistenceController.areRedosesDrawnIndividuallyKey) var areRedosesDrawnIndividually: Bool = false
    @AppStorage(PersistenceController.shouldAutomaticallyStartLiveActivityKey) var shouldAutomaticallyStartLiveActivity: Bool = true
    @AppStorage(PersistenceController.independentSubstanceHeightKey) var areSubstanceHeightsIndependent: Bool = false
    @AppStorage(PersistenceController.iCloudSyncEnabledKey) var iCloudSyncEnabled: Bool = false
    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject var authenticator: Authenticator

    private var lockTimeOption: LockTimeOption {
        LockTimeOption(rawValue: lockTimeOptionString) ?? LockTimeOption.after5Minutes
    }

    private func setLockTimeOption(option: LockTimeOption) {
        lockTimeOptionString = option.rawValue
    }

    var body: some View {
        let timeOptionBinding = Binding {
            lockTimeOption
        } set: { newValue in
            setLockTimeOption(option: newValue)
        }

        SettingsContent(
            isEyeOpen: $isEyeOpen,
            isHidingDosageDots: $isHidingDosageDots,
            isHidingToleranceChartInExperience: $isHidingToleranceChartInExperience,
            isHidingSubstanceInfoInExperience: $isHidingSubstanceInfoInExperience,
            areRedosesDrawnIndividually: $areRedosesDrawnIndividually,
            areSubstanceHeightsIndependent: $areSubstanceHeightsIndependent,
            shouldAutomaticallyStartLiveActivity: $shouldAutomaticallyStartLiveActivity,
            isFaceIDAvailable: authenticator.isFaceIDEnabled,
            hasToUnlockApp: $hasToUnlockApp,
            isExporting: $viewModel.isExporting,
            journalFile: viewModel.journalFile,
            exportData: {
                viewModel.exportData()
            },
            importData: { data in
                viewModel.importData(data: data)
            },
            deleteEverything: {
                viewModel.deleteEverything()
            },
            viewModel: viewModel,
            isShowingToast: $viewModel.isShowingToast,
            isSuccessToast: $viewModel.isShowingSuccessToast,
            toastMessage: $viewModel.toastMessage,
            lockTimeOption: timeOptionBinding,
            iCloudSyncEnabled: $iCloudSyncEnabled
        )
    }
}

struct SettingsContent: View {
    @Binding var isEyeOpen: Bool
    @Binding var isHidingDosageDots: Bool
    @Binding var isHidingToleranceChartInExperience: Bool
    @Binding var isHidingSubstanceInfoInExperience: Bool
    @Binding var areRedosesDrawnIndividually: Bool
    @Binding var areSubstanceHeightsIndependent: Bool
    @Binding var shouldAutomaticallyStartLiveActivity: Bool
    let isFaceIDAvailable: Bool
    @Binding var hasToUnlockApp: Bool
    @State var isImporting = false
    @Binding var isExporting: Bool
    let journalFile: JournalFile
    @EnvironmentObject private var toastViewModel: ToastViewModel
    let exportData: () -> Void
    let importData: (Data) -> Void
    let deleteEverything: () -> Void
    let viewModel: SettingsScreen.ViewModel
    @Binding var isShowingToast: Bool
    @Binding var isSuccessToast: Bool
    @Binding var toastMessage: String
    @Binding var lockTimeOption: LockTimeOption
    @Binding var iCloudSyncEnabled: Bool

    #if os(iOS)
        @StateObject private var syncMonitor = SyncMonitor.default
    #endif

    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingImportAlert = false
    @State private var isMigratingCloudData = false
    @State private var isRevertingToggle = false
    @State private var isShowingMigrationSuccessAlert = false
    @State private var isShowingMigrationConfirmationAlert = false

    #if os(iOS)
        var syncStatusText: String {
            // Simple description to avoid enum case issues
            return syncMonitor.syncStateSummary.description
        }

        func stateText(for state: SyncMonitor.SyncState) -> String {
            switch state {
            case .notStarted:
                return "Not started"
            case .inProgress(started: let date):
                return "In progress since \(dateFormatter.string(from: date))"
            case let .succeeded(started: _, ended: endDate):
                return "Succeeded at \(dateFormatter.string(from: endDate))"
            case let .failed(started: _, ended: endDate, error: _):
                return "Failed at \(dateFormatter.string(from: endDate))"
            }
        }

        var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
    #endif

    var body: some View {
        ZStack {
            List {
                Section("Privacy") {
                    if isFaceIDAvailable {
                        Toggle("Require App Unlock", isOn: $hasToUnlockApp.animation()).tint(
                            Color.accentColor)
                    } else {
                        Text("Enable Face ID for Journal in settings to lock the app.")
                    }
                    if hasToUnlockApp {
                        Picker("Time option", selection: $lockTimeOption) {
                            ForEach(LockTimeOption.allCases) { option in
                                Text(option.text)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
                if isEyeOpen {
                    Section("UI") {
                        NavigationLink(value: GlobalNavigationDestination.editColors) {
                            Label("Edit Substance Colors", systemImage: "paintpalette")
                        }
                        NavigationLink(value: GlobalNavigationDestination.customUnits) {
                            Label("Custom Units", systemImage: "pills")
                        }
                        Group {
                            Toggle("Hide dosage dots", isOn: $isHidingDosageDots)
                            Toggle(
                                "Hide tolerance chart", isOn: $isHidingToleranceChartInExperience)
                            Toggle("Hide substance info", isOn: $isHidingSubstanceInfoInExperience)
                            Toggle("Draw redoses individually", isOn: $areRedosesDrawnIndividually)
                            Toggle(
                                "Independent substance heights",
                                isOn: $areSubstanceHeightsIndependent)
                            if #available(iOS 16.2, *) {
                                if ActivityManager.shared.authorizationInfo.areActivitiesEnabled {
                                    Toggle(
                                        "Automatic live activities",
                                        isOn: $shouldAutomaticallyStartLiveActivity)
                                }
                            }
                        }.tint(.accentColor)
                    }
                }
                Section(
                    header: Text("Journal Data"),
                    footer: Text(
                        "You can export all your data into a file on your phone and import it again at a later time. This way you can migrate your data to Android or delete the app without losing your data."
                    )
                ) {
                    Button {
                        exportData()
                    } label: {
                        Label("Export Data", systemImage: "arrow.up.doc")
                    }
                    Button {
                        isShowingImportAlert.toggle()
                    } label: {
                        Label("Import Data", systemImage: "arrow.down.doc")
                    }
                    .confirmationDialog(
                        "Are you sure?",
                        isPresented: $isShowingImportAlert,
                        titleVisibility: .visible,
                        actions: {
                            Button("Import", role: .destructive) {
                                isImporting.toggle()
                            }
                            Button("Cancel", role: .cancel) {}
                        },
                        message: {
                            Text(
                                "Importing will delete all the data currently in the app and replace it with the imported data."
                            )
                        }
                    )
                    Button {
                        isShowingDeleteConfirmation.toggle()
                    } label: {
                        Label("Delete Everything", systemImage: "trash").foregroundColor(.red)
                    }
                    .confirmationDialog(
                        "Delete Everything?",
                        isPresented: $isShowingDeleteConfirmation,
                        titleVisibility: .visible,
                        actions: {
                            Button("Delete", role: .destructive) {
                                deleteEverything()
                            }
                            Button("Cancel", role: .cancel) {}
                        },
                        message: {
                            Text(
                                "This will delete all your experiences, ingestions, custom substances and sprays."
                            )
                        }
                    )
                }
                #if os(iOS)
                    Section(
                        header: Text("iCloud Synchronization"),
                        footer: Text(
                            "Enabling iCloud synchronization is required to sync data between iOS and Apple Watch."
                        )
                    ) {
                        Toggle("Enable iCloud Syncronization", isOn: $iCloudSyncEnabled)
                            .tint(.accentColor)
                            .disabled(isMigratingCloudData)
                            .onChange(of: iCloudSyncEnabled) { _ in
                                if isRevertingToggle {
                                    isRevertingToggle = false
                                    return
                                }
                                isShowingMigrationConfirmationAlert = true
                            }

                        // Sync status summary with icon
                        HStack {
                            Image(systemName: syncMonitor.syncStateSummary.symbolName)
                                .foregroundColor(syncMonitor.syncStateSummary.symbolColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sync Status")
                                    .font(.headline)
                                Text(syncStatusText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)

                        // Detailed sync states
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detailed Status:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("Setup:")
                                    .font(.caption)
                                    .frame(width: 60, alignment: .leading)
                                Text(stateText(for: viewModel.setupState))
                                    .font(.caption.monospaced())
                                Spacer()
                            }

                            HStack {
                                Text("Import:")
                                    .font(.caption)
                                    .frame(width: 60, alignment: .leading)
                                Text(stateText(for: viewModel.importState))
                                    .font(.caption.monospaced())
                                Spacer()
                            }

                            HStack {
                                Text("Export:")
                                    .font(.caption)
                                    .frame(width: 60, alignment: .leading)
                                Text(stateText(for: viewModel.exportState))
                                    .font(.caption.monospaced())
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)

                        // Error information
                        if viewModel.hasSyncError {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sync Errors:")
                                    .font(.caption)
                                    .foregroundColor(.red)

                                if let setupError = syncMonitor.setupError {
                                    Text("Setup: \(setupError.localizedDescription)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }

                                if let importError = syncMonitor.importError {
                                    Text("Import: \(importError.localizedDescription)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }

                                if let exportError = syncMonitor.exportError {
                                    Text("Export: \(exportError.localizedDescription)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                #endif
                Section("Communication") {
                    if isEyeOpen {
                        NavigationLink(value: GlobalNavigationDestination.shareApp) {
                            Label("Share App", systemImage: "person.2")
                        }
                    }
                    Link(
                        destination: URL(
                            string: isEyeOpen
                                ? "https://t.me/+ss8uZhBF6g00MTY8" : "https://t.me/isaakhanimann")!
                    ) {
                        Label("Question, Bug Report", systemImage: "exclamationmark.bubble")
                    }
                    if isEyeOpen {
                        NavigationLink(value: GlobalNavigationDestination.faq) {
                            Label("Frequently Asked Questions", systemImage: "questionmark.square")
                        }
                        Link(
                            destination: URL(
                                string:
                                    "https://github.com/isaakhanimann/psychonautwiki-journal-ios")!
                        ) {
                            Label("Source Code", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                }
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(getCurrentAppVersion())
                            .foregroundColor(.secondary)
                    }
                }
                eye
            }
            .navigationTitle("Settings")
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json]
            ) { result in
                do {
                    let selectedFile: URL = try result.get()
                    if selectedFile.startAccessingSecurityScopedResource() {
                        let data = try Data(contentsOf: selectedFile)
                        importData(data)
                    } else {
                        toastViewModel.showErrorToast(message: "Permission Denied")
                    }
                    selectedFile.stopAccessingSecurityScopedResource()
                } catch {
                    toastViewModel.showErrorToast(message: "Import Failed")
                    print("Error getting data: \(error.localizedDescription)")
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: journalFile,
                contentType: .json,
                defaultFilename: "Journal \(Date().asDateString)"
            ) { result in
                if case .success = result {
                    toastViewModel.showSuccessToast(message: "Export Successful")
                } else {
                    toastViewModel.showErrorToast(message: "Export Failed")
                }
            }
            .toast(isPresenting: $isShowingToast) {
                AlertToast(
                    displayMode: .alert,
                    type: isSuccessToast ? .complete(.green) : .error(.red),
                    title: toastMessage
                )
            }
            .disabled(isMigratingCloudData)

            if isMigratingCloudData {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Migrating data...")
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemBackground))
                    )
                    .shadow(radius: 10)
            }
        }
        .alert("Are You Sure?", isPresented: $isShowingMigrationConfirmationAlert) {
            Button("Continue", role: .destructive) {
                isMigratingCloudData = true
                PersistenceController.shared.toggleiCloudSync(enabled: iCloudSyncEnabled) { error in
                    isMigratingCloudData = false
                    if let error = error {
                        toastViewModel.showErrorToast(
                            message: "Migration failed: \(error.localizedDescription)")
                        // Revert toggle on failure
                        isRevertingToggle = true
                        iCloudSyncEnabled.toggle()
                    } else {
                        isShowingMigrationSuccessAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                isRevertingToggle = true
                iCloudSyncEnabled.toggle()
            }
        } message: {
            Text(
                "It is recommended to export your data first as a backup in case something goes wrong during the migration."
            )
        }
        .alert("Migration Successful", isPresented: $isShowingMigrationSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please restart the app for the changes to take full effect.")
        }
    }

    private var eye: some View {
        HStack {
            Spacer()
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80, alignment: .center)
                .onTapGesture(count: 3, perform: toggleEye)
            Spacer()
        }
        .listRowBackground(Color.clear)
    }

    private var imageName: String {
        isEyeOpen ? "Eye Open" : "Eye Closed"
    }

    private func toggleEye() {
        isEyeOpen.toggle()
        NotificationCenter.default.post(name: Notification.eyeName, object: nil)
        playHapticFeedback()
    }
}

#Preview {
    SettingsContent(
        isEyeOpen: .constant(true),
        isHidingDosageDots: .constant(false),
        isHidingToleranceChartInExperience: .constant(false),
        isHidingSubstanceInfoInExperience: .constant(false),
        areRedosesDrawnIndividually: .constant(false),
        areSubstanceHeightsIndependent: .constant(false),
        shouldAutomaticallyStartLiveActivity: .constant(false),
        isFaceIDAvailable: true,
        hasToUnlockApp: .constant(false),
        isImporting: false,
        isExporting: .constant(false),
        journalFile: JournalFile(experiences: [], customSubstances: [], customUnits: []),
        exportData: {},
        importData: { _ in },
        deleteEverything: {},
        viewModel: SettingsScreen.ViewModel(),
        isShowingToast: .constant(false),
        isSuccessToast: .constant(false),
        toastMessage: .constant(""),
        lockTimeOption: .constant(.after5Minutes),
        iCloudSyncEnabled: .constant(false)
    )
    .accentColor(Color.blue)
}
