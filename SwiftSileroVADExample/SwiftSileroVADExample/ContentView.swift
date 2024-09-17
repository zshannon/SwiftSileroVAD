//
//  ContentView.swift
//  SwiftSileroVADExample
//
//  Created by Zane Shannon on 9/7/24.
//

import Charts
import SwiftSileroVAD
import SwiftUI

struct ContentView: View {
    private var model: ViewModel = .init()
    @State private var isSpeech = false
    @State private var confidenceValues: [Float] = []
    @State private var minConfidenceForVoice: Float = 0.4
    @State private var msWindow: Double = 10
    @State private var lastSpeechTime: Date?

    var body: some View {
        if #available(macOS 13.0, *) {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)

                Text(isSpeech ? "Speaking" : "Not Speaking")

                Chart {
                    ForEach(Array(confidenceValues.enumerated()), id: \.offset) { index, value in
                        if value >= minConfidenceForVoice {
                            RectangleMark(
                                xStart: .value("Index", index),
                                xEnd: .value("Index", index + 1),
                                yStart: .value("Confidence", minConfidenceForVoice),
                                yEnd: .value("Confidence", value)
                            )
                            .foregroundStyle(.green)
                        }
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Confidence", value)
                        )
                    }
                }
                .frame(height: 200)
                HStack {
                    Text("Min Confidence: \(minConfidenceForVoice, specifier: "%.2f")")
                    Slider(value: $minConfidenceForVoice, in: 0 ... 1)
                        .padding()
                }
                HStack {
                    Text("MS Window: \(Int(msWindow)) ms")
                    Slider(value: $msWindow, in: 0 ... 200, step: 5)
                        .padding()
                }
            }
            .padding()
            .task {
                do {
                    for try await (_, confidence) in await model.startListening() {
                        let now = Date()
                        if confidenceValues.count > 500 { confidenceValues.removeAll(keepingCapacity: true) }
                        if confidence >= minConfidenceForVoice {
                            lastSpeechTime = now
                            confidenceValues.append(confidence)
                            isSpeech = true
                        } else if let lastSpeechTime = lastSpeechTime,
                                  now.timeIntervalSince(lastSpeechTime) < (msWindow / 1000.0)
                        {
                            confidenceValues.append(minConfidenceForVoice)
                        } else {
                            isSpeech = false
                            confidenceValues.append(confidence)
                        }
                    }
                } catch {
                    // Handle error
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
