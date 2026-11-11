// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import os

/// Moments a haptic mouse could feel, written to the unified log for a
/// companion Logi Options+ plugin to stream. Only the event's name is
/// logged, never any content.
enum NotchMouseHaptics {
    enum Event: String, CaseIterable {
        /// The island opens, closes or switches section.
        case navigate
        /// The timer ruler passes a minute.
        case timerTick
        /// A timer or Pomodoro phase finished.
        case timerFinished
        /// A notification arrived in the island.
        case notification
    }

    static let subsystem = "com.vorssaint.utils"
    static let category = "MouseHaptics"
    static let marker = "vorssaint-haptic:"

    private static let logger = Logger(subsystem: subsystem, category: category)

    static func message(_ event: Event) -> String { marker + event.rawValue }

    static func signal(_ event: Event) {
        logger.notice("\(message(event), privacy: .public)")
    }
}
