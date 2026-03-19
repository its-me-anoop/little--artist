//
//  PDFExportConfigView.swift
//  Little Artist
//
//  Configuration sheet for generating a PDF portfolio keepsake
//  for a selected child's artwork collection.
//

import SwiftUI
import SwiftData

/// A sheet that lets the user configure and generate a PDF portfolio for a child.
///
/// Presented from Settings' "PDF Portfolio Export" row. The user picks an artist,
/// time range, and layout options before generating the PDF.
struct PDFExportConfigView: View {

    // MARK: - Environment & Queries

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Child.createdAt) private var children: [Child]

    // MARK: - State

    @State private var selectedChild: Child?
    @State private var timeRange: TimeRange = .lastYear
    @State private var includeAIStories = true
    @State private var fullPageLayout = false
    @State private var isGenerating = false
    @State private var showPreview = false
    @State private var generatedPDFData: Data?

    // MARK: - Types

    /// The date window to include in the exported portfolio.
    enum TimeRange: String, CaseIterable {
        case lastYear = "Last 12 Months"
        case allTime = "All Time"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                BrandAppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Brand.sectionSpacing) {
                        introSection
                        artistCard
                        timeRangeCard
                        layoutOptionsCard
                        previewThumbnail
                    }
                    .padding(.horizontal, Brand.screenPadding)
                    .padding(.top, Brand.screenPadding)
                    .padding(.bottom, 100)
                }

                .safeAreaInset(edge: .bottom) {
                    generateButton
                }
            }
            .navigationTitle("Studio Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Brand.warmGray)
                            .font(.title3)
                    }
                }
            }
            .navigationDestination(isPresented: $showPreview) {
                if let pdfData = generatedPDFData, let child = selectedChild {
                    PDFPreviewView(pdfData: pdfData, child: child)
                }
            }
        }
        .onAppear {
            if selectedChild == nil {
                selectedChild = children.first
            }
        }
    }

    // MARK: - Intro Section

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create your keepsake")
                .font(Brand.title1Font)
                .foregroundStyle(Brand.charcoal)

            Text("Choose an artist and time window to generate a beautiful scrapbook-style PDF you can print or share.")
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.warmGray)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Artist Card

    private var artistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("SELECT ARTIST")

            if children.isEmpty {
                Text("No artists yet — add a child profile first.")
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)
                    .padding(Brand.fieldPadding)
            } else {
                ArtistSelectorView(
                    children: children,
                    selectedChild: $selectedChild
                )
                .padding(.bottom, 4)
            }
        }
        .padding(.top, 16)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
        .rotationEffect(.degrees(-0.6))
    }

    // MARK: - Time Range Card

    private var timeRangeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("TIME RANGE")
                .padding(.horizontal, Brand.screenPadding)

            VStack(spacing: 0) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    timeRangeRow(range)

                    if range != TimeRange.allCases.last {
                        Divider()
                            .padding(.horizontal, Brand.screenPadding)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.top, 16)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
        .rotationEffect(.degrees(0.5))
    }

    private func timeRangeRow(_ range: TimeRange) -> some View {
        let isSelected = timeRange == range

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                timeRange = range
            }
        } label: {
            HStack(spacing: 14) {
                // Radio indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Brand.primary : Brand.softTan,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Brand.primary)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(range.rawValue)
                    .font(Brand.bodyFont)
                    .foregroundStyle(isSelected ? Brand.charcoal : Brand.warmGray)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Brand.primary)
                }
            }
            .padding(.horizontal, Brand.screenPadding)
            .padding(.vertical, 14)
            .background(
                isSelected ? Brand.primaryTint : Color.clear
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Layout Options Card

    private var layoutOptionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("LAYOUT & FEATURES")
                .padding(.horizontal, Brand.screenPadding)
                .padding(.top, 16)

            toggleRow(
                icon: "sparkles",
                iconColor: Brand.lavender,
                title: "AI Stories",
                subtitle: "Include AI-generated captions",
                binding: $includeAIStories
            )

            Divider()
                .padding(.horizontal, Brand.screenPadding)

            toggleRow(
                icon: "doc.richtext",
                iconColor: Brand.sky,
                title: "Full Page Layout",
                subtitle: "One artwork per page",
                binding: $fullPageLayout
            )

            Spacer().frame(height: 8)
        }
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
    }

    private func toggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        binding: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Brand.bodyFont.weight(.medium))
                    .foregroundStyle(Brand.charcoal)

                Text(subtitle)
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }

            Spacer()

            Toggle("", isOn: binding)
                .tint(Brand.primary)
                .labelsHidden()
        }
        .padding(.horizontal, Brand.screenPadding)
        .padding(.vertical, 14)
    }

    // MARK: - Preview Thumbnail

    private var previewThumbnail: some View {
        VStack(spacing: 12) {
            sectionLabel("PREVIEW")

            ZStack {
                // Background stacked card
                RoundedRectangle(cornerRadius: Brand.radiusCard)
                    .fill(Brand.softTan.opacity(0.6))
                    .frame(height: 120)
                    .rotationEffect(.degrees(2))

                // Foreground preview card
                VStack(spacing: 6) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Brand.primary.opacity(0.7))

                    Text(selectedChild?.name ?? "Your Child")
                        .font(Brand.headlineFont)
                        .foregroundStyle(Brand.charcoal)

                    Text(previewYearLabel)
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Brand.surface)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
                .brandCardShadow()
                .rotationEffect(.degrees(-1))
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewYearLabel: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date.now)
        switch timeRange {
        case .lastYear:
            return "\(year - 1)–\(year) Collection"
        case .allTime:
            return "Complete Collection"
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.4)

            Button {
                generatePDF()
            } label: {
                HStack(spacing: 10) {
                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                    } else {
                        Image(systemName: "doc.fill")
                    }

                    Text(isGenerating ? "Generating…" : "Generate PDF")
                        .font(Brand.headlineFont)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(canGenerate ? Brand.primary : Brand.disabled)
                )
                .brandFABShadow()
            }
            .disabled(!canGenerate || isGenerating)
            .padding(.horizontal, Brand.screenPadding)
            .padding(.vertical, 14)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private var canGenerate: Bool {
        selectedChild != nil
    }

    private func filteredArtworks(for child: Child) -> [Artwork] {
        let artworks = child.artworks ?? []
        switch timeRange {
        case .allTime:
            return artworks
        case .lastYear:
            let cutoff = Calendar.current.date(byAdding: .day, value: -365, to: Date.now) ?? Date.now
            return artworks.filter { $0.createdAt >= cutoff }
        }
    }

    private func generatePDF() {
        Task {
            isGenerating = true
            guard let child = selectedChild else {
                isGenerating = false
                return
            }
            let artworks = filteredArtworks(for: child)
            let childRef = child
            generatedPDFData = await Task.detached(priority: .userInitiated) {
                PDFExportService.generatePortfolio(child: childRef, artworks: artworks)
            }.value
            isGenerating = false
            showPreview = true
        }
    }

    // MARK: - Shared Sub-views

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Brand.caption2Font.bold())
            .tracking(2)
            .foregroundStyle(Brand.warmGray)
    }
}

// MARK: - Preview

#Preview {
    PDFExportConfigView()
        .modelContainer(PreviewSampleData.container)
}
