import OnnxRuntimeBindings

public struct SileroVAD {
    private let session: ORTSession
    private var context = [Float](repeating: 0.0, count: 0)
    private var lastSampleRate: Int = 0

    public init() throws {
        let modelPath = Bundle.module.url(forResource: "silero_vad", withExtension: "onnx")!.path
        let env = try ORTEnv(loggingLevel: .error)
        let options = try ORTSessionOptions()
        try options.setLogSeverityLevel(.error)
        try options.setIntraOpNumThreads(1)
        let coreMLOptions = ORTCoreMLExecutionProviderOptions()
        coreMLOptions.enableOnSubgraphs = true
        try options.appendCoreMLExecutionProvider(with: coreMLOptions)
        session = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
    }

    public mutating func resetStates() {
        context = []
        lastSampleRate = 0
    }

    public mutating func run(bytes: [Float], sampleRate: Int = 16000) throws -> Float {
        enum Error: Swift.Error, Codable, Sendable { case invalidSampleRate }
        guard sampleRate == 16000 || sampleRate == 8000 else {
            throw Error.invalidSampleRate
        }

        let contextSize = sampleRate == 16000 ? 64 : 32
        if lastSampleRate != sampleRate {
            resetStates()
        }

        if context.isEmpty {
            context = [Float](repeating: 0.0, count: contextSize)
        }

        let input = context + bytes
        let inputTensor = try ORTValue(
            tensorData: NSMutableData(data: Data(bytes: input, count: input.count * MemoryLayout<Float>.stride)),
            elementType: .float,
            shape: [1, NSNumber(value: input.count)]
        )

        // NB: no idea what `state` is supposed to be but everything i've tried leaves it all 0s after every run so not bothering with it anymore
        let state = [Float](repeating: 0.0, count: 2 * 128)
        let stateTensorData = NSMutableData(data: Data(bytes: state, count: state.count * MemoryLayout<Float>.stride))
        let stateTensor = try ORTValue(
            tensorData: stateTensorData,
            elementType: .float,
            shape: [2, 1, 128]
        )

        let srTensor = try ORTValue(
            tensorData: NSMutableData(data: Data(bytes: [sampleRate], count: MemoryLayout<Int>.stride)),
            elementType: .int64,
            shape: []
        )

        let inputs: [String: ORTValue] = [
            "input": inputTensor,
            "state": stateTensor,
            "sr": srTensor,
        ]

        let outputs: [String: ORTValue] = try session.run(withInputs: inputs, outputNames: ["output"], runOptions: nil)

        context = Array(input.suffix(contextSize))
        lastSampleRate = sampleRate

        let outputTensor = outputs["output"]!
        let outputData = try outputTensor.tensorData() as Data
        let output = outputData.withUnsafeBytes {
            Array(UnsafeBufferPointer<Float>(
                start: $0.baseAddress!.assumingMemoryBound(to: Float.self),
                count: outputData.count / MemoryLayout<Float>.stride
            ))
        }
        return output.first ?? 0
    }
}
