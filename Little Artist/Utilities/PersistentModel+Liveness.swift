//
//  PersistentModel+Liveness.swift
//  Little Artist
//
//  SwiftData traps (EXC_BREAKPOINT) when a view reads a property of a
//  model that has been deleted — by the user, by a cascade, or by an
//  iCloud merge — while the view still holds a reference to it. Views
//  that hold a model check `isLive` before reading anything else.
//

import SwiftData

extension PersistentModel {
    /// Whether this model can still be read safely. False once it has been
    /// deleted or detached from its context. Reading `isDeleted` and
    /// `modelContext` never traps, unlike reading stored properties.
    var isLive: Bool {
        !isDeleted && modelContext != nil
    }
}
