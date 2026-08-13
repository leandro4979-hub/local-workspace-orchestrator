import Darwin
import Foundation

public final class WorkspaceReader: @unchecked Sendable {
    public struct Limits: Sendable {
        public let maxFileBytes: Int
        public let maxPathBytes: Int
        public let maxDepth: Int

        public init(maxFileBytes: Int = 1_048_576, maxPathBytes: Int = 1_024, maxDepth: Int = 32) {
            precondition((1...1_048_576).contains(maxFileBytes))
            precondition((1...1_024).contains(maxPathBytes))
            precondition((1...32).contains(maxDepth))
            self.maxFileBytes = maxFileBytes
            self.maxPathBytes = maxPathBytes
            self.maxDepth = maxDepth
        }
    }

    public struct Identity: Codable, Sendable, Equatable {
        public let canonicalPath: String
        public let device: UInt64
        public let inode: UInt64

        public var stableID: String { "dev:\(device):ino:\(inode)" }
    }

    private let rootDescriptor: Int32
    public let identity: Identity
    private let limits: Limits

    public init(rootURL: URL, limits: Limits = .init()) throws {
        guard rootURL.isFileURL else { throw ReaderError.invalidRoot }
        let resolved = rootURL.resolvingSymlinksInPath().standardizedFileURL
        let descriptor = Darwin.open(resolved.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        guard descriptor >= 0 else { throw ReaderError.invalidRoot }
        var info = stat()
        guard fstat(descriptor, &info) == 0, (info.st_mode & S_IFMT) == S_IFDIR else {
            Darwin.close(descriptor)
            throw ReaderError.invalidRoot
        }
        rootDescriptor = descriptor
        identity = Identity(
            canonicalPath: resolved.path,
            device: UInt64(info.st_dev),
            inode: UInt64(info.st_ino)
        )
        self.limits = limits
    }

    deinit { Darwin.close(rootDescriptor) }

    public func readTextFile(relativePath: String) throws -> String {
        let components = try validate(relativePath)
        var current = dup(rootDescriptor)
        guard current >= 0 else { throw ReaderError.ioFailure }
        defer { if current >= 0 { Darwin.close(current) } }

        for component in components.dropLast() {
            let next = openat(current, component, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
            guard next >= 0 else { throw ReaderError.pathRejected }
            Darwin.close(current)
            current = next
        }

        guard let leaf = components.last else { throw ReaderError.invalidPath }
        let file = openat(current, leaf, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
        guard file >= 0 else { throw ReaderError.pathRejected }
        defer { Darwin.close(file) }

        var info = stat()
        guard fstat(file, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG else {
            throw ReaderError.notRegularFile
        }
        guard info.st_size >= 0, info.st_size <= limits.maxFileBytes else {
            throw ReaderError.fileOversized
        }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: min(64 * 1_024, limits.maxFileBytes + 1))
        while true {
            let count = Darwin.read(file, &buffer, buffer.count)
            guard count >= 0 else { throw ReaderError.ioFailure }
            if count == 0 { break }
            guard count <= limits.maxFileBytes - data.count else { throw ReaderError.fileOversized }
            data.append(buffer, count: count)
        }
        guard let text = String(data: data, encoding: .utf8), !text.unicodeScalars.contains(where: { $0.value == 0 }) else {
            throw ReaderError.notUTF8Text
        }
        return text
    }

    private func validate(_ path: String) throws -> [String] {
        guard !path.isEmpty, path.utf8.count <= limits.maxPathBytes,
              !path.hasPrefix("/"), path.precomposedStringWithCanonicalMapping == path else {
            throw ReaderError.invalidPath
        }
        let components = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard !components.isEmpty, components.count <= limits.maxDepth else { throw ReaderError.invalidPath }
        for component in components {
            guard !component.isEmpty, component != ".", component != "..",
                  !component.unicodeScalars.contains(where: { $0.value == 0 }),
                  !Self.deniedNames.contains(component.lowercased()),
                  !Self.deniedSuffixes.contains(where: { component.lowercased().hasSuffix($0) }) else {
                throw ReaderError.pathRejected
            }
        }
        return components
    }

    private static let deniedNames: Set<String> = [
        ".env", ".ssh", ".aws", ".gnupg", ".git", ".gitconfig", ".netrc", "id_rsa", "id_ed25519",
        "credentials", "credentials.json", "secrets", "deriveddata", ".build", "node_modules"
    ]
    private static let deniedSuffixes = [".p12", ".pfx", ".key", ".pem", ".mobileprovision"]

    public enum ReaderError: Error, Equatable, Sendable {
        case invalidRoot, invalidPath, pathRejected, notRegularFile, fileOversized, notUTF8Text, ioFailure
    }
}
