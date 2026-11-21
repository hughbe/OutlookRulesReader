//
//  RawEntryID.swift
//
//
//  Created by Hugh Bellamy on 20/11/2026.
//

import DataStream
import MAPI

/// A MAPI entry ID stored as a `FlatEntry`: its size, then its bytes (spec §8). Parameters keep the bytes exactly as
/// read, so an entry ID always writes back unchanged, even when it is of a kind `MAPI` can't decode, or holds a path
/// `MAPI` can't encode again (such as a PST path with non-ASCII characters).
internal enum RawEntryID {
    static func read(from dataStream: inout DataStream) throws -> [UInt8] {
        /// Size (4 bytes)
        let size: UInt32 = try dataStream.read(endianess: .littleEndian)
        guard size <= dataStream.remainingCount else {
            throw OutlookRulesReadError.lengthOutOfRange
        }

        /// Entry ID (variable)
        return try dataStream.readBytes(count: Int(size))
    }

    static func write(_ bytes: [UInt8], to dataStream: inout OutputDataStream) {
        /// Size (4 bytes)
        dataStream.write(UInt32(bytes.count), endianess: .littleEndian)

        /// Entry ID (variable)
        dataStream.write(bytes)
    }

    /// The decoded entry ID, or nil if `MAPI` can't decode it.
    static func decode(_ bytes: [UInt8]) -> EntryID? {
        guard !bytes.isEmpty else {
            return nil
        }

        var dataStream = DataStream(bytes)
        guard let entryID = try? getEntryID(dataStream: &dataStream, size: bytes.count),
              dataStream.position == bytes.count else {
            return nil
        }

        return entryID
    }

    static func encode(_ entryID: EntryID) -> [UInt8] {
        var dataStream = OutputDataStream()
        entryID.write(to: &dataStream)
        return [UInt8](dataStream.data)
    }
}
