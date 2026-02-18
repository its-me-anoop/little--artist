//
//  Color+Hex.swift
//  Little Artist
//
//  Convenience initialiser for creating SwiftUI Colors from hex strings.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

extension Color {
    /// Creates a `Color` from a 6-digit hexadecimal RGB string.
    ///
    /// - Parameter hex: A string such as `"FF8C00"`. Leading `#` or other
    ///   non-alphanumeric characters are stripped automatically. If the
    ///   string does not contain exactly 6 hex digits, the colour falls
    ///   back to white.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }

        self.init(red: r, green: g, blue: b)
    }
}
