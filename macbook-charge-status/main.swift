//
//  main.swift
//  macbook-charge-status
//
//  Created by Kenny Na on 2023-06-25.
//  @kennynahh on GitHub

import Foundation

struct BatteryStatus {
    let isCharging: Bool
    let level: Float
}

func getBatteryStatus() -> BatteryStatus? {
    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", "pmset -g batt"]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    guard let statusLine = output.split(separator: "\n").first(where: { $0.contains("InternalBattery") }) else { return nil }
    let statusComponents = statusLine.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    guard let percentageRange = statusComponents[0].range(of: "\\d+(\\.\\d+)?%", options: .regularExpression),
          let level = Float(statusComponents[0][percentageRange].trimmingCharacters(in: CharacterSet(charactersIn: "%"))) else { return nil }

    let isCharging = output.contains("AC Power")

    return BatteryStatus(isCharging: isCharging, level: level)
}

guard let status = getBatteryStatus() else {
    print("Failed to get battery status")
    exit(EXIT_FAILURE)
}

print("Battery level: \(status.level)%")
print("Is connected to AC Power: \(status.isCharging ? "Yes" : "No")")
