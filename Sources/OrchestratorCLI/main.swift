import Darwin
import Foundation
import OrchestratorCore

@main
struct OrchestratorCommand {
    static func main() async {
        do {
            try await run(Array(CommandLine.arguments.dropFirst()))
        } catch let error as CLIError {
            writeError("error: \(error.message)\n")
            Darwin.exit(error.code)
        } catch {
            writeError("error: operation failed safely; no workspace mutation occurred\n")
            Darwin.exit(4)
        }
    }

    private static func run(_ arguments: [String]) async throws {
        let orchestrator = WorkspaceOrchestrator()
        guard let command = arguments.first else { throw CLIError.usage }

        switch command {
        case "status" where arguments.count == 1:
            let capabilities = await orchestrator.capabilities()
            let data = try JSONEncoder.pretty.encode(capabilities)
            writeOutput(String(decoding: data, as: UTF8.self) + "\n")

        case "analyze" where arguments.count == 3:
            let instructionData = try readStandardInput(maxBytes: 16_384)
            guard let instruction = String(data: instructionData, encoding: .utf8) else {
                throw CLIError.inputNotUTF8
            }
            let result = try await orchestrator.analyze(
                workspaceRoot: URL(fileURLWithPath: arguments[1], isDirectory: true),
                relativePath: arguments[2],
                instruction: instruction
            )
            let data = try JSONEncoder.pretty.encode(result)
            writeOutput(String(decoding: data, as: UTF8.self) + "\n")

        case "help", "--help", "-h":
            guard arguments.count == 1 else { throw CLIError.usage }
            writeOutput(usage)

        default:
            throw CLIError.usage
        }
    }

    private static func readStandardInput(maxBytes: Int) throws -> Data {
        var result = Data()
        while true {
            let remaining = maxBytes + 1 - result.count
            guard remaining > 0 else { throw CLIError.inputOversized }
            guard let chunk = try FileHandle.standardInput.read(upToCount: min(16_384, remaining)),
                  !chunk.isEmpty else { break }
            result.append(chunk)
            guard result.count <= maxBytes else { throw CLIError.inputOversized }
        }
        guard !result.isEmpty else { throw CLIError.emptyInput }
        return result
    }

    private static func writeOutput(_ value: String) {
        FileHandle.standardOutput.write(Data(value.utf8))
    }

    private static func writeError(_ value: String) {
        FileHandle.standardError.write(Data(value.utf8))
    }

    private static let usage = """
    Usage:
      workspace-orchestrator status
      workspace-orchestrator analyze <workspace-root> <relative-file> < instruction.txt
      workspace-orchestrator help

    Phase 1 is read-only. No write, shell, process-launch, or approval command exists.
    """

    private enum CLIError: Error {
        case usage, inputOversized, emptyInput, inputNotUTF8
        var message: String {
            switch self {
            case .usage: "invalid command; run 'workspace-orchestrator help'"
            case .inputOversized: "instruction exceeds 16 KiB"
            case .emptyInput: "instruction cannot be empty"
            case .inputNotUTF8: "instruction must be UTF-8"
            }
        }
        var code: Int32 { self == .usage ? 64 : 65 }
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}
