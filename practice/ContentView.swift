//
//  ContentView.swift
//  practice
//
//  Created by Liam Cotton on 31/03/2026.
//

import AVFoundation
import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var game = PitchTrainerGame()
    @State private var screen: AppScreen = .menu

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.16),
                    Color(red: 0.10, green: 0.22, blue: 0.34),
                    Color(red: 0.88, green: 0.49, blue: 0.19)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch screen {
            case .menu:
                menuView
            case .singleNote:
                singleNoteView
            case .phrase:
                phraseView
            }
        }
        .task {
            await game.prepare()
        }
    }

    private var menuView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Text("Sing Challenge")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Choose a mode, watch the pitch guide, and sing as accurately as you can.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))

                Text("Total Score: \(game.totalScore)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.yellow)
            }

            VStack(spacing: 18) {
                menuCard(
                    title: "Single Note",
                    subtitle: "One target note. Hold it for one second and score on pitch accuracy.",
                    accent: Color(red: 0.33, green: 0.81, blue: 0.58)
                ) {
                    game.enterSingleNoteMode()
                    screen = .singleNote
                }

                menuCard(
                    title: "Phrase Mode",
                    subtitle: "Sing a two-bar phrase with pitch and rhythm scoring plus a live pitch lane.",
                    accent: Color(red: 0.96, green: 0.74, blue: 0.24)
                ) {
                    game.enterPhraseMode()
                    screen = .phrase
                }
            }

            if let errorMessage = game.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.top, 8)
            }
        }
        .padding(24)
    }

    private var singleNoteView: some View {
        VStack(spacing: 20) {
            topBar(title: "Single Note") {
                game.leaveMode()
                screen = .menu
            }

            VStack(spacing: 10) {
                Text("Match the target pitch and hold it steady.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.84))

                Text("Total Score: \(game.totalScore)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.yellow)
            }

            VStack(spacing: 12) {
                Text("Target")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.75))

                Text(game.targetNote.name)
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(String(format: "%.1f Hz", game.targetNote.frequency))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.82))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 16) {
                HStack {
                    infoPill(title: "Detected", value: game.detectedNoteName)
                    infoPill(title: "Offset", value: game.centsDescription)
                }

                ProgressView(value: game.noteHoldProgress)
                    .tint(.green)
                    .scaleEffect(x: 1, y: 1.6, anchor: .center)

                Text(game.noteStatus)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                if let result = game.noteResultText {
                    Text(result)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.yellow)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Button(action: game.startSingleNoteRound) {
                Text(game.isSingleNoteRoundActive ? "Try Another Note" : "Start Quiz")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.22))
            }

            Spacer(minLength: 0)
        }
        .padding(24)
    }

    private var phraseView: some View {
        VStack(spacing: 18) {
            topBar(title: "Phrase Mode") {
                game.leaveMode()
                screen = .menu
            }

            VStack(spacing: 8) {
                Text(game.activePhrase.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Two bars, one voice, SingStar-style pitch lane.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))

                Text("Total Score: \(game.totalScore)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.yellow)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Sheet")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()

                    Text("\(Int(game.activePhrase.bpm)) BPM")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.75))
                }

                PhraseSheetView(phrase: game.activePhrase)
                    .frame(height: 170)
                    .padding(12)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Pitch Lane")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()

                    Text(game.phraseStateLabel)
                        .font(.headline)
                        .foregroundStyle(.yellow)
                }

                PhraseTrackView(
                    phrase: game.activePhrase,
                    samples: game.phraseTrace,
                    playheadTime: game.phrasePlayheadTime
                )
                .frame(height: 220)
                .padding(12)
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            HStack {
                infoPill(title: "Detected", value: game.detectedNoteName)
                infoPill(title: "Offset", value: game.centsDescription)
            }

            Text(game.phraseStatus)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            if let result = game.phraseResult {
                HStack {
                    resultPill(title: "Pitch", value: "\(result.pitchScore)")
                    resultPill(title: "Rhythm", value: "\(result.rhythmScore)")
                    resultPill(title: "Total", value: "\(result.total)")
                }
            }

            Button(action: game.startPhraseRound) {
                Text(game.isPhraseRoundRunning ? "Restart Phrase" : "Start Phrase")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.22))
            }

            Spacer(minLength: 0)
        }
        .padding(24)
    }

    private func menuCard(
        title: String,
        subtitle: String,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Circle()
                        .fill(accent)
                        .frame(width: 16, height: 16)
                }

                Text(subtitle)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.white.opacity(0.84))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(accent.opacity(0.75), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func topBar(title: String, back: @escaping () -> Void) -> some View {
        HStack {
            Button(action: back) {
                Label("Menu", systemImage: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.12), in: Capsule())
                    .foregroundStyle(.white)
            }

            Spacer()

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 90, height: 1)
        }
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.65))

            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func resultPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.68))

            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(.yellow)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct PhraseSheetView: View {
    let phrase: PhraseChallenge

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let lineSpacing = height / 8
            let minMidi = phrase.midiRange.lowerBound - 1
            let maxMidi = phrase.midiRange.upperBound + 1

            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    let y = lineSpacing * CGFloat(index + 2)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(.white.opacity(0.35), lineWidth: 1)
                }

                ForEach(0...phrase.bars, id: \.self) { barIndex in
                    let x = width * CGFloat(Double(barIndex * 4) / phrase.totalBeats)
                    Path { path in
                        path.move(to: CGPoint(x: x, y: lineSpacing * 1.4))
                        path.addLine(to: CGPoint(x: x, y: lineSpacing * 6.6))
                    }
                    .stroke(.white.opacity(0.55), lineWidth: barIndex == 0 || barIndex == phrase.bars ? 2 : 1)
                }

                ForEach(phrase.notes) { note in
                    let noteMidX = width * CGFloat((note.startBeat + note.durationBeats / 2) / phrase.totalBeats)
                    let midiSpan = Double(max(maxMidi - minMidi, 1))
                    let normalized = CGFloat((note.midiValue - Double(minMidi)) / midiSpan)
                    let y = lineSpacing * 6.2 - normalized * lineSpacing * 4.2

                    Ellipse()
                        .fill(.white)
                        .frame(width: 18, height: 12)
                        .rotationEffect(.degrees(-22))
                        .position(x: noteMidX, y: y)

                    Path { path in
                        path.move(to: CGPoint(x: noteMidX + 8, y: y))
                        path.addLine(to: CGPoint(x: noteMidX + 8, y: y - 32))
                    }
                    .stroke(.white, lineWidth: 2)
                }
            }
        }
    }
}

struct PhraseTrackView: View {
    let phrase: PhraseChallenge
    let samples: [PhraseTraceSample]
    let playheadTime: Double?

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let laneCount = phrase.midiRange.upperBound - phrase.midiRange.lowerBound + 3

            ZStack {
                ForEach(0..<laneCount, id: \.self) { index in
                    let y = height * CGFloat(index) / CGFloat(max(laneCount - 1, 1))
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(.white.opacity(0.08), lineWidth: 1)
                }

                ForEach(0...Int(phrase.totalBeats), id: \.self) { beat in
                    let x = width * CGFloat(Double(beat) / phrase.totalBeats)
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    .stroke(.white.opacity(beat.isMultiple(of: 4) ? 0.24 : 0.10), lineWidth: beat.isMultiple(of: 4) ? 2 : 1)
                }

                ForEach(phrase.notes) { note in
                    let startTime = note.startTime(beatDuration: phrase.beatDuration)
                    let laneDuration = note.durationBeats * phrase.beatDuration
                    let x = width * CGFloat(startTime / phrase.totalDuration)
                    let laneWidth = width * CGFloat(laneDuration / phrase.totalDuration)
                    let y = yPosition(forMidi: note.midiValue, in: height)

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.94, green: 0.79, blue: 0.27).opacity(0.75))
                        .frame(width: max(laneWidth, 18), height: 16)
                        .position(x: x + laneWidth / 2, y: y)
                }

                if samples.count > 1 {
                    Path { path in
                        var started = false
                        for sample in samples {
                            let point = CGPoint(
                                x: width * CGFloat(sample.time / phrase.totalDuration),
                                y: yPosition(forMidi: sample.midi, in: height)
                            )

                            if started {
                                path.addLine(to: point)
                            } else {
                                path.move(to: point)
                                started = true
                            }
                        }
                    }
                    .stroke(Color(red: 0.32, green: 0.92, blue: 0.62), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }

                if let playheadTime {
                    let x = width * CGFloat(min(max(playheadTime / phrase.totalDuration, 0), 1))

                    Rectangle()
                        .fill(.white.opacity(0.85))
                        .frame(width: 2, height: height)
                        .position(x: x, y: height / 2)
                }
            }
        }
    }

    private func yPosition(forMidi midi: Double, in height: CGFloat) -> CGFloat {
        let minMidi = Double(phrase.midiRange.lowerBound - 1)
        let maxMidi = Double(phrase.midiRange.upperBound + 1)
        let normalized = (midi - minMidi) / max(maxMidi - minMidi, 1)
        return height * CGFloat(1 - normalized)
    }
}

enum AppScreen {
    case menu
    case singleNote
    case phrase
}

enum ActiveMode {
    case none
    case singleNote
    case phrase
}

enum PhraseRoundState {
    case ready
    case countdown
    case singing
    case finished
}

@MainActor
final class PitchTrainerGame: ObservableObject {
    @Published private(set) var totalScore = 0
    @Published private(set) var errorMessage: String?
    @Published private(set) var detectedFrequency: Double?
    @Published private(set) var detectedNoteName = "--"
    @Published private(set) var centsOff = 0.0

    @Published private(set) var targetNote = PitchMath.quizNotes.randomElement() ?? PitchMath.referenceA4
    @Published private(set) var noteHoldProgress = 0.0
    @Published private(set) var noteStatus = "Tap Start Quiz to get a note."
    @Published private(set) var noteResultText: String?
    @Published private(set) var isSingleNoteRoundActive = false

    @Published private(set) var activePhrase = PhraseChallenge.samples[0]
    @Published private(set) var phraseState: PhraseRoundState = .ready
    @Published private(set) var phraseStatus = "Press Start Phrase and sing when the count-in ends."
    @Published private(set) var phraseResult: PhraseResult?
    @Published private(set) var phraseTrace: [PhraseTraceSample] = []
    @Published private(set) var phrasePlayheadTime: Double?

    private let audioEngine = AVAudioEngine()
    private let processingQueue = DispatchQueue(label: "PitchTrainerGame.audio")
    private var hasPreparedAudio = false
    private var activeMode: ActiveMode = .none
    private var noteHeldDuration = 0.0
    private var noteMatchingOffsets: [Double] = []
    private var phraseSamples: [PhraseTraceSample] = []
    private var phraseTask: Task<Void, Never>?
    private var phraseSingingStartDate: Date?

    var centsDescription: String {
        guard detectedFrequency != nil else { return "--" }
        let rounded = Int(centsOff.rounded())
        return rounded == 0 ? "Perfect" : "\(rounded > 0 ? "+" : "")\(rounded) cents"
    }

    var phraseStateLabel: String {
        switch phraseState {
        case .ready:
            return "Ready"
        case .countdown:
            return "Count In"
        case .singing:
            return "Live"
        case .finished:
            return "Scored"
        }
    }

    var isPhraseRoundRunning: Bool {
        phraseState == .countdown || phraseState == .singing
    }

    func prepare() async {
        guard !hasPreparedAudio else { return }
        hasPreparedAudio = true

        let granted = await requestMicrophoneAccess()
        guard granted else {
            errorMessage = "Microphone access is required so the app can hear and score your singing."
            noteStatus = "Enable microphone permission, then relaunch the app."
            phraseStatus = noteStatus
            return
        }

        do {
            try configureAudioSessionIfNeeded()
            try startAudioEngine()
            noteStatus = "Tap Start Quiz when you're ready to sing."
            phraseStatus = "Press Start Phrase and sing when the count-in ends."
        } catch {
            errorMessage = "Audio setup failed: \(error.localizedDescription)"
            noteStatus = "The microphone could not be started."
            phraseStatus = noteStatus
        }
    }

    func enterSingleNoteMode() {
        leaveMode()
        activeMode = .singleNote
        noteStatus = "Tap Start Quiz when you're ready to sing."
    }

    func enterPhraseMode() {
        leaveMode()
        activeMode = .phrase
        activePhrase = PhraseChallenge.samples.randomElement() ?? PhraseChallenge.samples[0]
        phraseStatus = "Press Start Phrase and sing when the count-in ends."
    }

    func leaveMode() {
        activeMode = .none
        isSingleNoteRoundActive = false
        noteHoldProgress = 0
        noteResultText = nil
        noteMatchingOffsets.removeAll(keepingCapacity: true)
        noteHeldDuration = 0

        phraseTask?.cancel()
        phraseTask = nil
        phraseState = .ready
        phrasePlayheadTime = nil
        phraseResult = nil
        phraseTrace.removeAll(keepingCapacity: true)
        phraseSamples.removeAll(keepingCapacity: true)
        phraseSingingStartDate = nil
    }

    func startSingleNoteRound() {
        guard errorMessage == nil else { return }

        activeMode = .singleNote
        targetNote = PitchMath.quizNotes.randomElement() ?? PitchMath.referenceA4
        isSingleNoteRoundActive = true
        noteHeldDuration = 0
        noteHoldProgress = 0
        noteMatchingOffsets.removeAll(keepingCapacity: true)
        noteResultText = nil
        detectedFrequency = nil
        detectedNoteName = "--"
        centsOff = 0
        noteStatus = "Sing \(targetNote.name) and hold it steady."
    }

    func startPhraseRound() {
        guard errorMessage == nil else { return }

        activeMode = .phrase
        activePhrase = PhraseChallenge.samples.randomElement() ?? PhraseChallenge.samples[0]
        phraseState = .countdown
        phraseStatus = "2-bar count-in. Get ready."
        phraseResult = nil
        phraseTrace.removeAll(keepingCapacity: true)
        phraseSamples.removeAll(keepingCapacity: true)
        phrasePlayheadTime = nil
        detectedFrequency = nil
        detectedNoteName = "--"
        centsOff = 0

        phraseTask?.cancel()
        phraseTask = Task { [weak self] in
            await self?.runPhraseRound()
        }
    }

    private func runPhraseRound() async {
        let countInDuration = activePhrase.beatDuration * 8
        let totalDuration = activePhrase.totalDuration

        do {
            try await updatePhraseCountdown(for: countInDuration)
            try Task.checkCancellation()

            phraseState = .singing
            phraseStatus = "Sing now."
            phraseSingingStartDate = Date()
            phrasePlayheadTime = 0

            let frameInterval = 1.0 / 30.0
            while let startDate = phraseSingingStartDate {
                let elapsed = Date().timeIntervalSince(startDate)
                phrasePlayheadTime = min(elapsed, totalDuration)
                if elapsed >= totalDuration {
                    break
                }

                try await Task.sleep(for: .milliseconds(Int(frameInterval * 1_000)))
            }

            finishPhraseRound()
        } catch {
            return
        }
    }

    private func updatePhraseCountdown(for duration: Double) async throws {
        let countdownStart = Date()
        while true {
            let elapsed = Date().timeIntervalSince(countdownStart)
            let remaining = max(duration - elapsed, 0)
            let barsRemaining = Int(ceil(remaining / (activePhrase.beatDuration * 4)))
            phrasePlayheadTime = nil
            phraseStatus = remaining > 0.05 ? "\(max(barsRemaining, 1)) bar\(barsRemaining == 1 ? "" : "s")..." : "Go"
            if remaining <= 0 {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    private func finishPhraseRound() {
        let result = PitchMath.evaluatePhrase(activePhrase, samples: phraseSamples)
        phraseResult = result
        totalScore += result.total
        phraseState = .finished
        phraseStatus = "Pitch \(result.pitchScore), rhythm \(result.rhythmScore)."
        phrasePlayheadTime = activePhrase.totalDuration
        phraseTask = nil
    }

    private func startAudioEngine() throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2_048, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let sampleRate = format.sampleRate
            let duration = Double(buffer.frameLength) / sampleRate

            self.processingQueue.async {
                guard let frequency = PitchDetector.detectPitch(in: buffer, sampleRate: sampleRate) else { return }
                Task { @MainActor in
                    self.handleDetectedPitch(frequency, sampleDuration: duration)
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func handleDetectedPitch(_ frequency: Double, sampleDuration: Double) {
        detectedFrequency = frequency
        detectedNoteName = PitchMath.noteName(for: frequency)

        switch activeMode {
        case .singleNote:
            updateSingleNoteRound(frequency: frequency, sampleDuration: sampleDuration)
        case .phrase:
            updatePhraseTracking(frequency: frequency, sampleDuration: sampleDuration)
        case .none:
            break
        }
    }

    private func updateSingleNoteRound(frequency: Double, sampleDuration: Double) {
        centsOff = PitchMath.centsOffset(frequency: frequency, targetFrequency: targetNote.frequency)
        guard isSingleNoteRoundActive else { return }

        let absoluteOffset = abs(centsOff)
        if absoluteOffset <= 40 {
            noteHeldDuration += sampleDuration
            noteHoldProgress = min(noteHeldDuration, 1)
            noteMatchingOffsets.append(absoluteOffset)
        } else {
            noteHeldDuration = max(0, noteHeldDuration - sampleDuration * 1.5)
            noteHoldProgress = min(noteHeldDuration, 1)
            if noteMatchingOffsets.count > 4 {
                noteMatchingOffsets.removeFirst(min(2, noteMatchingOffsets.count))
            }
        }

        if noteHeldDuration >= 1 {
            let averageOffset = noteMatchingOffsets.average
            let roundScore = PitchMath.score(forAverageCentsOff: averageOffset)

            totalScore += roundScore
            isSingleNoteRoundActive = false
            noteResultText = "Nice. \(Int(averageOffset.rounded())) cents off, +\(roundScore) points."
            noteStatus = "Round complete. Start another note."
            noteHoldProgress = 1
        }
    }

    private func updatePhraseTracking(frequency: Double, sampleDuration: Double) {
        guard phraseState == .singing, let phraseSingingStartDate else {
            centsOff = 0
            return
        }

        let elapsed = Date().timeIntervalSince(phraseSingingStartDate)
        guard elapsed >= 0, elapsed <= activePhrase.totalDuration else { return }

        let midiValue = PitchMath.midi(for: frequency)
        let targetMidi = activePhrase.targetMIDINear(time: elapsed) ?? midiValue

        centsOff = (midiValue - targetMidi) * 100

        let sample = PhraseTraceSample(time: elapsed, duration: sampleDuration, midi: midiValue)
        phraseSamples.append(sample)
        phraseTrace.append(sample)

        if phraseTrace.count > 500 {
            phraseTrace.removeFirst(min(60, phraseTrace.count))
        }
    }

    private func requestMicrophoneAccess() async -> Bool {
        #if os(iOS)
        return await withCheckedContinuation { continuation in
            if #available(iOS 17, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        #elseif os(macOS)
        return await AVCaptureDevice.requestAccess(for: .audio)
        #else
        return true
        #endif
    }

    private func configureAudioSessionIfNeeded() throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)
        #endif
    }
}

struct QuizNote: Equatable {
    let name: String
    let frequency: Double

    var midiValue: Double {
        PitchMath.midi(for: frequency)
    }
}

struct PhraseNote: Identifiable, Equatable {
    let id = UUID()
    let note: QuizNote
    let startBeat: Double
    let durationBeats: Double

    var midiValue: Double {
        note.midiValue
    }
}

struct PhraseChallenge: Equatable {
    let title: String
    let bpm: Double
    let bars: Int
    let notes: [PhraseNote]

    var totalBeats: Double {
        Double(bars * 4)
    }

    var beatDuration: Double {
        60 / bpm
    }

    var totalDuration: Double {
        totalBeats * beatDuration
    }

    var midiRange: ClosedRange<Int> {
        let values = notes.map { Int($0.midiValue.rounded()) }
        let minimum = values.min() ?? 60
        let maximum = values.max() ?? 67
        return minimum...maximum
    }

    func targetMIDINear(time: Double) -> Double? {
        notes.first(where: {
            time >= $0.startTime(beatDuration: beatDuration) && time <= $0.endTime(beatDuration: beatDuration)
        })?.midiValue
    }

    static let samples: [PhraseChallenge] = [
        PhraseChallenge(
            title: "Morning Echo",
            bpm: 92,
            bars: 2,
            notes: [
                PhraseNote(note: PitchMath.note(midi: 60), startBeat: 0, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 62), startBeat: 1, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 64), startBeat: 2, durationBeats: 2),
                PhraseNote(note: PitchMath.note(midi: 67), startBeat: 4, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 65), startBeat: 5, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 64), startBeat: 6, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 62), startBeat: 7, durationBeats: 1)
            ]
        ),
        PhraseChallenge(
            title: "Gentle Climb",
            bpm: 88,
            bars: 2,
            notes: [
                PhraseNote(note: PitchMath.note(midi: 55), startBeat: 0, durationBeats: 2),
                PhraseNote(note: PitchMath.note(midi: 57), startBeat: 2, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 59), startBeat: 3, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 60), startBeat: 4, durationBeats: 2),
                PhraseNote(note: PitchMath.note(midi: 59), startBeat: 6, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 57), startBeat: 7, durationBeats: 1)
            ]
        ),
        PhraseChallenge(
            title: "Little Hook",
            bpm: 96,
            bars: 2,
            notes: [
                PhraseNote(note: PitchMath.note(midi: 64), startBeat: 0, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 67), startBeat: 1, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 69), startBeat: 2, durationBeats: 2),
                PhraseNote(note: PitchMath.note(midi: 67), startBeat: 4, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 64), startBeat: 5, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 62), startBeat: 6, durationBeats: 1),
                PhraseNote(note: PitchMath.note(midi: 64), startBeat: 7, durationBeats: 1)
            ]
        )
    ]
}

struct PhraseTraceSample: Identifiable, Equatable {
    let id = UUID()
    let time: Double
    let duration: Double
    let midi: Double
}

struct PhraseResult: Equatable {
    let pitchScore: Int
    let rhythmScore: Int

    var total: Int {
        pitchScore + rhythmScore
    }
}

extension PhraseNote {
    func startTime(beatDuration: Double) -> Double {
        startBeat * beatDuration
    }

    func endTime(beatDuration: Double) -> Double {
        (startBeat + durationBeats) * beatDuration
    }
}

enum PitchMath {
    static let referenceA4 = QuizNote(name: "A4", frequency: 440)
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    static let quizNotes: [QuizNote] = (48...71).map { note(midi: $0) }

    static func note(midi: Int) -> QuizNote {
        QuizNote(name: noteName(forMIDINote: midi), frequency: frequency(forMIDINote: midi))
    }

    static func midi(for frequency: Double) -> Double {
        69 + 12 * log2(frequency / 440)
    }

    static func noteName(for frequency: Double) -> String {
        guard frequency > 0 else { return "--" }
        return noteName(forMIDINote: Int(midi(for: frequency).rounded()))
    }

    static func noteName(forMIDINote midi: Int) -> String {
        let pitchClass = (midi % 12 + 12) % 12
        let octave = midi / 12 - 1
        return "\(noteNames[pitchClass])\(octave)"
    }

    static func frequency(forMIDINote midi: Int) -> Double {
        440 * pow(2, Double(midi - 69) / 12)
    }

    static func centsOffset(frequency: Double, targetFrequency: Double) -> Double {
        1200 * log2(frequency / targetFrequency)
    }

    static func score(forAverageCentsOff cents: Double) -> Int {
        switch abs(cents) {
        case ..<8:
            return 120
        case ..<15:
            return 100
        case ..<25:
            return 80
        case ..<40:
            return 60
        default:
            return 40
        }
    }

    static func accuracyPercent(forAverageCentsOff cents: Double) -> Int {
        switch abs(cents) {
        case ..<8:
            return 100
        case ..<15:
            return 90
        case ..<25:
            return 80
        case ..<40:
            return 65
        case ..<60:
            return 45
        default:
            return 20
        }
    }

    static func evaluatePhrase(_ phrase: PhraseChallenge, samples: [PhraseTraceSample]) -> PhraseResult {
        guard !samples.isEmpty else {
            return PhraseResult(pitchScore: 0, rhythmScore: 0)
        }

        let beatDuration = phrase.beatDuration
        let pitchScores = phrase.notes.map { note -> Double in
            let start = note.startTime(beatDuration: beatDuration)
            let end = note.endTime(beatDuration: beatDuration)
            let targetMidi = note.midiValue
            let matched = samples.filter {
                $0.time + $0.duration >= start - 0.16 &&
                $0.time <= end + 0.16 &&
                abs($0.midi - targetMidi) <= 0.65
            }

            guard !matched.isEmpty else { return 0 }
            let averageCents = matched.map { abs($0.midi - targetMidi) * 100 }.average
            return Double(accuracyPercent(forAverageCentsOff: averageCents))
        }

        let rhythmScores = phrase.notes.map { note -> Double in
            let start = note.startTime(beatDuration: beatDuration)
            let end = note.endTime(beatDuration: beatDuration)
            let targetMidi = note.midiValue
            let matched = samples.filter {
                $0.time + $0.duration >= start - 0.18 &&
                $0.time <= end + 0.18 &&
                abs($0.midi - targetMidi) <= 0.75
            }

            guard let firstMatch = matched.map(\.time).min() else { return 0 }
            let onsetPenalty = min(abs(firstMatch - start) * 140, 50)
            let expectedDuration = max(end - start, 0.001)
            let sungDuration = min(matched.map(\.duration).reduce(0, +), expectedDuration)
            let coveragePenalty = (1 - (sungDuration / expectedDuration)) * 50
            return max(0, 100 - onsetPenalty - coveragePenalty)
        }

        return PhraseResult(
            pitchScore: Int(pitchScores.average.rounded()),
            rhythmScore: Int(rhythmScores.average.rounded())
        )
    }
}

enum PitchDetector {
    static func detectPitch(in buffer: AVAudioPCMBuffer, sampleRate: Double) -> Double? {
        guard
            let channelData = buffer.floatChannelData?.pointee,
            buffer.frameLength > 1
        else {
            return nil
        }

        let frameCount = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))

        let rms = sqrt(samples.reduce(0) { $0 + Double($1 * $1) } / Double(frameCount))
        guard rms > 0.01 else { return nil }

        let mean = samples.reduce(0, +) / Float(frameCount)
        let normalized = samples.map { Double($0 - mean) }

        let minFrequency = 80.0
        let maxFrequency = 1_000.0
        let minLag = max(Int(sampleRate / maxFrequency), 2)
        let maxLag = min(Int(sampleRate / minFrequency), frameCount / 2)

        guard minLag < maxLag else { return nil }

        var bestLag = 0
        var bestCorrelation = 0.0

        for lag in minLag...maxLag {
            var numerator = 0.0
            var energyA = 0.0
            var energyB = 0.0

            for index in 0..<(frameCount - lag) {
                let first = normalized[index]
                let second = normalized[index + lag]
                numerator += first * second
                energyA += first * first
                energyB += second * second
            }

            let denominator = sqrt(energyA * energyB)
            guard denominator > 0 else { continue }

            let correlation = numerator / denominator
            if correlation > bestCorrelation {
                bestCorrelation = correlation
                bestLag = lag
            }
        }

        guard bestLag > 0, bestCorrelation > 0.82 else { return nil }
        return sampleRate / Double(bestLag)
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

#Preview {
    ContentView()
}
