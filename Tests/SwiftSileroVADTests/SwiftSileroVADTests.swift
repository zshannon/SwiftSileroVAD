import AVFoundation
@testable import SwiftSileroVAD
import XCTest

final class SwiftSileroVADTests: XCTestCase {
    func testInit() throws {
        XCTAssertNoThrow(try SileroVAD())
    }

    func testJFKSpeech() throws {
        var vad = try SileroVAD()
        let jfkAudio = Bundle.module.url(forResource: "jfk", withExtension: "wav")
        let floats = try readAudioFile(url: jfkAudio!)
        XCTAssertEqual(176_000, floats.count)
        let probabilities = try stride(from: 0, to: floats.count, by: 512)
            .map { try vad.run(bytes: Array(floats[$0 ..< Swift.min(
                $0 + 512,
                floats.count
            )])) }
        XCTAssertEqual(probabilities.count, 344)
        XCTAssertEqual(probabilities[0], 0.012012929)
        XCTAssertEqual(probabilities[100], 0.066182435)
        XCTAssertEqual(probabilities[200], 0.91776323)
        XCTAssertEqual(probabilities[300], 0.6470929)
        XCTAssertEqual(probabilities[343], 0.57817054)
    }

    private func readAudioFile(url: URL) throws -> [Float] {
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
}
