import Foundation
import OllamaLocalCore

public enum EngineID: String, Codable, CaseIterable, Sendable {
    case localGemma = "local_gemma"
    case anthropic = "anthropic"
}

public struct EngineCapability: Codable, Sendable, Equatable {
    public let engine: EngineID
    public let available: Bool
    public let networkScope: String
    public let model: String
    public let reason: String?
}

protocol EngineAdapter: Sendable {
    var capability: EngineCapability { get async }
    func infer(prompt: String) async throws -> String
}

actor LocalGemmaAdapter: EngineAdapter {
    private let client = OllamaLocalClient()

    var capability: EngineCapability {
        get async {
            do {
                _ = try await client.status()
                return .init(engine: .localGemma, available: true, networkScope: "127.0.0.1:11434", model: "gemma3:4b", reason: nil)
            } catch {
                return .init(engine: .localGemma, available: false, networkScope: "127.0.0.1:11434", model: "gemma3:4b", reason: "local_service_unavailable")
            }
        }
    }

    func infer(prompt: String) async throws -> String { try await client.ask(prompt: prompt) }
}

struct DisabledAnthropicAdapter: EngineAdapter {
    var capability: EngineCapability {
        get async { .init(engine: .anthropic, available: false, networkScope: "none", model: "claude-opus-5", reason: "credential_not_configured") }
    }
    func infer(prompt: String) async throws -> String { throw RegistryError.engineUnavailable }
}

public actor EngineRegistry {
    private let local: any EngineAdapter
    private let anthropic: any EngineAdapter

    public init() {
        local = LocalGemmaAdapter()
        anthropic = DisabledAnthropicAdapter()
    }

    init(local: any EngineAdapter, anthropic: any EngineAdapter = DisabledAnthropicAdapter()) {
        self.local = local
        self.anthropic = anthropic
    }

    public func capabilities() async -> [EngineCapability] {
        [await local.capability, await anthropic.capability]
    }

    func infer(using engine: EngineID, prompt: String) async throws -> String {
        switch engine {
        case .localGemma: try await local.infer(prompt: prompt)
        case .anthropic: throw RegistryError.engineUnavailable
        }
    }
}

public enum RegistryError: Error, Equatable, Sendable { case engineUnavailable }
