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

    var body: some View {
        if #available(macOS 13.0, *) {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)

                Text(isSpeech ? "Speaking" : "Not Speaking")

                Chart {
                    ForEach(Array(confidenceValues.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Confidence", value)
                        )
                    }
                }
                .frame(height: 200)
            }
            .padding()
            .task {
                do {
                    for try await (_, confidence) in await model.startListening() {
                        confidenceValues.append(confidence)
                        isSpeech = confidence > 0.5
                    }
                } catch {}
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
