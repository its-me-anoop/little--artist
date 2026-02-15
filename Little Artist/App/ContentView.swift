//
//  ContentView.swift
//  Little Artist
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
