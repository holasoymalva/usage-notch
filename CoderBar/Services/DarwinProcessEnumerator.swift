//
//  DarwinProcessEnumerator.swift
//  Usage Notch
//

import Foundation
#if canImport(Darwin)
import Darwin
#endif

public struct DiscoveredAntigravityProcess: Sendable {
    public let pid: Int32
    public let executablePath: String
    public let commandLine: String
    public let extensionServerPort: Int?
    public let extensionServerCsrfToken: String?
    public let csrfToken: String?
    public let listeningPorts: [Int]
    
    public init(
        pid: Int32,
        executablePath: String,
        commandLine: String,
        extensionServerPort: Int? = nil,
        extensionServerCsrfToken: String? = nil,
        csrfToken: String? = nil,
        listeningPorts: [Int] = []
    ) {
        self.pid = pid
        self.executablePath = executablePath
        self.commandLine = commandLine
        self.extensionServerPort = extensionServerPort
        self.extensionServerCsrfToken = extensionServerCsrfToken
        self.csrfToken = csrfToken
        self.listeningPorts = listeningPorts
    }
}

public enum DarwinProcessEnumerator {
    public static func isAntigravityCandidatePath(_ executablePath: String) -> Bool {
        let lowercased = executablePath.lowercased()
        if lowercased.contains("antigravity") {
            return true
        }
        
        var basename = URL(fileURLWithPath: lowercased).lastPathComponent
        if basename.hasSuffix(".exe") {
            basename.removeLast(4)
        }
        return basename.hasPrefix("language_server") ||
            basename.hasPrefix("language-server") ||
            ["agy", "antigravity-cli", "antigravity_cli"].contains(basename)
    }

    public static func parseProcArgs2(_ data: Data) -> String? {
        let argumentCountSize = MemoryLayout<Int32>.size
        guard data.count >= argumentCountSize else { return nil }
        let argumentCount = data.withUnsafeBytes { rawBuffer in
            Int(Int32(littleEndian: rawBuffer.loadUnaligned(as: Int32.self)))
        }
        guard argumentCount >= 0 else { return nil }

        let bytes = [UInt8](data)
        var offset = argumentCountSize
        guard let executableTerminator = bytes[offset...].firstIndex(of: 0) else { return nil }
        offset = executableTerminator + 1
        while offset < bytes.count, bytes[offset] == 0 {
            offset += 1
        }

        var arguments: [String] = []
        arguments.reserveCapacity(argumentCount)
        for _ in 0..<argumentCount {
            guard offset < bytes.count,
                  let terminator = bytes[offset...].firstIndex(of: 0),
                  let argument = String(bytes: bytes[offset..<terminator], encoding: .utf8)
            else { return nil }
            arguments.append(argument)
            offset = terminator + 1
        }
        return arguments.joined(separator: " ")
    }
    
    public static func extractIntFlag(flag: String, from text: String) -> Int? {
        guard let range = text.range(of: "\(flag) ") ?? text.range(of: "\(flag)=") else { return nil }
        let sub = text[range.upperBound...]
        let token = sub.prefix { $0 != " " && $0 != "\"" && $0 != "'" }
        return Int(token)
    }
    
    public static func extractStringFlag(flag: String, from text: String) -> String? {
        guard let range = text.range(of: "\(flag) ") ?? text.range(of: "\(flag)=") else { return nil }
        let sub = text[range.upperBound...]
        let token = sub.prefix { $0 != " " && $0 != "\"" && $0 != "'" }
        return token.isEmpty ? nil : String(token)
    }
    
    public static func fallbackListeningPortsViaLsof(pid: Int32) -> [Int] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-a", "-p", "\(pid)"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            return parseLsofListeningPorts(output)
        } catch {
            return []
        }
    }

    public static func parseLsofListeningPorts(_ output: String) -> [Int] {
        guard let regex = try? NSRegularExpression(pattern: #":(\d+)\s+\(LISTEN\)"#) else { return [] }
        let range = NSRange(output.startIndex..<output.endIndex, in: output)
        var ports: Set<Int> = []
        regex.enumerateMatches(in: output, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let range = Range(match.range(at: 1), in: output),
                  let port = Int(output[range]) else { return }
            ports.insert(port)
        }
        return ports.sorted()
    }
    
    public static func fallbackScanProcessesViaPS() -> [DiscoveredAntigravityProcess] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-ax", "-o", "pid=,command="]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var results: [DiscoveredAntigravityProcess] = []
            for line in output.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }
                let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                guard parts.count == 2, let pid = Int32(parts[0]) else { continue }
                let cmd = String(parts[1])
                if isAntigravityCandidatePath(cmd) || cmd.contains("antigravity") || cmd.contains("language_server") || cmd.contains("agy") {
                    var ports = fallbackListeningPortsViaLsof(pid: pid)
                    let extPort = extractIntFlag(flag: "--extension_server_port", from: cmd) ?? extractIntFlag(flag: "--port", from: cmd)
                    if let p = extPort, !ports.contains(p) {
                        ports.append(p)
                    }
                    let extCsrf = extractStringFlag(flag: "--extension_server_csrf_token", from: cmd)
                    let csrf = extractStringFlag(flag: "--csrf_token", from: cmd)
                    results.append(DiscoveredAntigravityProcess(
                        pid: pid,
                        executablePath: cmd,
                        commandLine: cmd,
                        extensionServerPort: extPort,
                        extensionServerCsrfToken: extCsrf,
                        csrfToken: csrf,
                        listeningPorts: ports
                    ))
                }
            }
            return results
        } catch {
            return []
        }
    }
}

#if canImport(Darwin)
extension DarwinProcessEnumerator {
    public static func allPIDs() -> [Int32] {
        let requiredCount = proc_listallpids(nil, 0)
        guard requiredCount > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(requiredCount) + 32)
        let actualCount = pids.withUnsafeMutableBytes { buffer in
            proc_listallpids(buffer.baseAddress, Int32(buffer.count))
        }
        guard actualCount > 0 else { return [] }
        return Array(pids.prefix(Int(actualCount))).filter { $0 > 0 }
    }

    public static func executablePath(pid: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        let byteCount = buffer.withUnsafeMutableBytes { rawBuffer in
            proc_pidpath(pid, rawBuffer.baseAddress, UInt32(rawBuffer.count))
        }
        guard byteCount > 0 else { return nil }
        return buffer.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return nil }
            let bytes = UnsafeRawBufferPointer(start: baseAddress, count: Int(byteCount))
            let pathBytes = bytes.prefix { $0 != 0 }
            guard !pathBytes.isEmpty else { return nil }
            return String(bytes: pathBytes, encoding: .utf8)
        }
    }

    public static func commandLine(pid: Int32) -> String? {
        var mib = [CTL_KERN, KERN_PROCARGS2, pid]
        var byteCount = 0
        guard sysctl(&mib, u_int(mib.count), nil, &byteCount, nil, 0) == 0,
              byteCount >= MemoryLayout<Int32>.size
        else { return nil }

        var data = Data(count: byteCount)
        let result = data.withUnsafeMutableBytes { rawBuffer in
            sysctl(&mib, u_int(mib.count), rawBuffer.baseAddress, &byteCount, nil, 0)
        }
        guard result == 0 else { return nil }
        if byteCount < data.count {
            data.removeSubrange(byteCount..<data.count)
        }
        return self.parseProcArgs2(data)
    }

    public static func listeningTCPPorts(pid: Int32) -> [Int] {
        let requiredBytes = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
        guard requiredBytes > 0 else { return [] }
        let descriptorStride = MemoryLayout<proc_fdinfo>.stride
        var descriptors = [proc_fdinfo](
            repeating: proc_fdinfo(),
            count: Int(requiredBytes) / descriptorStride + 8)
        let actualBytes = descriptors.withUnsafeMutableBytes { buffer in
            proc_pidinfo(
                pid,
                PROC_PIDLISTFDS,
                0,
                buffer.baseAddress,
                Int32(buffer.count))
        }
        guard actualBytes > 0 else { return [] }

        var ports: Set<Int> = []
        for descriptor in descriptors.prefix(Int(actualBytes) / descriptorStride)
            where descriptor.proc_fdtype == PROX_FDTYPE_SOCKET
        {
            var info = socket_fdinfo()
            let byteCount = proc_pidfdinfo(
                pid,
                descriptor.proc_fd,
                PROC_PIDFDSOCKETINFO,
                &info,
                Int32(MemoryLayout<socket_fdinfo>.size))
            guard byteCount == MemoryLayout<socket_fdinfo>.size,
                  info.psi.soi_kind == SOCKINFO_TCP,
                  info.psi.soi_proto.pri_tcp.tcpsi_state == TSI_S_LISTEN
            else { continue }
            let networkPort = UInt16(truncatingIfNeeded: info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport)
            ports.insert(Int(UInt16(bigEndian: networkPort)))
        }
        return ports.sorted()
    }
    
    public static func findAntigravityProcesses() -> [DiscoveredAntigravityProcess] {
        var processes: [DiscoveredAntigravityProcess] = []
        let pids = allPIDs()
        for pid in pids {
            guard let path = executablePath(pid: pid), isAntigravityCandidatePath(path) else { continue }
            let cmd = commandLine(pid: pid) ?? path
            var ports = listeningTCPPorts(pid: pid)
            if ports.isEmpty {
                ports = fallbackListeningPortsViaLsof(pid: pid)
            }
            
            let extPort = extractIntFlag(flag: "--extension_server_port", from: cmd) ?? extractIntFlag(flag: "--port", from: cmd)
            if let p = extPort, !ports.contains(p) {
                ports.append(p)
            }
            let extCsrf = extractStringFlag(flag: "--extension_server_csrf_token", from: cmd)
            let csrf = extractStringFlag(flag: "--csrf_token", from: cmd)
            
            processes.append(DiscoveredAntigravityProcess(
                pid: pid,
                executablePath: path,
                commandLine: cmd,
                extensionServerPort: extPort,
                extensionServerCsrfToken: extCsrf,
                csrfToken: csrf,
                listeningPorts: ports
            ))
        }
        
        if processes.isEmpty {
            processes = fallbackScanProcessesViaPS()
        }
        
        return processes
    }
}
#else
extension DarwinProcessEnumerator {
    public static func findAntigravityProcesses() -> [DiscoveredAntigravityProcess] {
        return fallbackScanProcessesViaPS()
    }
}
#endif
