import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: MenuTab = .suggestion
    @State private var aiService: AIServiceProtocol

    init(modelContext: ModelContext) {
        let dataService = DataService(modelContext: modelContext)
        let settings = dataService.getSettings()
        _aiService = State(initialValue: AIServiceFactory.create(for: settings.aiProvider, settings: settings))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Content
            Group {
                switch selectedTab {
                case .sendOff:
                    SendOffView(modelContext: modelContext)
                case .suggestion:
                    TaskSuggestionView(modelContext: modelContext, aiService: aiService)
                case .progress:
                    DailyProgressView(modelContext: modelContext)
                case .settings:
                    SettingsView(modelContext: modelContext)
                }
            }
            .frame(height: Constants.menuBarHeight - 60)

            Divider()

            // Tab Bar
            HStack(spacing: 0) {
                ForEach(MenuTab.allCases) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation {
                            selectedTab = tab
                        }
                    }
                }
            }
            .frame(height: 60)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: Constants.menuBarWidth, height: Constants.menuBarHeight)
    }
}
