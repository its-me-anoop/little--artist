//
//  ShareManagementView.swift
//  Little Artist
//
//  Custom sharing management view that replaces UICloudSharingController
//  for the "Manage Sharing" screen — displays the owner's actual iCloud
//  name instead of the generic "(Owner)" label.
//

import CloudKit
import SwiftUI

/// A custom sharing management view that shows the owner's iCloud identity.
///
/// `UICloudSharingController` always displays "(Owner)" for the share owner.
/// This view fetches the actual iCloud user name and presents a branded
/// sharing management experience.
struct ShareManagementView: View {
    let child: Child
    let share: CKShare
    let ckContainer: CKContainer

    var onStoppedSharing: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var ownerName: String?
    @State private var sharePayload: SharePayload?
    @State private var isStoppingShare = false
    @State private var isLeavingShare = false
    @State private var stopError: String?

    private var isCurrentUserOwner: Bool {
        share.currentUserParticipant?.role == .owner
    }

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
            .background(Brand.cream)
            .navigationTitle("Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task { await fetchOwnerName() }
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

                // Other participants
                ForEach(otherParticipants, id: \.self) { participant in
                    Divider().padding(.leading, 56)
                    participantRow(participant)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                // Only owners can invite more people
                if isCurrentUserOwner {
                    Divider().padding(.leading, 56)

                    // Send invite link via standard share sheet with child avatar preview
                    Button {
                        if let url = share.url {
                            let itemSource = ShareInviteItemSource(
                                url: url,
                                childName: child.name,
                                avatarImageData: child.avatarImageData,
                                avatarColor: child.avatarColor
                            )
                            sharePayload = SharePayload(items: [itemSource])
                        }
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
                Text(ownerName ?? "You")
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                Text("Owner")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }

            Spacer()
        }
    }

    private func participantRow(_ participant: CKShare.Participant) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 28))
                .foregroundStyle(Brand.sky)

            VStack(alignment: .leading, spacing: 2) {
                Text(participantName(participant))
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                Text(participantStatus(participant))
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }

            Spacer()

            if participant.acceptanceStatus == .pending {
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

    private var otherParticipants: [CKShare.Participant] {
        share.participants.filter { $0.role != .owner }
    }

    private func participantName(_ participant: CKShare.Participant) -> String {
        if let components = participant.userIdentity.nameComponents {
            return PersonNameComponentsFormatter.localizedString(from: components, style: .default)
        }
        if let email = participant.userIdentity.lookupInfo?.emailAddress {
            return email
        }
        if let phone = participant.userIdentity.lookupInfo?.phoneNumber {
            return phone
        }
        return "Unknown"
    }

    private func participantStatus(_ participant: CKShare.Participant) -> String {
        switch participant.permission {
        case .readWrite: return "Can make changes"
        case .readOnly: return "View only"
        default: return "No access"
        }
    }

    // MARK: - Actions

    private func fetchOwnerName() async {
        // 1. Try share participant identity
        if let components = share.currentUserParticipant?.userIdentity.nameComponents
            ?? share.owner.userIdentity.nameComponents {
            let name = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
            if !name.isEmpty { ownerName = name; return }
        }

        // 2. Request discoverability and fetch identity from CloudKit
        do {
            // Request permission so CloudKit can resolve our identity
            let status = try await ckContainer.requestApplicationPermission(.userDiscoverability)
            if status == .granted {
                let recordID = try await ckContainer.userRecordID()
                if let identity = try await ckContainer.userIdentity(forUserRecordID: recordID),
                   let components = identity.nameComponents {
                    let name = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
                    if !name.isEmpty { ownerName = name; return }
                }
            }
        } catch {
            // Discoverability not available — continue to fallbacks
        }

        // 3. Try owner's email or phone from lookup info
        if let email = share.owner.userIdentity.lookupInfo?.emailAddress {
            ownerName = email
            return
        }
        if let phone = share.owner.userIdentity.lookupInfo?.phoneNumber {
            ownerName = phone
            return
        }

        // 4. Falls back to "You"
    }

    private func stopSharing() async {
        isStoppingShare = true
        do {
            try await CloudKitSharingService.shared.stopSharing(child)
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
            try await CloudKitSharingService.shared.leaveShare(child, modelContext: modelContext)
            dismiss()
            onStoppedSharing?()
        } catch {
            stopError = error.localizedDescription
            isLeavingShare = false
        }
    }
}
