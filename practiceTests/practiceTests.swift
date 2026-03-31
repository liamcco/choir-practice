//
//  practiceTests.swift
//  practiceTests
//
//  Created by Liam Cotton on 31/03/2026.
//

import Testing
@testable import practice

struct practiceTests {
    @Test func noteNameUsesChromaticMapping() {
        #expect(PitchMath.noteName(for: 440) == "A4")
        #expect(PitchMath.noteName(for: 466.16) == "A#4")
    }

    @Test func scoreRewardsCloserPitch() {
        #expect(PitchMath.score(forAverageCentsOff: 4) == 120)
        #expect(PitchMath.score(forAverageCentsOff: 18) == 80)
        #expect(PitchMath.score(forAverageCentsOff: 39) == 60)
    }

    @Test func phraseEvaluationRewardsAccurateSamples() {
        let phrase = PhraseChallenge.samples[0]
        let samples = phrase.notes.flatMap { note -> [PhraseTraceSample] in
            let start = note.startTime(beatDuration: phrase.beatDuration)
            let duration = note.durationBeats * phrase.beatDuration
            return stride(from: 0.05, to: max(duration - 0.05, 0.1), by: 0.18).map { offset in
                PhraseTraceSample(
                    time: start + offset,
                    duration: 0.18,
                    midi: note.midiValue
                )
            }
        }

        let result = PitchMath.evaluatePhrase(phrase, samples: samples)

        #expect(result.pitchScore >= 90)
        #expect(result.rhythmScore >= 75)
    }
}
