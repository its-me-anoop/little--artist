import ImagePlayground
import SwiftUI

extension View {
    /// Conditionally applies `.imagePlaygroundSheet` only on iOS 18.1+.
    @ViewBuilder
    func imagePlaygroundSheetCompat(
        isPresented: Binding<Bool>,
        onCompletion: @escaping (URL) -> Void
    ) -> some View {
        if #available(iOS 18.1, *) {
            self.imagePlaygroundSheet(
                isPresented: isPresented,
                onCompletion: onCompletion
            )
        } else {
            self
        }
    }

    /// Whether Image Playground is available on this device.
    var isImagePlaygroundAvailable: Bool {
        if #available(iOS 18.1, *) {
            return true
        }
        return false
    }
}
