//
//  AppleIntelligenceService.swift
//  Little Artist
//
//  On-device and Private Cloud Compute artwork AI using Apple's
//  FoundationModels framework on iOS 27+. Leads the engine ladder so
//  suggestions stay private, free, and offline-capable whenever the
//  device supports Apple Intelligence.
//

// Compiled only with the iOS 27 SDK (Xcode 27 / Swift 6.4+) so the project
// still builds — minus Apple Intelligence — with stable Xcode for App Store
// submission. FoundationModels is weak-linked (see OTHER_LDFLAGS) because
// beta-SDK symbols may be absent from older iOS 26.x runtimes.
#if compiler(>=6.4)

import CoreGraphics
import Foundation
import FoundationModels
import UIKit

/// Generates artwork titles, captions, and content screening using Apple
/// Intelligence models. Callers receive `nil` when no Apple engine can
/// serve a request, and fall through to the next engine in the ladder.
@available(iOS 27.0, *)
enum AppleIntelligenceService {

    // MARK: - Guided Generation Outputs

    @Generable
    struct GeneratedArtworkSuggestion {
        @Guide(description: "A creative, playful 2-4 word storybook-style title for the artwork. Never include the child's name or any colours, and never use the words 'drawing' or 'painting'.")
        var title: String

        @Guide(description: "One warm sentence of at most 15 words celebrating what the child created, specific about the subjects depicted.")
        var caption: String

        @Guide(description: "The primary art medium visible in the piece.", .anyOf(["Craft", "Painting", "Drawing", "Watercolor", "Collage", "Sculpture", "Digital", "Mixed Media"]))
        var medium: String
    }

    @Generable
    struct ArtworkScreening {
        @Guide(description: "True when the image shows children's artwork: a drawing, painting, craft, collage, sketch, or colouring page — including photos of artwork hanging on a wall or lying on a table. False for regular photographs, screenshots, memes, or unrelated images.")
        var isArtwork: Bool

        @Guide(description: "True when the content is appropriate for a family app. False for nudity, violence, gore, drugs, weapons, or other adult content.")
        var isAppropriate: Bool

        @Guide(description: "What the image shows, in at most 12 words.")
        var subject: String
    }

    // MARK: - Instructions

    private static let suggestionInstructions = """
        You name children's artwork with creative, fun, short titles.
        Focus on the SUBJECTS and SCENES depicted (animals, people, flowers, \
        houses, landscapes), never the colours or the medium.
        Great titles sound like storybook names: "The Brave Dinosaur Parade", \
        "Grandma's Garden Party", "Rocket to the Moon".
        Captions celebrate warmly and name what is in the picture: \
        "A cheerful dinosaur marches proudly through a field of flowers."
        Also identify the primary art medium you can see in the piece.
        """

    private static let screeningInstructions = """
        You are a content classifier for a children's artwork archiving app. \
        Classify whether an image is children's artwork and whether it is \
        appropriate for a family audience.
        """

    // MARK: - Availability

    /// Builds a snapshot of Apple engine availability from the live models.
    static func currentAvailability() -> AIEngineAvailability {
        let onDevice = SystemLanguageModel.default
        let privateCloud = PrivateCloudComputeLanguageModel()

        let quotaReached: Bool
        switch privateCloud.quotaUsage.status {
        case .limitReached:
            quotaReached = true
        case .belowLimit:
            quotaReached = false
        @unknown default:
            // Optimistic: attempt the request; failures fall down the ladder.
            quotaReached = false
        }

        return AIEngineAvailability(
            onDeviceAvailable: onDevice.availability == .available,
            onDeviceSupportsVision: onDevice.capabilities.contains(.vision),
            privateCloudAvailable: privateCloud.availability == .available,
            privateCloudSupportsVision: privateCloud.capabilities.contains(.vision),
            privateCloudQuotaReached: quotaReached
        )
    }

    /// Warms up the on-device model with the real prompt prefix so the
    /// first suggestion feels instant (loads model assets and primes the
    /// KV cache). Call when the Add Artwork sheet appears and AI captions
    /// are enabled.
    static func prewarm() {
        let model = SystemLanguageModel.default
        guard model.availability == .available else { return }
        LanguageModelSession(model: model, instructions: suggestionInstructions)
            .prewarm(promptPrefix: Prompt("Create a title and caption for this artwork"))
    }

    // MARK: - Suggestions

    /// Generates (or improves) a title and caption using the best available
    /// Apple engine. Returns nil when no Apple engine could serve the
    /// request so the caller can fall through to static fallback text.
    static func generateSuggestion(
        imageData: Data,
        childName: String,
        existingTitle: String? = nil,
        existingCaption: String? = nil
    ) async -> (suggestion: AISuggestion, engine: AIEngine)? {
        guard let cgImage = preparedCGImage(from: imageData) else { return nil }

        let prompt = Prompt {
            if existingTitle != nil || existingCaption != nil {
                "Improve the title and caption for this child's artwork to be more creative and specific."
                "Current title: \(existingTitle?.isEmpty == false ? existingTitle! : "None")"
                "Current caption: \(existingCaption?.isEmpty == false ? existingCaption! : "None")"
            } else {
                "Create a title and caption for this artwork made by \(childName)."
            }
            Attachment(cgImage).label("The child's artwork")
        }

        for engine in currentAvailability().capableAppleEngines {
            do {
                let generated: GeneratedArtworkSuggestion
                switch engine {
                case .onDevice:
                    generated = try await respond(
                        model: SystemLanguageModel.default,
                        instructions: suggestionInstructions,
                        prompt: prompt
                    )
                case .privateCloudCompute:
                    generated = try await respond(
                        model: PrivateCloudComputeLanguageModel(),
                        instructions: suggestionInstructions,
                        prompt: prompt
                    )
                case .fallback:
                    continue
                }

                let title = generated.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let caption = generated.caption.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty || !caption.isEmpty else { continue }

                return (
                    AISuggestion(
                        title: title.isEmpty ? "My Artwork" : title,
                        caption: caption.isEmpty ? "A colorful creation full of imagination." : caption,
                        medium: generated.medium
                    ),
                    engine
                )
            } catch {
                // Rate limits, timeouts, guardrails, context overflow —
                // fall through to the next engine in the ladder.
                continue
            }
        }
        return nil
    }

    // MARK: - Screening

    /// Screens an image for artwork content and appropriateness using Apple
    /// engines. Pass `allowPrivateCloudCompute: false` on capture-time paths
    /// that must guarantee the image never leaves the device.
    /// Returns nil when no Apple engine could serve the request.
    static func screenArtwork(
        imageData: Data,
        allowPrivateCloudCompute: Bool
    ) async -> ArtworkValidationResult? {
        guard let cgImage = preparedCGImage(from: imageData) else { return nil }

        let prompt = Prompt {
            "Classify this image."
            Attachment(cgImage).label("Image to classify")
        }

        var engines = currentAvailability().capableAppleEngines
        if !allowPrivateCloudCompute {
            engines.removeAll { $0 == .privateCloudCompute }
        }

        for engine in engines {
            do {
                let screening: ArtworkScreening
                switch engine {
                case .onDevice:
                    screening = try await respond(
                        model: SystemLanguageModel.default,
                        instructions: screeningInstructions,
                        prompt: prompt
                    )
                case .privateCloudCompute:
                    screening = try await respond(
                        model: PrivateCloudComputeLanguageModel(),
                        instructions: screeningInstructions,
                        prompt: prompt
                    )
                case .fallback:
                    continue
                }

                if screening.isArtwork && screening.isAppropriate {
                    return .valid
                }
                let message = screening.isAppropriate
                    ? "This doesn't look like artwork. \(screening.subject.prefix(60))"
                    : "This image doesn't appear appropriate for a children's app."
                return ArtworkValidationResult(
                    isArtwork: screening.isArtwork,
                    isAppropriate: screening.isAppropriate,
                    message: message
                )
            } catch let error as LanguageModelError {
                // In a children's app, a guardrail or refusal during
                // screening is itself a flag signal.
                switch error {
                case .guardrailViolation, .refusal:
                    return ArtworkValidationResult(
                        isArtwork: false,
                        isAppropriate: false,
                        message: "This image doesn't appear appropriate for a children's app."
                    )
                default:
                    continue
                }
            } catch {
                continue
            }
        }
        return nil
    }

    // MARK: - Helpers

    /// Runs a guided-generation request against any language model.
    /// One fresh session per request — these are stateless use cases.
    /// The schema is enforced at decode time, so it is omitted from the
    /// prompt (`includeSchemaInPrompt: false`) for a faster first token;
    /// a response-token cap bounds tail latency.
    private static func respond<Output: Generable>(
        model: some LanguageModel,
        instructions: String,
        prompt: Prompt
    ) async throws -> Output {
        let session = LanguageModelSession(model: model, instructions: instructions)
        return try await session.respond(
            to: prompt,
            generating: Output.self,
            includeSchemaInPrompt: false,
            options: GenerationOptions(temperature: 0.8, maximumResponseTokens: 120)
        ).content
    }

    /// Decodes, orientation-normalizes, and downsamples an image so the
    /// longest edge is at most `maxDimension` points before attaching it
    /// to a prompt. 768 px keeps plenty of detail for artwork recognition
    /// while cutting vision-encoding latency versus larger attachments.
    private static func preparedCGImage(from data: Data, maxDimension: CGFloat = 768) -> CGImage? {
        guard let image = UIImage(data: data) else { return nil }

        let longestEdge = max(image.size.width, image.size.height)
        guard longestEdge > 0 else { return nil }

        let scale = min(1, maxDimension / longestEdge)
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let normalized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return normalized.cgImage
    }
}

#endif
