@testable import SileroVAD
import XCTest

final class SileroVADTests: XCTestCase {
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
}
