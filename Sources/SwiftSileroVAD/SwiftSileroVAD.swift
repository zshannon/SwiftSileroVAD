
import OnnxRuntimeBindings

struct SileroVAD {
    private let session: ORTSession

    init() throws {
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
}
