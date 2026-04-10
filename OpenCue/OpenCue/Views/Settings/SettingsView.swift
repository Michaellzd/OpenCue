import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .visual

    enum SettingsTab: String, CaseIterable {
        case visual = "Visual"
        case general = "General"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title2.bold())

                Spacer()

                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Settings")
            }
            .padding(20)

            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            Divider()
                .padding(.top, 16)

            ScrollView {
                Group {
                    switch selectedTab {
                    case .visual:
                        VisualTab()
                    case .general:
                        GeneralTab()
                    }
                }
                .padding(20)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 450, idealWidth: 450, maxWidth: 450, minHeight: 500, idealHeight: 500, maxHeight: 500)
    }
}
