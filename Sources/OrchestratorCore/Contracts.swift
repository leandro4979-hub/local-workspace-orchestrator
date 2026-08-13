import Foundation

public enum ContractVersion {
    public static let current = "1.0.0"
}

public enum ActionState: String, Codable, CaseIterable, Sendable {
    case draft, prepared, awaitingApproval = "awaiting_approval", approved, executing, succeeded
    case rejected, cancelled, expired, failed, rolledBack = "rolled_back"
    case unknownAfterCrash = "unknown_after_crash"

    public var isTerminal: Bool {
        switch self {
        case .succeeded, .rejected, .cancelled, .expired, .failed, .rolledBack: true
        default: false
        }
    }
}

public enum TransitionActor: String, Codable, Sendable {
    case coordinator, preparer, human, approvalAuthority = "approval_authority"
    case executor, recoveryManager = "recovery_manager", expiryService = "expiry_service"
}

/// Encode-only in Phase 1. Untrusted serialized data must not be able to
/// reconstruct an action directly in an authoritative state.
public struct ActionRecord: Encodable, Sendable, Equatable {
    public let schemaVersion: String
    public let actionID: UUID
    public let actionType: String
    public let workspaceID: String
    public private(set) var state: ActionState
    public private(set) var stateVersion: UInt64

    public init(actionID: UUID, actionType: String, workspaceID: String) throws {
        guard !actionType.isEmpty, actionType.utf8.count <= 64,
              !workspaceID.isEmpty, workspaceID.utf8.count <= 256 else {
            throw ContractError.invalidField
        }
        schemaVersion = ContractVersion.current
        self.actionID = actionID
        self.actionType = actionType
        self.workspaceID = workspaceID
        state = .draft
        stateVersion = 1
    }

    public mutating func transition(to next: ActionState, by actor: TransitionActor) throws {
        guard !state.isTerminal else { throw ContractError.terminalState }
        guard Self.allowedTransitions[state]?[next]?.contains(actor) == true else {
            throw ContractError.transitionDenied
        }
        let (nextVersion, overflow) = stateVersion.addingReportingOverflow(1)
        guard !overflow else { throw ContractError.integerOverflow }
        state = next
        stateVersion = nextVersion
    }

    private static let allowedTransitions: [ActionState: [ActionState: Set<TransitionActor>]] = [
        .draft: [.prepared: [.preparer], .cancelled: [.human, .coordinator], .failed: [.coordinator]],
        .prepared: [.awaitingApproval: [.coordinator], .cancelled: [.human, .coordinator], .failed: [.coordinator]],
        .awaitingApproval: [.approved: [.approvalAuthority], .rejected: [.human], .cancelled: [.human], .expired: [.expiryService]],
        .approved: [.executing: [.executor], .expired: [.expiryService], .cancelled: [.human]],
        .executing: [.succeeded: [.executor], .failed: [.executor], .unknownAfterCrash: [.recoveryManager]],
        .failed: [.rolledBack: [.executor, .recoveryManager]],
        .unknownAfterCrash: [.succeeded: [.recoveryManager], .rolledBack: [.recoveryManager]]
    ]

    public enum ContractError: Error, Equatable, Sendable {
        case invalidField, transitionDenied, terminalState, integerOverflow
    }
}
