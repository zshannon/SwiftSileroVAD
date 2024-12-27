//
//  Utils.swift
//  SileroVAD
//
//  Created by Zane Shannon on 12/22/24.
//

import AVFoundation

func readAudioFile(url: URL) throws -> [Float] {
    enum Error: Swift.Error, Codable, Sendable { case failedToOpenFile, failedToCreatePCMBuffer, failedToReadFile }
    guard let file = try? AVAudioFile(forReading: url) else {
        throw Error.failedToOpenFile
    }
    let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: file.fileFormat.sampleRate,
        channels: 1,
        interleaved: false
    )
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length)) else {
        throw Error.failedToCreatePCMBuffer
    }
    do {
        try file.read(into: buffer)
    } catch {
        throw Error.failedToReadFile
    }
    let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count: Int(buffer.frameLength)))
    return floatArray
}
