//
//  HasanaGardenAudioSystem.swift
//  Hasana
//
//  Created by Azzam Alrashed on 2026-05-26.
//

import Foundation
import AVFoundation
import Observation
import UIKit
import Combine
import SwiftUI

// ==========================================
// MARK: - SYSTEM OVERVIEW & DSP MATHEMATICS
// ==========================================
/*
 This file implements a self-contained, real-time procedural audio synthesis engine
 specifically designed for the Hasana 3D Garden. Rather than playing back static, looping MP3
 files that cause audible repetition fatigue, this engine synthesizes all sounds mathematically
 on a dedicated real-time audio thread using standard iOS AVFoundation audio units.
 
 The soundscape consists of:
 1. Wind (Rumble & Swells): Brownian noise processed through a pair of dynamically modulated
    biquad bandpass filters. Cutoff frequencies and Q factors are modulated by a mixture of
    low-frequency oscillators (LFOs) to simulate random, organic wind gusts.
 2. Foliage Rustle: Pink noise processed through a biquad highpass filter and modulated
    by wind speed. It features a random impulse/crackle generator that simulates the sound of
    individual leaves colliding as the wind accelerates.
 3. Bird Chimes / Chirps: Synthesized using frequency-swept sine wave oscillators with optional
    vibrato (FM). A procedural scheduling engine triggers various bird call patterns (chirps, warbles,
    harmonized chimes) at random intervals, governed by the garden's tending state and time of day.
 4. Tap Sound Triggers: Pluck, chime, and resonant woodblock sounds generated instantly upon user interaction:
    - Foundational Trees: Woodblock sound synthesized using dual resonant FM carrier frequencies (low-pitched).
    - Leafy Plants: Plucky water-droplet sweep (frequency sliding downwards rapidly).
    - Flowers: High-frequency metallic chime bell (FM carrier-modulator ratio 1.625).
    - Panning: Taps are panned dynamically in the stereo field based on the plant's 2D default position.
 5. Sound Dampening Model: Translates high-level garden parameters (dormancy ratio, wetness, time of day,
    and camera distance) into precise DSP coefficients, low/high shelving EQ gains, and reverb mixes.
 
 Real-time Thread Safety:
 All DSP generation is contained within the `AVAudioSourceNode` render block. To prevent audio glitches
 (clicks, dropouts), we avoid heap allocations, locking, or system API calls on the real-time thread.
 Parameters from the main thread are passed safely using a lightweight unfair lock and smoothed
 sample-by-sample using one-pole lowpass filter interpolation.
*/

// ==========================================
// MARK: - DSP BASIC MATH HELPERS
// ==========================================

/// A lightweight, non-recursive, thread-safe lock using `os_unfair_lock`.
/// Used for crossing thread boundaries (Main UI thread -> Real-time audio thread) with minimal latency.
final class UnfairLock {
    private var lock = os_unfair_lock_s()
    
    func sync<T>(_ closure: () -> T) -> T {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return closure()
    }
}

/// A fast, deterministic 64-bit Linear Congruential Generator (LCG) for noise and random parameter selection.
/// Avoids using system `arc4random()` inside the audio render thread, which can block.
struct LCG {
    var state: UInt64
    
    init(seed: UInt64 = 1337) {
        self.state = seed == 0 ? 1337 : seed
    }
    
    mutating func next() -> UInt64 {
        // Multiplier and increment coefficients from Knuth/Numerical Recipes
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
    
    mutating func nextDouble() -> Double {
        let value = next()
        return Double(value) / Double(UInt64.max)
    }
    
    mutating func nextFloat() -> Float {
        let value = next()
        return Float(value) / Float(UInt64.max)
    }
    
    mutating func nextRange(min: Double, max: Double) -> Double {
        return min + nextDouble() * (max - min)
    }
}

/// An implementation of a standard second-order biquad filter.
/// Coefficients are updated dynamic-analytically without memory allocation.
struct BiquadFilter {
    var b0: Double = 0.0, b1: Double = 0.0, b2: Double = 0.0
    var a1: Double = 0.0, a2: Double = 0.0
    var x1: Double = 0.0, x2: Double = 0.0
    var y1: Double = 0.0, y2: Double = 0.0
    
    private var lastCutoff: Double = -1.0
    private var lastQ: Double = -1.0
    private var lastSampleRate: Double = -1.0
    
    mutating func updateLowpass(cutoff: Double, q: Double, sampleRate: Double) {
        if cutoff == lastCutoff && q == lastQ && sampleRate == lastSampleRate { return }
        lastCutoff = cutoff
        lastQ = q
        lastSampleRate = sampleRate
        
        let w0 = 2.0 * .pi * cutoff / sampleRate
        let cosW0 = cos(w0)
        let alpha = sin(w0) / (2.0 * q)
        
        let a0 = 1.0 + alpha
        b0 = ((1.0 - cosW0) / 2.0) / a0
        b1 = (1.0 - cosW0) / a0
        b2 = ((1.0 - cosW0) / 2.0) / a0
        a1 = (-2.0 * cosW0) / a0
        a2 = (1.0 - alpha) / a0
    }
    
    mutating func updateHighpass(cutoff: Double, q: Double, sampleRate: Double) {
        if cutoff == lastCutoff && q == lastQ && sampleRate == lastSampleRate { return }
        lastCutoff = cutoff
        lastQ = q
        lastSampleRate = sampleRate
        
        let w0 = 2.0 * .pi * cutoff / sampleRate
        let cosW0 = cos(w0)
        let alpha = sin(w0) / (2.0 * q)
        
        let a0 = 1.0 + alpha
        b0 = ((1.0 + cosW0) / 2.0) / a0
        b1 = (-(1.0 + cosW0)) / a0
        b2 = ((1.0 + cosW0) / 2.0) / a0
        a1 = (-2.0 * cosW0) / a0
        a2 = (1.0 - alpha) / a0
    }
    
    mutating func updateBandpass(cutoff: Double, q: Double, sampleRate: Double) {
        if cutoff == lastCutoff && q == lastQ && sampleRate == lastSampleRate { return }
        lastCutoff = cutoff
        lastQ = q
        lastSampleRate = sampleRate
        
        let w0 = 2.0 * .pi * cutoff / sampleRate
        let sinW0 = sin(w0)
        let cosW0 = cos(w0)
        let alpha = sinW0 / (2.0 * q)
        
        let a0 = 1.0 + alpha
        b0 = alpha / a0 // constant peak gain
        b1 = 0.0
        b2 = -alpha / a0
        a1 = (-2.0 * cosW0) / a0
        a2 = (1.0 - alpha) / a0
    }
    
    @inline(__always)
    mutating func process(_ sample: Double) -> Double {
        let x0 = sample
        let y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        
        x2 = x1
        x1 = x0
        y2 = y1
        y1 = y0
        
        // Prevent denormals (subnormal floating point numbers causing high CPU usage)
        if abs(y1) < 1e-15 { y1 = 0.0 }
        if abs(y2) < 1e-15 { y2 = 0.0 }
        
        return y0
    }
}

/// A simple sinusoidal Low-Frequency Oscillator (LFO) for modulating parameters.
struct LFO {
    private var phase: Double = 0.0
    var frequency: Double
    var sampleRate: Double
    
    init(frequency: Double, sampleRate: Double = 44100.0) {
        self.frequency = frequency
        self.sampleRate = sampleRate
    }
    
    mutating func next() -> Double {
        let val = sin(phase)
        phase += 2.0 * .pi * frequency / sampleRate
        if phase >= 2.0 * .pi {
            phase -= 2.0 * .pi
        }
        return val
    }
}

// ==========================================
// MARK: - NOISE & WIND SYNTHESIZERS
// ==========================================

/// Pink noise generator implementing the Voss-McCartney algorithm.
/// Provides a -3dB/octave spectral decay profile for natural atmospheric weight.
struct PinkNoiseGenerator {
    private var rows = Array(repeating: 0.0, count: 12)
    private var runningSum: Double = 0.0
    private var index: UInt32 = 0
    private var rng = LCG(seed: 54321)
    
    mutating func next() -> Double {
        let lastIndex = index
        index = (index + 1) & 2047 // 2^12 - 1
        
        var diff = lastIndex ^ index
        var rIndex = 0
        while (diff & 1) == 0 {
            diff >>= 1
            rIndex += 1
        }
        
        runningSum -= rows[rIndex]
        let newRandom = rng.nextRange(min: -1.0, max: 1.0)
        rows[rIndex] = newRandom
        runningSum += newRandom
        
        let white = rng.nextRange(min: -1.0, max: 1.0)
        return (runningSum + white) * 0.08
    }
}

/// Brownian (red) noise generator using a leaky integrator with DC-drift protection.
/// Provides a -6dB/octave decay, perfect for deep wind rumble and ocean-like sounds.
struct BrownNoiseGenerator {
    private var accumulator: Double = 0.0
    private var rng = LCG(seed: 9988)
    private var dcFilter = BiquadFilter()
    
    init() {
        dcFilter.updateHighpass(cutoff: 15.0, q: 0.707, sampleRate: 44100.0)
    }
    
    mutating func next() -> Double {
        let white = rng.nextRange(min: -1.0, max: 1.0)
        accumulator = 0.996 * accumulator + 0.04 * white
        return dcFilter.process(accumulator) * 0.25
    }
}

/// Leaf rustle synthesizer producing crispy high-frequency crackles.
/// Modulated by wind speed and a threshold impulse model.
struct FoliageRustleGenerator {
    private var pinkNoise = PinkNoiseGenerator()
    private var highpass = BiquadFilter()
    private var lfo = LFO(frequency: 0.25, sampleRate: 44100.0)
    private var rng = LCG(seed: 23232)
    
    init() {
        highpass.updateHighpass(cutoff: 4400.0, q: 0.8, sampleRate: 44100.0)
    }
    
    mutating func next(windSpeed: Double, dampeningFactor: Double) -> Double {
        let rawNoise = pinkNoise.next()
        let filtered = highpass.process(rawNoise)
        
        // Modulate crackle rate with wind speed
        lfo.frequency = 0.2 + windSpeed * 0.4
        let intensity = (lfo.next() + 1.0) * 0.5 * windSpeed
        
        // Impulsive crackles: simulate individual leaf impacts
        let threshold = 1.0 - (windSpeed * 0.82)
        let roll = rng.nextDouble()
        let isImpulse = roll > max(0.90, threshold)
        
        let impulseAmp = isImpulse ? (roll - threshold) / (1.0 - threshold) : 0.0
        let dampGain = max(0.0, 1.0 - dampeningFactor * 0.95)
        
        return filtered * impulseAmp * intensity * dampGain * 0.16
    }
}

/// Wind and foliage synthesizer combining rumble and rustle components with LFO modulators.
struct WindFoliageSynthesizer {
    private var brownNoise = BrownNoiseGenerator()
    private var windFilter1 = BiquadFilter()
    private var windFilter2 = BiquadFilter()
    private var rustleGen = FoliageRustleGenerator()
    
    private var lfo1 = LFO(frequency: 0.035, sampleRate: 44100.0)
    private var lfo2 = LFO(frequency: 0.11, sampleRate: 44100.0)
    
    mutating func next(windSpeed: Double, dampeningFactor: Double) -> Double {
        let noise = brownNoise.next()
        
        // Combined LFOs generate wind swells
        let swell1 = (lfo1.next() + 1.0) * 0.5
        let swell2 = (lfo2.next() + 1.0) * 0.5
        let gust = (swell1 * 0.65 + swell2 * 0.35) * windSpeed
        
        // Muffle frequencies based on dampening factor
        let baseCutoff1 = 150.0 + gust * 400.0
        let baseCutoff2 = 280.0 + gust * 750.0
        let cutoff1 = baseCutoff1 * max(0.2, 1.0 - dampeningFactor * 0.6)
        let cutoff2 = baseCutoff2 * max(0.2, 1.0 - dampeningFactor * 0.5)
        
        windFilter1.updateBandpass(cutoff: cutoff1, q: 1.8 + gust * 2.2, sampleRate: 44100.0)
        windFilter2.updateBandpass(cutoff: cutoff2, q: 1.2 + gust * 1.5, sampleRate: 44100.0)
        
        let windPart1 = windFilter1.process(noise)
        let windPart2 = windFilter2.process(noise)
        
        let windMix = (windPart1 * 0.7 + windPart2 * 0.3) * (0.2 + gust * 0.8)
        let rustleMix = rustleGen.next(windSpeed: windSpeed, dampeningFactor: dampeningFactor)
        
        let overallVolume = max(0.0, 1.0 - dampeningFactor * 0.75)
        return (windMix + rustleMix) * overallVolume
    }
}

// ==========================================
// MARK: - PROCEDURAL BIRD CHIMES & CHIRPS
// ==========================================

/// A single bird synthesizer voice. Generates frequency-swept sine wave with optional FM vibrato.
struct BirdVoice {
    var isActive: Bool = false
    var phase: Double = 0.0
    var sampleRate: Double = 44100.0
    
    var startFreq: Double = 0.0
    var endFreq: Double = 0.0
    var currentFreq: Double = 0.0
    var sweepRate: Double = 0.0
    
    var amplitude: Double = 0.0
    var decayRate: Double = 0.0
    
    var vibratoFreq: Double = 0.0
    var vibratoDepth: Double = 0.0
    var vibratoPhase: Double = 0.0
    
    var delaySamples: Int = 0
    
    mutating func trigger(
        startFreq: Double,
        endFreq: Double,
        duration: Double,
        volume: Double,
        vibratoFreq: Double = 0.0,
        vibratoDepth: Double = 0.0,
        delay: Double = 0.0
    ) {
        self.phase = 0.0
        self.startFreq = startFreq
        self.endFreq = endFreq
        self.currentFreq = startFreq
        
        let totalSamples = duration * sampleRate
        self.sweepRate = (endFreq - startFreq) / totalSamples
        
        self.amplitude = volume
        self.decayRate = volume / totalSamples
        
        self.vibratoFreq = vibratoFreq
        self.vibratoDepth = vibratoDepth
        self.vibratoPhase = 0.0
        
        self.delaySamples = Int(delay * sampleRate)
        self.isActive = true
    }
    
    mutating func next() -> Double {
        guard isActive else { return 0.0 }
        
        if delaySamples > 0 {
            delaySamples -= 1
            return 0.0
        }
        
        // FM / Vibrato logic
        var vibratoOffset = 0.0
        if vibratoFreq > 0.0 && vibratoDepth > 0.0 {
            vibratoOffset = sin(vibratoPhase) * vibratoDepth
            vibratoPhase += 2.0 * .pi * vibratoFreq / sampleRate
            if vibratoPhase >= 2.0 * .pi {
                vibratoPhase -= 2.0 * .pi
            }
        }
        
        let frequency = max(100.0, currentFreq + vibratoOffset)
        let sample = sin(phase) * amplitude
        
        phase += 2.0 * .pi * frequency / sampleRate
        if phase >= 2.0 * .pi {
            phase -= 2.0 * .pi
        }
        
        // Perform sweep
        if sweepRate > 0.0 {
            currentFreq = min(currentFreq + sweepRate, endFreq)
        } else {
            currentFreq = max(currentFreq + sweepRate, endFreq)
        }
        
        // Decay volume
        amplitude -= decayRate
        if amplitude <= 0.0 {
            amplitude = 0.0
            isActive = false
        }
        
        return sample
    }
}

/// Procedural scheduling manager for bird calls. Multi-voice, organic interval generation.
struct DSPBirdSynthesizer {
    var voices = Array(repeating: BirdVoice(), count: 6)
    private var rng = LCG(seed: 112233)
    private var sampleCounter: Int = 0
    private var nextTriggerSamples: Int = 44100 * 2
    
    mutating func process(birdActivity: Double, dampeningFactor: Double) -> Double {
        sampleCounter += 1
        if sampleCounter >= nextTriggerSamples {
            sampleCounter = 0
            
            // Interval changes based on activity and dampening (dampened = less frequent birds)
            let baseInterval = 1.2 + (1.0 - birdActivity) * 9.0
            let randomOffset = rng.nextDouble() * 3.0
            let totalSeconds = (baseInterval + randomOffset) * (1.0 + dampeningFactor * 2.5)
            nextTriggerSamples = Int(totalSeconds * 44100.0)
            
            if birdActivity > 0.05 {
                triggerRandomSong(activity: birdActivity)
            }
        }
        
        var mix = 0.0
        for i in 0..<voices.count {
            mix += voices[i].next()
        }
        
        return mix * 0.22 // scale down to keep it subtle
    }
    
    mutating func triggerRandomSong(activity: Double) {
        let songType = rng.next() % 4
        let baseVolume = (0.28 + rng.nextDouble() * 0.22) * activity
        
        switch songType {
        case 0: // Sweet short chirps (3 bursts)
            let startPitch = 2700.0 + rng.nextDouble() * 1100.0
            let chirpCount = 3
            for idx in 0..<chirpCount {
                if let freeIdx = findFreeVoice() {
                    voices[freeIdx].trigger(
                        startFreq: startPitch + Double(idx) * 120.0,
                        endFreq: startPitch + Double(idx) * 120.0 + 900.0,
                        duration: 0.045,
                        volume: baseVolume * 0.9,
                        vibratoFreq: 0.0,
                        vibratoDepth: 0.0,
                        delay: Double(idx) * 0.09
                    )
                }
            }
            
        case 1: // Decaying warble (vibrato)
            let pitch = 2300.0 + rng.nextDouble() * 700.0
            if let freeIdx = findFreeVoice() {
                voices[freeIdx].trigger(
                    startFreq: pitch,
                    endFreq: pitch - 500.0,
                    duration: 0.4,
                    volume: baseVolume * 1.1,
                    vibratoFreq: 22.0,
                    vibratoDepth: 120.0,
                    delay: 0.0
                )
            }
            
        case 2: // Harmonized Chime Bells (minor third)
            let pitch = 3300.0 + rng.nextDouble() * 600.0
            if let freeIdx1 = findFreeVoice() {
                voices[freeIdx1].trigger(
                    startFreq: pitch,
                    endFreq: pitch - 150.0,
                    duration: 0.55,
                    volume: baseVolume * 0.75,
                    vibratoFreq: 0.0,
                    vibratoDepth: 0.0,
                    delay: 0.0
                )
            }
            if let freeIdx2 = findFreeVoice() {
                voices[freeIdx2].trigger(
                    startFreq: pitch * 1.189, // Minor third
                    endFreq: (pitch - 150.0) * 1.189,
                    duration: 0.45,
                    volume: baseVolume * 0.45,
                    vibratoFreq: 0.0,
                    vibratoDepth: 0.0,
                    delay: 0.04
                )
            }
            
        case 3: // Interlocking call-response whistles
            let pitch = 2100.0 + rng.nextDouble() * 300.0
            if let freeIdx1 = findFreeVoice() {
                voices[freeIdx1].trigger(
                    startFreq: pitch,
                    endFreq: pitch + 200.0,
                    duration: 0.28,
                    volume: baseVolume * 0.8,
                    vibratoFreq: 8.0,
                    vibratoDepth: 30.0,
                    delay: 0.0
                )
            }
            if let freeIdx2 = findFreeVoice() {
                voices[freeIdx2].trigger(
                    startFreq: pitch + 400.0,
                    endFreq: pitch + 300.0,
                    duration: 0.32,
                    volume: baseVolume * 0.7,
                    vibratoFreq: 9.0,
                    vibratoDepth: 35.0,
                    delay: 0.35
                )
            }
            
        default:
            break
        }
    }
    
    private func findFreeVoice() -> Int? {
        for idx in 0..<voices.count {
            if !voices[idx].isActive {
                return idx
            }
        }
        return nil
    }
}

// ==========================================
// MARK: - PROCEDURAL INTERACTIVE TAP SYSTEM
// ==========================================

/// Synthesizer voice for interactive taps. Features physical modeling / FM parameters.
struct TapVoice {
    var isActive: Bool = false
    var phase: Double = 0.0
    var modPhase: Double = 0.0
    private var noiseGen = LCG(seed: 98765)
    private var noiseFilter = BiquadFilter()
    
    var carrierFreq: Double = 0.0
    var modFreq: Double = 0.0
    var modIndex: Double = 0.0
    var decayRate: Double = 0.0
    var amplitude: Double = 0.0
    var noiseMix: Double = 0.0
    var pitchSweepRate: Double = 0.0
    
    var panLeft: Float = 0.5
    var panRight: Float = 0.5
    
    mutating func trigger(
        carrier: Double,
        mod: Double,
        index: Double,
        duration: Double,
        amp: Double,
        noise: Double = 0.0,
        pitchSweep: Double = 0.0,
        pan: Float = 0.0
    ) {
        self.phase = 0.0
        self.modPhase = 0.0
        self.carrierFreq = carrier
        self.modFreq = mod
        self.modIndex = index
        let totalSamples = duration * 44100.0
        self.decayRate = amp / totalSamples
        self.amplitude = amp
        self.noiseMix = noise
        self.pitchSweepRate = pitchSweep / totalSamples
        
        // Equal-power panning calculation
        let normalizedPan = max(-1.0, min(1.0, pan))
        self.panLeft = sqrt((1.0 - normalizedPan) / 2.0)
        self.panRight = sqrt((1.0 + normalizedPan) / 2.0)
        
        noiseFilter.updateBandpass(cutoff: carrier * 1.4, q: 2.2, sampleRate: 44100.0)
        self.isActive = true
    }
    
    mutating func next(left: inout Double, right: inout Double) {
        guard isActive else { return }
        
        // FM modulator calculation
        var fmOffset = 0.0
        if modFreq > 0.0 && modIndex > 0.0 {
            fmOffset = sin(modPhase) * modIndex * modFreq
            modPhase += 2.0 * .pi * modFreq / 44100.0
            if modPhase >= 2.0 * .pi {
                modPhase -= 2.0 * .pi
            }
        }
        
        let freq = max(30.0, carrierFreq + fmOffset)
        let sineSample = sin(phase)
        phase += 2.0 * .pi * freq / 44100.0
        if phase >= 2.0 * .pi {
            phase -= 2.0 * .pi
        }
        
        // Add mallet strike / noise component
        let whiteNoise = noiseMix > 0.0 ? (noiseGen.nextDouble() * 2.0 - 1.0) : 0.0
        let filteredNoise = noiseMix > 0.0 ? noiseFilter.process(whiteNoise) : 0.0
        
        let sample = (sineSample * (1.0 - noiseMix) + filteredNoise * noiseMix) * amplitude
        
        // Sweep pitch
        carrierFreq += pitchSweepRate
        
        // Decay amplitude linear envelope
        amplitude -= decayRate
        if amplitude <= 0.0 {
            amplitude = 0.0
            isActive = false
        }
        
        left += sample * Double(panLeft)
        right += sample * Double(panRight)
    }
}

/// Interactive taps manager supporting polyphony and role-specific presets.
struct DSPTapSynthesizer {
    var voices = Array(repeating: TapVoice(), count: 12)
    
    mutating func triggerTap(role: HasanaGardenVisualRole, pan: Float, volume: Double) {
        guard let idx = findFreeVoice() else { return }
        
        switch role {
        case .foundationalTree:
            // Low, warm woodblock mallet sound
            voices[idx].trigger(
                carrier: 175.0,
                mod: 262.5, // 1.5 ratio
                index: 0.38,
                duration: 0.20,
                amp: 0.85 * volume,
                noise: 0.16,
                pitchSweep: -15.0,
                pan: pan
            )
        case .plant:
            // Fast water droplet pluck
            voices[idx].trigger(
                carrier: 880.0,
                mod: 0.0,
                index: 0.0,
                duration: 0.09,
                amp: 0.62 * volume,
                noise: 0.06,
                pitchSweep: -580.0,
                pan: pan
            )
        case .flower:
            // Sweet metallic chime bell
            voices[idx].trigger(
                carrier: 1400.0,
                mod: 2275.0, // minor chord relationship (1.625 ratio)
                index: 1.25,
                duration: 0.85,
                amp: 0.58 * volume,
                noise: 0.015,
                pitchSweep: -70.0,
                pan: pan
            )
        }
    }
    
    private func findFreeVoice() -> Int? {
        for idx in 0..<voices.count {
            if !voices[idx].isActive {
                return idx
            }
        }
        return nil
    }
    
    mutating func process(left: inout Double, right: inout Double) {
        for idx in 0..<voices.count {
            voices[idx].next(left: &left, right: &right)
        }
    }
}

// ==========================================
// MARK: - SOUND DAMPENING & ENV MODELING
// ==========================================

/// Internal state configuration of the garden audio environment.
struct HasanaGardenAudioEnvironmentState: Equatable {
    var timeOfDay: Double = 0.5 // 0.0 to 1.0 (midnight to noon to midnight)
    var dormancyRatio: Double = 0.0 // 0.0 to 1.0 (uncared for plants ratio)
    var wetness: Double = 0.0 // 0.0 to 1.0 (recent tending)
    var windSpeed: Double = 0.5 // 0.0 to 1.0 (current wind velocity)
    var cameraDistance: Double = 5.0 // distance to plants
    var cameraYaw: Float = 0.0 // rotation around plants
}

/// Evaluates high-level garden states and outputs specific physical parameters.
struct DSPSoundDampeningModel {
    struct Output {
        let dampeningFactor: Double // 0.0 (clean) to 1.0 (fully muffled)
        let windVolume: Double
        let birdRate: Double
        let birdVolume: Double
        let reverbMix: Float
        let eqLowGain: Float
        let eqHighGain: Float
        let isNight: Bool
    }
    
    func evaluate(env: HasanaGardenAudioEnvironmentState) -> Output {
        let isNight = env.timeOfDay < 0.22 || env.timeOfDay > 0.78
        let timeFactor = isNight ? 0.15 : 1.0
        
        // Calculate dynamic high-frequency dampening factor
        let baseDamp = env.dormancyRatio * 0.78
        let wetnessDampFactor = env.wetness * 0.32
        let dampeningFactor = max(0.0, min(1.0, baseDamp - wetnessDampFactor))
        
        // Wind sounds
        let windVolume = (0.2 + (1.0 - env.dormancyRatio) * 0.8) * (0.35 + env.windSpeed * 0.65)
        
        // Birds activity (no birds in dark or dormant garden)
        let birdRate = (1.0 - env.dormancyRatio) * timeFactor * (0.35 + env.wetness * 0.65)
        let birdVolume = (1.0 - env.dormancyRatio) * (isNight ? 0.03 : 0.8)
        
        // Reverb density based on wetness/distance
        let distFactor = Float((env.cameraDistance - 3.8) / 5.4)
        let baseReverb = Float(14.0 + env.wetness * 22.0)
        let reverbMix = baseReverb + distFactor * 26.0
        
        // EQ Gains
        let eqLowGain = Float(env.dormancyRatio * 3.0) // Boost muddy low end
        let eqHighGain = Float(-dampeningFactor * 13.5) // Muffle/filter highs
        
        return Output(
            dampeningFactor: dampeningFactor,
            windVolume: windVolume,
            birdRate: birdRate,
            birdVolume: birdVolume,
            reverbMix: max(0.0, min(80.0, reverbMix)),
            eqLowGain: eqLowGain,
            eqHighGain: eqHighGain,
            isNight: isNight
        )
    }
}

// ==========================================
// MARK: - AUDIO SYSTEM MANAGER CLASS
// ==========================================

/// Local container wrapping mutable DSP objects. Captured by reference by the render closure.
/// All variables inside are read and written strictly on the audio render thread.
private final class RealtimeDSPContainer: @unchecked Sendable {
    var windGen = WindFoliageSynthesizer()
    var birdSynth = DSPBirdSynthesizer()
    var tapSynth = DSPTapSynthesizer()
    
    // Smoothed values to avoid audio clicks
    var currentMuteVolume: Double = 0.0
    var currentWindSpeed: Double = 0.5
    var currentDampening: Double = 0.0
    var currentBirdRate: Double = 0.5
    var currentBirdVolume: Double = 0.5
    var currentCamDistance: Double = 5.0
    var currentMasterVolume: Double = 0.8
}

/// Command queue element for tap triggers.
struct TapTriggerCommand: Sendable {
    let role: HasanaGardenVisualRole
    let pan: Float
    let volume: Double
}

@Observable
@MainActor
final class HasanaGardenAudioSystem {
    static let shared = HasanaGardenAudioSystem()
    
    // UI bindable states
    var isMuted: Bool = true {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "hasana.garden.audio.muted")
            updateMuteState()
        }
    }
    
    var masterVolume: Float = 0.8 {
        didSet {
            UserDefaults.standard.set(masterVolume, forKey: "hasana.garden.audio.masterVolume")
            lock.sync {
                sharedState.masterVolume = Double(masterVolume)
            }
        }
    }
    
    private(set) var isPlaying: Bool = false
    
    // Internal AV graph properties
    private let engine = AVAudioEngine()
    private let reverbNode = AVAudioUnitReverb()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 2)
    private var sourceNode: AVAudioSourceNode?
    
    // State sharing
    private let lock = UnfairLock()
    private struct SharedState {
        var windSpeed: Double = 0.5
        var dampeningFactor: Double = 0.0
        var birdRate: Double = 0.5
        var birdVolume: Double = 0.5
        var cameraDistance: Double = 5.0
        var masterVolume: Double = 0.8
        var targetMuteVolume: Double = 0.0
        var currentMuteVolume: Double = 0.0
        var pendingTaps: [TapTriggerCommand] = []
    }
    private var sharedState = SharedState()
    
    // Env properties
    private var currentEnvironment = HasanaGardenAudioEnvironmentState()
    private let dampeningModel = DSPSoundDampeningModel()
    
    private var isInitialized = false
    private var subscriptions = Set<AnyCancellable>()
    private var wasPlayingBeforeBackground = false
    
    private init() {
        // Read defaults
        self.isMuted = UserDefaults.standard.bool(forKey: "hasana.garden.audio.muted")
        if UserDefaults.standard.object(forKey: "hasana.garden.audio.muted") == nil {
            self.isMuted = true
        }
        
        let savedVol = UserDefaults.standard.float(forKey: "hasana.garden.audio.masterVolume")
        self.masterVolume = savedVol > 0.0 ? savedVol : 0.8
        
        lock.sync {
            sharedState.masterVolume = Double(self.masterVolume)
            sharedState.targetMuteVolume = self.isMuted ? 0.0 : 1.0
            sharedState.currentMuteVolume = self.isMuted ? 0.0 : 1.0
        }
        
        setupNotifications()
    }
    
    deinit {}
    
    func start() {
        guard !isPlaying else { return }
        
        setupAudioPipeline()
        
        do {
            try configureAudioSession()
            if !engine.isRunning {
                try engine.start()
            }
            isPlaying = true
            updateMuteState()
            print("🔊 HasanaGardenAudioSystem engine successfully started.")
        } catch {
            print("❌ Failed to start HasanaGardenAudioSystem: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        guard isPlaying else { return }
        
        // Fade out volume smoothly to prevent popping clicks
        lock.sync {
            sharedState.targetMuteVolume = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
            guard let self = self else { return }
            self.lock.sync {
                if self.sharedState.targetMuteVolume == 0.0 {
                    self.engine.pause()
                    self.isPlaying = false
                }
            }
        }
    }
    
    func triggerTap(for practiceID: HasanaGardenPracticeID, displayState: HasanaGardenDisplayState) {
        guard let practiceState = displayState.practices.first(where: { $0.practice.id == practiceID }) else { return }
        let practice = practiceState.practice
        
        // Stereo panning calculated from relative position bounds (-350 to +350)
        let pan = Float(practice.defaultPosition.x) / 320.0
        let role = practice.visualRole
        
        let cmd = TapTriggerCommand(role: role, pan: pan, volume: 1.0)
        lock.sync {
            sharedState.pendingTaps.append(cmd)
        }
    }
    
    func triggerGenericTap(pan: Float = 0.0, volume: Double = 0.4) {
        let cmd = TapTriggerCommand(role: .plant, pan: pan, volume: volume)
        lock.sync {
            sharedState.pendingTaps.append(cmd)
        }
    }
    
    func updateEnvironment(timeOfDay: Double, dormancyRatio: Double, wetness: Double, windSpeed: Double = 0.5) {
        lock.sync {
            currentEnvironment.timeOfDay = timeOfDay
            currentEnvironment.dormancyRatio = dormancyRatio
            currentEnvironment.wetness = wetness
            currentEnvironment.windSpeed = windSpeed
            
            applyEnvironmentState_unlocked()
        }
    }
    
    func updateCamera(distance: Float, yaw: Float) {
        lock.sync {
            currentEnvironment.cameraDistance = Double(distance)
            currentEnvironment.cameraYaw = yaw
            sharedState.cameraDistance = Double(distance)
        }
    }
    
    func connectToStore(_ store: HasanaGardenStore) {
        let displayState = store.displayState
        let totalCount = displayState.practices.count
        guard totalCount > 0 else { return }
        
        let dormantCount = displayState.practices.filter(\.isDormant).count
        let dormancyRatio = Double(dormantCount) / Double(totalCount)
        let tendedCount = displayState.tendedTodayCount
        let wetness = Double(tendedCount) / Double(totalCount)
        
        // Calculate system clock time fraction
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        let timeOfDay = (Double(hour) + Double(minute) / 60.0) / 24.0
        
        // Wind speed is slightly higher if garden is lush and tended
        let windSpeed = 0.35 + (Double(tendedCount) / Double(totalCount)) * 0.45
        
        updateEnvironment(
            timeOfDay: timeOfDay,
            dormancyRatio: dormancyRatio,
            wetness: wetness,
            windSpeed: windSpeed
        )
    }
    
    // MARK: - Private Pipeline Config
    
    private func setupAudioPipeline() {
        guard !isInitialized else { return }
        
        let dsp = RealtimeDSPContainer()
        
        sourceNode = AVAudioSourceNode { [weak self] (isSilence, timestamp, frameCount, outputData) -> OSStatus in
            guard let self = self else { return noErr }
            
            var windSpeed = 0.5
            var dampeningFactor = 0.0
            var birdRate = 0.5
            var birdVolume = 0.5
            var cameraDistance = 5.0
            var masterVolume = 0.8
            var targetMuteVolume = 0.0
            var pendingTaps: [TapTriggerCommand] = []
            
            self.lock.sync {
                windSpeed = self.sharedState.windSpeed
                dampeningFactor = self.sharedState.dampeningFactor
                birdRate = self.sharedState.birdRate
                birdVolume = self.sharedState.birdVolume
                cameraDistance = self.sharedState.cameraDistance
                masterVolume = self.sharedState.masterVolume
                targetMuteVolume = self.sharedState.targetMuteVolume
                
                if !self.sharedState.pendingTaps.isEmpty {
                    pendingTaps = self.sharedState.pendingTaps
                    self.sharedState.pendingTaps.removeAll()
                }
            }
            
            // Handle any tap triggers queued
            for tap in pendingTaps {
                dsp.tapSynth.triggerTap(role: tap.role, pan: tap.pan, volume: tap.volume)
            }
            
            let abl = UnsafeMutableAudioBufferListPointer(outputData)
            guard abl.count > 0,
                  let leftBuffer = abl[0].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            let rightBuffer = abl.count > 1 ? abl[1].mData?.assumingMemoryBound(to: Float.self) : nil
            
            // Loop samples
            for frame in 0..<Int(frameCount) {
                // One-pole smoothing to prevent pops
                let k = 0.0006
                dsp.currentMuteVolume += k * (targetMuteVolume - dsp.currentMuteVolume)
                dsp.currentWindSpeed += k * (windSpeed - dsp.currentWindSpeed)
                dsp.currentDampening += k * (dampeningFactor - dsp.currentDampening)
                dsp.currentBirdRate += k * (birdRate - dsp.currentBirdRate)
                dsp.currentBirdVolume += k * (birdVolume - dsp.currentBirdVolume)
                dsp.currentCamDistance += k * (cameraDistance - dsp.currentCamDistance)
                dsp.currentMasterVolume += k * (masterVolume - dsp.currentMasterVolume)
                
                let effectiveMuteVolume = dsp.currentMuteVolume
                
                if effectiveMuteVolume <= 0.0001 && targetMuteVolume == 0.0 {
                    leftBuffer[frame] = 0.0
                    rightBuffer?[frame] = 0.0
                    continue
                }
                
                // Wind & rustling leaves
                let ambientSample = dsp.windGen.next(
                    windSpeed: dsp.currentWindSpeed,
                    dampeningFactor: dsp.currentDampening
                )
                
                // Birds
                let birdSample = dsp.birdSynth.process(
                    birdActivity: dsp.currentBirdRate,
                    dampeningFactor: dsp.currentDampening
                ) * dsp.currentBirdVolume
                
                var left = ambientSample + birdSample
                var right = ambientSample + birdSample
                
                // Taps
                var tapLeft = 0.0
                var tapRight = 0.0
                dsp.tapSynth.process(left: &tapLeft, right: &tapRight)
                
                left += tapLeft
                right += tapRight
                
                // Inverse-distance attenuation
                let distanceScale = max(1.0, (dsp.currentCamDistance - 2.2) / 3.2)
                let distAtten = 1.0 / distanceScale
                
                let finalGain = distAtten * dsp.currentMasterVolume * effectiveMuteVolume
                
                leftBuffer[frame] = Float(left * finalGain)
                if let rightBuffer {
                    rightBuffer[frame] = Float(right * finalGain)
                }
            }
            
            return noErr
        }
        
        reverbNode.loadFactoryPreset(.mediumChamber)
        reverbNode.wetDryMix = 25.0
        
        // Setup parametric EQ
        // Band 0: Low Shelf
        let lowBand = eqNode.bands[0]
        lowBand.filterType = .lowShelf
        lowBand.frequency = 190.0
        lowBand.bypass = false
        lowBand.gain = 0.0
        
        // Band 1: High Shelf
        let highBand = eqNode.bands[1]
        highBand.filterType = .highShelf
        highBand.frequency = 5800.0
        highBand.bypass = false
        highBand.gain = 0.0
        
        engine.attach(sourceNode!)
        engine.attach(reverbNode)
        engine.attach(eqNode)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
        engine.connect(sourceNode!, to: reverbNode, format: format)
        engine.connect(reverbNode, to: eqNode, format: format)
        engine.connect(eqNode, to: engine.mainMixerNode, format: format)
        
        engine.prepare()
        isInitialized = true
    }
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.ambient, mode: .default, options: [])
        try session.setActive(true)
    }
    
    private func updateMuteState() {
        lock.sync {
            sharedState.targetMuteVolume = isMuted ? 0.0 : 1.0
        }
        if !isMuted && isPlaying {
            do {
                try configureAudioSession()
                if !engine.isRunning {
                    try engine.start()
                }
            } catch {
                print("❌ Failed to start audio engine: \(error)")
            }
        }
    }
    
    private func applyEnvironmentState_unlocked() {
        let output = dampeningModel.evaluate(env: currentEnvironment)
        
        sharedState.windSpeed = currentEnvironment.windSpeed * output.windVolume
        sharedState.dampeningFactor = output.dampeningFactor
        sharedState.birdRate = output.birdRate
        sharedState.birdVolume = output.birdVolume
        
        let reverbMix = output.reverbMix
        let eqLow = output.eqLowGain
        let eqHigh = output.eqHighGain
        
        Task { @MainActor in
            self.reverbNode.wetDryMix = reverbMix
            self.eqNode.bands[0].gain = eqLow
            self.eqNode.bands[1].gain = eqHigh
        }
    }
    
    // MARK: - Notifications / Interruptions
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleWillResignActive()
            }
            .store(in: &subscriptions)
            
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleDidBecomeActive()
            }
            .store(in: &subscriptions)
            
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleInterruption(notification: notification)
            }
            .store(in: &subscriptions)
    }
    
    private func handleWillResignActive() {
        lock.sync {
            wasPlayingBeforeBackground = isPlaying
        }
        if isPlaying {
            lock.sync {
                sharedState.targetMuteVolume = 0.0
            }
            // Give it 150ms to fade out, then pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                self.lock.sync {
                    if self.sharedState.targetMuteVolume == 0.0 {
                        self.engine.pause()
                        try? AVAudioSession.sharedInstance().setActive(false)
                    }
                }
            }
        }
    }
    
    private func handleDidBecomeActive() {
        let shouldResume = lock.sync { wasPlayingBeforeBackground }
        if shouldResume {
            do {
                try configureAudioSession()
                if !engine.isRunning {
                    try engine.start()
                }
                lock.sync {
                    sharedState.targetMuteVolume = isMuted ? 0.0 : 1.0
                }
            } catch {
                print("❌ Failed to resume audio on active: \(error)")
            }
        }
    }
    
    private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeVal) else {
            return
        }
        
        switch type {
        case .began:
            lock.sync {
                wasPlayingBeforeBackground = isPlaying
            }
            engine.pause()
        case .ended:
            guard let optionsVal = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsVal)
            if options.contains(.shouldResume) {
                let shouldResume = lock.sync { wasPlayingBeforeBackground }
                if shouldResume {
                    try? configureAudioSession()
                    try? engine.start()
                }
            }
        @unknown default:
            break
        }
    }
}

// ==========================================
// MARK: - DEVELOPER TEST INSTRUMENT VIEW
// ==========================================

/// Interactive SwiftUI testing dashboard for developing and tuning the soundscape engine.
struct HasanaGardenAudioDashboard: View {
    @State private var timeOfDay: Double = 0.5
    @State private var dormancyRatio: Double = 0.0
    @State private var wetness: Double = 0.5
    @State private var windSpeed: Double = 0.5
    @State private var cameraDistance: Double = 5.0
    @State private var system = HasanaGardenAudioSystem.shared
    
    init() {}
    
    var body: some View {
        Form {
            Section(header: Text("Audio Engine Controls")) {
                Toggle("Muted (Mute Switch Helper)", isOn: Bindable(system).isMuted)
                
                HStack {
                    Text("Master Volume")
                    Spacer()
                    Slider(value: Bindable(system).masterVolume, in: 0.0...1.0)
                        .frame(width: 150)
                }
                
                HStack {
                    Text("Status:")
                    Spacer()
                    Text(system.isPlaying ? "PLAYING" : "STOPPED")
                        .foregroundColor(system.isPlaying ? .green : .red)
                        .bold()
                }
                
                Button(action: {
                    if system.isPlaying {
                        system.stop()
                    } else {
                        system.start()
                    }
                }) {
                    Text(system.isPlaying ? "Stop Audio System" : "Start Audio System")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Section(header: Text("Simulation Parameters")) {
                VStack(alignment: .leading) {
                    Text("Time of Day: \(String(format: "%.2f", timeOfDay))")
                    Slider(value: $timeOfDay, in: 0.0...1.0)
                }
                
                VStack(alignment: .leading) {
                    Text("Dormancy Ratio (Plant Dryness): \(String(format: "%.2f", dormancyRatio))")
                    Slider(value: $dormancyRatio, in: 0.0...1.0)
                }
                
                VStack(alignment: .leading) {
                    Text("Wetness (Tended today): \(String(format: "%.2f", wetness))")
                    Slider(value: $wetness, in: 0.0...1.0)
                }
                
                VStack(alignment: .leading) {
                    Text("Wind Speed: \(String(format: "%.2f", windSpeed))")
                    Slider(value: $windSpeed, in: 0.0...1.0)
                }
                
                VStack(alignment: .leading) {
                    Text("Camera Distance: \(String(format: "%.1fm", cameraDistance))")
                    Slider(value: $cameraDistance, in: 3.8...9.2)
                }
            }
            .onChange(of: timeOfDay) { updateEnv() }
            .onChange(of: dormancyRatio) { updateEnv() }
            .onChange(of: wetness) { updateEnv() }
            .onChange(of: windSpeed) { updateEnv() }
            .onChange(of: cameraDistance) {
                system.updateCamera(distance: Float(cameraDistance), yaw: 0.0)
            }
            
            Section(header: Text("Manual Tap Triggers")) {
                HStack {
                    Button("Tree Tap") {
                        system.triggerGenericTap(pan: -0.6, volume: 1.0)
                        system.triggerTap(for: .fajr, displayState: mockDisplayState())
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Plant Tap") {
                        system.triggerGenericTap(pan: 0.0, volume: 0.8)
                        system.triggerTap(for: .quran, displayState: mockDisplayState())
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Flower Tap") {
                        system.triggerGenericTap(pan: 0.6, volume: 0.8)
                        system.triggerTap(for: .adhkar, displayState: mockDisplayState())
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Garden Audio Debug")
        .onAppear {
            system.start()
            updateEnv()
        }
    }
    
    private func updateEnv() {
        system.updateEnvironment(
            timeOfDay: timeOfDay,
            dormancyRatio: dormancyRatio,
            wetness: wetness,
            windSpeed: windSpeed
        )
    }
    
    private func mockDisplayState() -> HasanaGardenDisplayState {
        let states = HasanaGardenPractice.defaults.map { practice in
            HasanaGardenPracticeState(
                practice: practice,
                progress: HasanaGardenProgress(practiceID: practice.id),
                isTendedToday: true,
                isDormant: false
            )
        }
        return HasanaGardenDisplayState(
            practices: states,
            tendedTodayCount: 8,
            totalTendedDays: 100
        )
    }
}
