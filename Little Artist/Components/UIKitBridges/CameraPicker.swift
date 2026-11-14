//
//  CameraPicker.swift
//  Little Artist
//
//  A reusable UIImagePickerController wrapper for capturing photos.
//

import SwiftUI

/// A `UIViewControllerRepresentable` wrapper around `UIImagePickerController`
/// configured for camera capture. Returns the captured `UIImage` via a closure.
struct CameraPicker: UIViewControllerRepresentable {
    /// Called with the captured image when the user takes a photo.
    let onImageCaptured: (UIImage) -> Void
    /// Whether to use the rear camera. Reads from the "defaultCameraBack"
    /// preference and defaults to the rear camera (artwork is photographed,
    /// not selfies) when the user has never changed it.
    var useBackCamera: Bool = UserDefaults.standard.object(forKey: "defaultCameraBack") as? Bool ?? true

    /// Whether this device has a camera. Callers should hide camera entry
    /// points when false; the picker falls back to the photo library.
    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Presenting `.camera` on a device without one (e.g. the Simulator)
        // throws, so fall back to the photo library.
        guard Self.isCameraAvailable else {
            picker.sourceType = .photoLibrary
            picker.delegate = context.coordinator
            return picker
        }
        picker.sourceType = .camera
        let preferred: UIImagePickerController.CameraDevice = useBackCamera ? .rear : .front
        picker.cameraDevice = UIImagePickerController.isCameraDeviceAvailable(preferred) ? preferred : .rear
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
