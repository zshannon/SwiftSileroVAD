//
//  ViewModel.swift
//
//
//  Created by Zane Shannon on 9/7/24.
//

import AudioKit
import AudioKitEX
import AVFAudio
import Combine
import Foundation
import SwiftSileroVAD

actor ViewModel {
    private var vad: SileroVAD
    private let engine: AudioEngine
    private let mixer: Mixer
    private let rawQ = DispatchQueue(
        label: ["microphone.raw-stream"]
            .joined(separator: "."),
        qos: .userInitiated
    )
    private let rawStream$ = PassthroughSubject<[Float], Never>()
    private var tap: RawDataTap?

    init() {
        vad = try! .init()
        Settings.audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 2,
            interleaved: false
        )!
        engine = AudioEngine()
        mixer = Mixer()
        guard let input = engine.input else { return }
        // setup filters based on
        // https://medium.com/@emt.joshhart/how-to-reduce-noise-while-recording-with-audiokit-in-swift-d286f6df45f
        // migration guide: https://www.audiokit.io/AudioKit/documentation/audiokit/migrationguide
        let filters: [(Node) -> Node] = [
            { Fader($0, gain: 0) },
            { PeakLimiter($0) },
//            { EqualizerFilter($0, centerFrequency: 1000, bandwidth: 200, gain: -6) },
            { DynamicsProcessor($0) },
        ]
        let filteredInput: Node = filters.reduce(input) { input, next in
            next(input)
        }
        mixer.addInput(filteredInput)
        engine.output = mixer
        let bufferSize = Int(48000 / 1000) * 30 // 30ms
        guard bufferSize > 0 else { fatalError("invalid buffer size") }
        tap = .init(input, bufferSize: UInt32(bufferSize),
                    callbackQueue: rawQ)
        { [stream$ = self.rawStream$] data in
            stream$.send(data)
        }
    }

    func startListening() -> AsyncThrowingStream<([Float], Float), Error> {
        .init { continuation in
            Task {
                try engine.start()
                tap?.start()
                for await data in rawStream$.values {
                    guard let bytes = convertTo16kHzWAV(inputAudio: data) else { continue }
                    let confidence = ((try? self.vad.run(bytes: bytes)) ?? 0)
                    continuation.yield((bytes, confidence))
                }
            }
        }
    }

    private nonisolated func convertTo16kHzWAV(inputAudio: [Float]) -> [Float]? {
        guard let audioInputNode = engine.input else { return nil }
        let inputFormat = audioInputNode.outputFormat
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: inputFormat,
            frameCapacity: AVAudioFrameCount(inputAudio.count)
        ) else {
            return nil
        }
        inputBuffer.frameLength = AVAudioFrameCount(inputAudio.count)
        let audioBuffer = inputBuffer.floatChannelData?[0]
        for i in 0 ..< inputAudio.count {
            audioBuffer?[i] = inputAudio[i]
        }
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000.0,
            channels: 1,
            interleaved: false
        )!
        guard let resampledPCMBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: AVAudioFrameCount(Double(inputAudio.count) *
                Double(16000.0 / inputFormat.sampleRate))
        ) else {
            return nil
        }
        let resampler = AVAudioConverter(from: inputFormat, to: outputFormat)
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return inputBuffer
        }
        var error: NSError?
        let status = resampler?.convert(
            to: resampledPCMBuffer,
            error: &error,
            withInputFrom: inputBlock
        )
        if status != .error {
            let resampledAudio = Array(UnsafeBufferPointer(
                start: resampledPCMBuffer.int16ChannelData?[0],
                count: Int(resampledPCMBuffer.frameLength)
            ))
            var int16Audio: [Float] = []
            for sample in resampledAudio {
                let int16Value = max(-1.0, min(Float(sample) / 32767.0, 1.0))
                int16Audio.append(int16Value)
            }
            return int16Audio
        } else {
            print("Error during resampling: \(error?.localizedDescription ?? "Unknown error")")
            return nil
        }
    }
}
