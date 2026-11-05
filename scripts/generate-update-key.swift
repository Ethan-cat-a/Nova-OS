import CryptoKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate-update-key <private-key-file>\n", stderr)
    exit(2)
}

let privateURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard !FileManager.default.fileExists(atPath: privateURL.path) else {
    fputs("Refusing to overwrite an existing Sparkle key.\n", stderr)
    exit(1)
}

let key = Curve25519.Signing.PrivateKey()
let privateSeed = Data(key.rawRepresentation).base64EncodedString() + "\n"
try FileManager.default.createDirectory(
    at: privateURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try Data(privateSeed.utf8).write(to: privateURL, options: .atomic)
try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: privateURL.path)
print(Data(key.publicKey.rawRepresentation).base64EncodedString())
