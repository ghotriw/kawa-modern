import SwiftUI

struct PreferencesView: View {
    @ObservedObject var inputSourceManager = InputSourceManager.shared
    @ObservedObject var shortcutManager = ShortcutManager.shared
    @ObservedObject var launchAtLogin = LaunchAtLoginManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Kawa Modern")
                        .font(.headline)
                    Text("Fast input source switcher")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Input Sources List
            VStack(alignment: .leading, spacing: 10) {
                Text("Input Sources & Shortcuts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                VStack(spacing: 6) {
                    ForEach(inputSourceManager.sources) { source in
                        HStack(spacing: 12) {
                            if let icon = source.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "globe")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, height: 20)
                            }

                            Text(source.name)
                                .font(.system(size: 13, weight: .medium))

                            Spacer()

                            ShortcutRecorderView(sourceId: source.id)
                                .frame(width: 140, height: 28)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 20)
            }

            Divider()
                .padding(.top, 12)

            // Settings options
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show notification when switching", isOn: $shortcutManager.showNotifications)
                    .toggleStyle(.checkbox)

                Toggle("Launch Kawa Modern at login", isOn: $launchAtLogin.isEnabled)
                    .toggleStyle(.checkbox)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            // Footer
            HStack {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.3"
                Text("Version \(version)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Quit Kawa Modern") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(width: 420)
        .onAppear {
            inputSourceManager.reload()
            launchAtLogin.refresh()
        }
    }
}
