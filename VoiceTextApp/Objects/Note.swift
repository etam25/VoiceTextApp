import SwiftUI

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    let date: Date
    let type: NoteType
    var content: String
    var audioFileName: String?

    
    enum NoteType: String, Codable {
        case voice, file, textScan

        var systemImage: String {
            switch self {
            case .voice:    return "waveform.circle.fill"
            case .file:     return "doc.fill"
            case .textScan: return "text.viewfinder"
            }
        }

        var label: String {
            switch self {
            case .voice:    return "Voice"
            case .file:     return "File"
            case .textScan: return "Scanned Text"
            }
        }

        var gradientColors: [Color] {
            switch self {
            case .voice:    return [.blue, .indigo]
            case .file:     return [.green, .teal]
            case .textScan: return [.orange, .red]
            }
        }
    }
}
