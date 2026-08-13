// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LocalWorkspaceOrchestrator",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "OrchestratorCore", targets: ["OrchestratorCore"]),
        .executable(name: "workspace-orchestrator", targets: ["OrchestratorCLI"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/leandro4979-hub/ollama-local-client.git",
            revision: "c5d102cce72f1cb4ae9c20a4bd47f7a1e57bf522"
        )
    ],
    targets: [
        .target(
            name: "OrchestratorCore",
            dependencies: [.product(name: "OllamaLocalCore", package: "ollama-local-client")]
        ),
        .executableTarget(name: "OrchestratorCLI", dependencies: ["OrchestratorCore"]),
        .testTarget(name: "OrchestratorCoreTests", dependencies: ["OrchestratorCore"])
    ]
)
