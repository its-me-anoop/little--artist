//
//  ShareManagementView.swift
//  Little Artist
//
//  Sharing management view — displays participants fetched from Firestore,
//  allows the owner to send invite links, stop sharing, and participants to leave.
//

import SwiftUI
import SwiftData

/// A sharing management view that shows participants from Firestore.
///
/// A branded sharing experience powered by ``FirestoreRepository``.
struct ShareManagementView: View {
    let child: Child
    let shareId: String
    /// When true, the view was just created — show the share link immediately.
    var isNewShare: Bool = false

    var onStoppedSharing: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var participants: [(userId: String, role: String, acceptedAt: Date?)] = []
    @State private var isLoadingParticipants = true
    @State private var sharePayload: SharePayload?
    @State private var isStoppingShare = false
    @State private var isLeavingShare = false
    @State private var stopError: String?

    private var isCurrentUserOwner: Bool {
        !child.isShared
    }

    /// The share code that the recipient enters in their app to join.
    private var shareCode: String { shareId }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Brand.sectionSpacing) {
                    // Child avatar header
                    childHeader
                        .padding(.top, 16)

                    // People section
                    peopleSection

                    // Share options
                    shareOptionsSection

                    // Owner: stop sharing, Participant: leave
                    if isCurrentUserOwner {
                        stopSharingButton
                    } else {
                        leaveProfileButton
                    }
                }
                .padding(.horizontal, Brand.screenPadding)
                .padding(.bottom, 32)
            }
            .background(BrandAppBackground())
            .navigationTitle("Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                await loadParticipants()
                // If this is a brand-new share, show the share sheet immediately
                if isNewShare {
                    presentShareLink()
                }
            }
            .sheet(item: $sharePayload) { payload in
                ActivityView(activityItems: payload.items)
            }
            .alert("Error", isPresented: Binding(
                get: { stopError != nil },
                set: { if !$0 { stopError = nil } }
            )) {
                Button("OK") { stopError = nil }
            } message: {
                Text(stopError ?? "")
            }
        }
    }

    // MARK: - Child Header

    private var childHeader: some View {
        VStack(spacing: 12) {
            // Circular child avatar
            Group {
                if let data = child.avatarImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(hex: child.avatarColor))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Text(String(child.name.prefix(1)).uppercased())
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                }
            }
            .brandCardShadow()

            Text(child.name)
                .font(Brand.title2Font)
                .foregroundStyle(Brand.charcoal)
        }
    }

    // MARK: - People Section

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("People")
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)
                .textCase(.uppercase)
                .padding(.leading, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                // Owner row
                ownerRow
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                if isLoadingParticipants {
                    Divider().padding(.leading, 56)
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Loading participants...")
                            .font(Brand.captionFont)
                            .foregroundStyle(Brand.warmGray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                // Other participants
                ForEach(participants, id: \.userId) { participant in
                    Divider().padding(.leading, 56)
                    participantRow(participant)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                // Only owners can invite more people
                if isCurrentUserOwner {
                    Divider().padding(.leading, 56)

                    Button {
                        presentShareLink()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Brand.primary)
                            Text("Share With More People")
                                .font(Brand.bodyFont)
                                .foregroundStyle(Brand.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
            }
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
            .brandCardShadow()
        }
    }

    private var ownerRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(Brand.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentUserOwner ? "You" : "Owner")
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                Text("Owner")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }

            Spacer()
        }
    }

    private func participantRow(_ participant: (userId: String, role: String, acceptedAt: Date?)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 28))
                .foregroundStyle(Brand.sky)

            VStack(alignment: .leading, spacing: 2) {
                Text(participant.userId.prefix(8) + "...")
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                Text(participantRoleLabel(participant.role))
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }

            Spacer()

            if participant.acceptedAt == nil {
                Text("Pending")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Brand.primaryTint)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Share Options

    private var shareOptionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Share Options")
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)
                .textCase(.uppercase)
                .padding(.leading, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Brand.sage)
                    Text("People you invite can make changes and add others.")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.charcoal)
                }
                .padding(16)
            }
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
            .brandCardShadow()
        }
    }

    // MARK: - Stop Sharing

    private var stopSharingButton: some View {
        Button(role: .destructive) {
            Task { await stopSharing() }
        } label: {
            HStack {
                if isStoppingShare {
                    ProgressView()
                        .tint(Brand.dustyRose)
                } else {
                    Text("Stop Sharing")
                        .font(Brand.headlineFont)
                }
            }
            .foregroundStyle(Brand.dustyRose)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
            .brandCardShadow()
        }
        .disabled(isStoppingShare)
    }

    // MARK: - Leave Profile (Participant)

    private var leaveProfileButton: some View {
        Button(role: .destructive) {
            Task { await leaveProfile() }
        } label: {
            HStack {
                if isLeavingShare {
                    ProgressView()
                        .tint(Brand.dustyRose)
                } else {
                    Image(systemName: "person.badge.minus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Leave Profile")
                        .font(Brand.headlineFont)
                }
            }
            .foregroundStyle(Brand.dustyRose)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
            .brandCardShadow()
        }
        .disabled(isLeavingShare)
    }

    // MARK: - Helpers

    private func participantRoleLabel(_ role: String) -> String {
        switch role {
        case "editor": return "Can make changes"
        case "viewer": return "View only"
        default: return "Participant"
        }
    }

    // MARK: - Actions

    private func loadParticipants() async {
        isLoadingParticipants = true
        do {
            participants = try await FirestoreRepository.shared.fetchParticipants(shareId: shareId)
        } catch {
            // Silently fail — empty participants list is fine
        }
        isLoadingParticipants = false
    }

    private func presentShareLink() {
        let text = "Join me on Artling to see \(child.name)'s artwork! Open the app, go to Settings → Join Shared Profile, and enter this code:\n\n\(shareCode)"
        sharePayload = SharePayload(items: [text])
    }

    private func stopSharing() async {
        isStoppingShare = true
        do {
            try await FirestoreRepository.shared.stopSharing(shareId: shareId)
            dismiss()
            onStoppedSharing?()
        } catch {
            stopError = error.localizedDescription
            isStoppingShare = false
        }
    }

    private func leaveProfile() async {
        isLeavingShare = true
        do {
            try await FirestoreRepository.shared.leaveShare(shareId: shareId)
            // Remove local mirror of shared child
            modelContext.delete(child)
            dismiss()
            onStoppedSharing?()
        } catch {
            stopError = error.localizedDescription
            isLeavingShare = false
        }
    }
}
