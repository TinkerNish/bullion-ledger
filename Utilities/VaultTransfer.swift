import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A versioned snapshot of the vault's data, used for export/import.
struct VaultExportPayload: Codable {
    var version: Int = 1
    var exportedAt: Date = Date()
    var lots: [GoldLot]
}

enum VaultTransferError: LocalizedError {
    case unreadableFile
    case unrecognizedFormat

    var errorDescription: String? {
        switch self {
        case .unreadableFile: return "Couldn't read that file."
        case .unrecognizedFormat: return "That file doesn't look like a Bullion Ledger export."
        }
    }
}

enum VaultCoding {
    static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    static func encode(_ lots: [GoldLot]) -> Data {
        let payload = VaultExportPayload(lots: lots)
        return (try? encoder.encode(payload)) ?? Data()
    }

    /// Accepts either the wrapped export payload or a bare array of lots (e.g. the
    /// app's own internal storage file), so either can be picked for import.
    static func decode(_ data: Data) throws -> [GoldLot] {
        if let payload = try? decoder.decode(VaultExportPayload.self, from: data) {
            return payload.lots
        }
        if let lots = try? decoder.decode([GoldLot].self, from: data) {
            return lots
        }
        throw VaultTransferError.unrecognizedFormat
    }
}

/// A JSON file document representing an exported vault, for use with `.fileExporter`.
struct VaultExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(lots: [GoldLot]) {
        self.data = VaultCoding.encode(lots)
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw VaultTransferError.unreadableFile
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
