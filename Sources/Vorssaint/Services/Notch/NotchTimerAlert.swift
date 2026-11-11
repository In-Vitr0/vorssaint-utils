// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

/// The deadline survives preference changes and suspension, so a completed
/// alarm cannot be restarted by a redraw, device change or return from sleep.
final class NotchTimerAlert {
    static let maximumDuration: Duration = .seconds(5 * 60)
    private var task: Task<Void, Never>?
    private var deadline: ContinuousClock.Instant?
    private let interval: Duration
    private let now: () -> ContinuousClock.Instant
    private let sound: () -> Void
    private let stopSound: () -> Void
    /// Rings a haptic mouse with every chime, sound on or off, until the
    /// finished timer is dismissed, as a watch keeps tapping.
    private let haptic: () -> Void
    private var soundEnabled = false

    convenience init() {
        let tone = NSSound(contentsOfFile: "/System/Library/Sounds/Glass.aiff", byReference: false)
        self.init(sound: {
            if let tone { tone.stop(); tone.play() }
            else { NSSound.beep() }
        }, stopSound: { tone?.stop() }, haptic: { NotchMouseHaptics.signal(.timerFinished) })
    }

    init(interval: Duration = .seconds(2), now: @escaping () -> ContinuousClock.Instant = { .now },
         sound: @escaping () -> Void, stopSound: @escaping () -> Void, haptic: @escaping () -> Void = {}) {
        self.interval = interval
        self.now = now
        self.sound = sound
        self.stopSound = stopSound
        self.haptic = haptic
    }

    func start(enabled: Bool) {
        let current = now()
        let deadline = self.deadline ?? current.advanced(by: Self.maximumDuration)
        self.deadline = deadline
        guard current < deadline else { suspend(); return }
        let soundTurnsOn = enabled && !soundEnabled
        if soundEnabled, !enabled { stopSound() }
        soundEnabled = enabled
        // Already ringing for the haptic: sound joins at once when it is turned on.
        guard task == nil else { if soundTurnsOn { sound() }; return }
        ring()
        task = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let delay = self?.delay(until: deadline) else { return }
                do { try await Task.sleep(for: delay, clock: .continuous) }
                catch { return }
                guard !Task.isCancelled, let self else { return }
                guard self.now() < deadline else { self.suspend(); return }
                self.ring()
            }
        }
    }

    private func ring() {
        haptic()
        if soundEnabled { sound() }
    }

    func suspend() {
        task?.cancel(); task = nil
        stopSound()
    }

    func stop() {
        suspend()
        deadline = nil
    }

    private func delay(until deadline: ContinuousClock.Instant) -> Duration {
        max(.zero, min(interval, now().duration(to: deadline)))
    }

    deinit { task?.cancel(); stopSound() }
}
