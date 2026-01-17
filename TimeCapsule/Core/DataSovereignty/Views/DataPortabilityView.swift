import SwiftUI

/// Main container view for data portability and privacy features
struct DataPortabilityView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case export = "Export"
        case import_ = "Import"
        case privacy = "Privacy"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "chart.pie"
            case .export: return "square.and.arrow.up"
            case .import_: return "square.and.arrow.down"
            case .privacy: return "hand.raised"
            }
        }
    }

    let vault: DataVaultManager
    let auditLogger: AuditLogger
    let exportCoordinator: ExportCoordinator
    let importCoordinator: ImportCoordinator

    @State private var selectedTab: Tab = .overview

    var body: some View {
        NavigationSplitView {
            List(Tab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("Data & Privacy")
            .listStyle(.sidebar)
        } detail: {
            detailView
                .frame(minWidth: 400)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .overview:
            DataOverviewView(vault: vault, auditLogger: auditLogger)
        case .export:
            ExportView(coordinator: exportCoordinator)
        case .import_:
            ImportView(coordinator: importCoordinator)
        case .privacy:
            PrivacyControlsView(vault: vault, auditLogger: auditLogger)
        }
    }
}

// MARK: - Convenience initializer

extension DataPortabilityView {
    init(vault: DataVaultManager, auditLogger: AuditLogger) {
        self.vault = vault
        self.auditLogger = auditLogger
        self.exportCoordinator = ExportCoordinator(vault: vault, auditLogger: auditLogger)
        self.importCoordinator = ImportCoordinator(vault: vault, auditLogger: auditLogger)
    }
}
