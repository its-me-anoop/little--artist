//
//  SettingsView.swift
//  Little Artist
//
//  App settings with children management, preferences,
//  data management, and about information.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var artworks: [Artwork]

    @AppStorage("aiCaptionsEnabled") private var aiCaptionsEnabled = true
    @AppStorage("defaultCameraBack") private var defaultCameraBack = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var showAddChild = false
    @State private var showDeleteChildConfirmation = false
    @State private var childToDelete: Child?

    private var storageUsed: String {
        let bytes = artworks.compactMap(\.imageData).reduce(0) { $0 + $1.count }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                // CHILDREN
                Section {
                    ForEach(children) { child in
                        NavigationLink {
                            EditChildView(child: child) {
                                // onDelete callback
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: child.avatarColor))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if let data = child.avatarImageData,
                                           let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(Circle())
                                        } else {
                                            Text(String(child.name.prefix(1)).uppercased())
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                        }
                                    }

                                Text(child.name)
                                    .font(Brand.bodyFont)

                                Spacer()

                                Text("\(child.artworks?.count ?? 0) artworks")
                                    .font(Brand.caption2Font)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            childToDelete = children[index]
                            showDeleteChildConfirmation = true
                        }
                    }

                    Button {
                        showAddChild = true
                    } label: {
                        Label("Add Child", systemImage: "plus")
                            .foregroundStyle(Brand.primary)
                    }
                } header: {
                    Text("Children")
                }

                // PREFERENCES
                Section {
                    Toggle(isOn: $aiCaptionsEnabled) {
                        Label("AI Captions", systemImage: "sparkles")
                    }
                    .tint(Brand.primary)

                    HStack {
                        Label("Default Camera", systemImage: "camera.fill")
                        Spacer()
                        Picker("", selection: $defaultCameraBack) {
                            Text("Back").tag(true)
                            Text("Front").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                } header: {
                    Text("Preferences")
                }

                // DATA
                Section {
                    HStack {
                        Label("Storage", systemImage: "externaldrive.fill")
                        Spacer()
                        Text(storageUsed)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Data")
                }

                // ABOUT
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
            .alert("Delete Child?", isPresented: $showDeleteChildConfirmation) {
                Button("Cancel", role: .cancel) {
                    childToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let child = childToDelete {
                        modelContext.delete(child)
                        childToDelete = nil
                    }
                }
            } message: {
                if let child = childToDelete {
                    Text("This will permanently delete \(child.name) and all their \(child.artworks?.count ?? 0) artworks.")
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSampleData.container)
}
