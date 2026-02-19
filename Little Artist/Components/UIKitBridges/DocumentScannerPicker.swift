//
//  DocumentScannerPicker.swift
//  Little Artist
//
//  A reusable VNDocumentCameraViewController wrapper for scanning documents.
//

import SwiftUI
import VisionKit

/// A `UIViewControllerRepresentable` wrapper around `VNDocumentCameraViewController`.
/// Returns the first scanned page as a `UIImage` via a closure.
struct DocumentScannerPicker: UIViewControllerRepresentable {
    /// Called with the scanned image when scanning completes.
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onImageCaptured: (UIImage) -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                onImageCaptured(image)
            }
            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: any Error
        ) {
            controller.dismiss(animated: true)
        }
    }
}
