import SwiftUI

#if DEBUG && targetEnvironment(simulator)
enum ScreenshotScreen: String, CaseIterable {
    case basecamp, trailMap = "trail-map", missionBriefing = "mission-briefing"
    case readTheSignal = "read-the-signal", buildALine = "build-a-line"
    case missionComplete = "mission-complete", fieldLog = "field-log"

    static let current: ScreenshotScreen? = {
        let process = ProcessInfo.processInfo
        let args = process.arguments
        func value(after flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
            return args[index + 1]
        }
        if args.contains("-ReviewScreen") {
            return value(after: "-ReviewScreen").flatMap(ScreenshotScreen.init(rawValue:))
        }
        let environmentFlag = process.environment["APPSTORE_SCREENSHOTS"]?.lowercased()
        guard args.contains("-AppStoreScreenshots") || ["1", "true", "yes"].contains(environmentFlag ?? "") else { return nil }
        let rawIndex = value(after: "-AppStoreScreenshotScreen") ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"] ?? "0"
        guard let index = Int(rawIndex), allCases.indices.contains(index) else { return nil }
        return allCases[index]
    }()
}
#endif

@main
struct PatchwoodApp: App {
    @StateObject private var journal = Journal()
    var body: some Scene {
        WindowGroup {
            Basecamp()
                .environmentObject(journal)
                .preferredColorScheme(.light)
                .tint(Ink.pine)
                #if DEBUG && targetEnvironment(simulator)
                .transaction { transaction in
                    if ScreenshotScreen.current != nil {
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                    }
                }
                #endif
        }
    }
}

struct Checkpoint: Codable {
    var step = -1
    var selection: [Int] = []
    var checked = false
    var missed: Set<Int> = []
}

private struct FieldRecord: Codable {
    var completed: Set<String> = []
    var checkpoints: [String: Checkpoint] = [:]
    var days: Set<String> = []
}

final class Journal: ObservableObject {
    private let store: UserDefaults
    private let key = "patchwood.journal.v1"
    @Published private var record: FieldRecord

    init() {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotScreen.current != nil {
            store = UserDefaults(suiteName: "patchwood.screenshots.v1")!
            record = FieldRecord()
            seedScreenshot()
            return
        }
        #endif
        #if DEBUG
        if let suite = ProcessInfo.processInfo.environment["PATCHWOOD_TEST_JOURNAL"], suite.hasPrefix("patchwood.test.") {
            store = UserDefaults(suiteName: suite) ?? .standard
        } else {
            store = .standard
        }
        #else
        store = .standard
        #endif
        record = store.data(forKey: key)
            .flatMap { try? JSONDecoder().decode(FieldRecord.self, from: $0) } ?? FieldRecord()
    }

    #if DEBUG && targetEnvironment(simulator)
    private func seedScreenshot() {
        guard let screen = ScreenshotScreen.current else { return }
        let missions = Trailbook.routes[0].missions
        switch screen {
        case .trailMap, .missionComplete, .fieldLog:
            finish(missions[0])
            finish(missions[1])
            if screen == .missionComplete || screen == .fieldLog { finish(missions[2]) }
        case .readTheSignal:
            save(Checkpoint(step: 0, selection: missions[0].challenges[0].answer), for: missions[0])
        case .buildALine:
            save(Checkpoint(step: 2, selection: missions[0].challenges[2].answer), for: missions[0])
        case .basecamp, .missionBriefing:
            break
        }
        persist()
    }
    #endif

    var current: Mission? { Trailbook.missions.first { !completed($0) } }
    var finishedLevels: Int { Trailbook.missions.filter(completed).count }
    var xp: Int { finishedLevels * 30 }
    func completed(_ mission: Mission) -> Bool { record.completed.contains(mission.id) }
    func unlocked(_ mission: Mission) -> Bool { completed(mission) || current?.id == mission.id }
    func checkpoint(_ mission: Mission) -> Checkpoint { record.checkpoints[mission.id] ?? Checkpoint() }
    func saved(_ mission: Mission) -> Bool { record.checkpoints[mission.id] != nil }
    func count(_ route: Route) -> Int { route.missions.filter(completed).count }

    private func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    func streak(at today: Date) -> Int {
        var cursor = Calendar.current.startOfDay(for: today)
        if !record.days.contains(dayKey(cursor)) {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while record.days.contains(dayKey(cursor)) {
            count += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    func save(_ checkpoint: Checkpoint, for mission: Mission) {
        record.checkpoints[mission.id] = checkpoint
        persist()
    }

    func finish(_ mission: Mission) {
        record.completed.insert(mission.id)
        record.days.insert(dayKey(Date()))
        record.checkpoints.removeValue(forKey: mission.id)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(record) { store.set(data, forKey: key) }
    }
}

enum Ink {
    static let paper = Color(red: 0.978, green: 0.966, blue: 0.919)
    static let card = Color(red: 1, green: 0.992, blue: 0.953)
    static let pine = Color(red: 0.075, green: 0.239, blue: 0.213)
    static let deep = Color(red: 0.055, green: 0.169, blue: 0.151)
    static let moss = Color(red: 0.30, green: 0.37, blue: 0.30)
    static let line = Color(red: 0.81, green: 0.82, blue: 0.73)
    static let sage = Color(red: 0.87, green: 0.90, blue: 0.79)
    static let amber = Color(red: 0.98, green: 0.76, blue: 0.30)
    static let clay = Color(red: 0.64, green: 0.235, blue: 0.115)
    static let cream = Color(red: 1.0, green: 0.967, blue: 0.83)
}

struct Folio: View {
    let title: String
    let size: CGFloat
    @ScaledMetric(relativeTo: .title) private var scale: CGFloat = 1
    init(_ title: String, _ size: CGFloat) { self.title = title; self.size = size }
    var body: some View {
        Text(title).font(.custom("Georgia-Bold", size: size * scale)).tracking(-size * 0.04)
    }
}

struct Locator: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased()).font(.system(.caption2, design: .monospaced, weight: .bold)).tracking(1.2)
    }
}

struct Shield: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        return Path { path in
            path.move(to: CGPoint(x: w * 0.5, y: h * 0.01))
            path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.19))
            path.addLine(to: CGPoint(x: w * 0.89, y: h * 0.65))
            path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.99), control: CGPoint(x: w * 0.84, y: h * 0.84))
            path.addQuadCurve(to: CGPoint(x: w * 0.11, y: h * 0.65), control: CGPoint(x: w * 0.16, y: h * 0.84))
            path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.19))
            path.closeSubpath()
        }
    }
}

struct Patch: View {
    let symbol: String
    var size: CGFloat = 46
    var muted = false
    var body: some View {
        ZStack {
            Shield().fill(muted ? Ink.line : Ink.pine)
            Shield().stroke(muted ? Ink.moss.opacity(0.48) : Ink.amber, lineWidth: max(1, size * 0.022)).scaleEffect(0.84)
            Image(systemName: symbol).font(.system(size: size * 0.39, weight: .semibold))
                .foregroundStyle(muted ? Ink.moss : Ink.cream)
        }
        .frame(width: size * 0.91, height: size).accessibilityHidden(true)
    }
}

struct ActionButton: View {
    let title: String
    var icon = "arrow.right"
    var enabled = true
    let action: () -> Void
    init(_ title: String, icon: String = "arrow.right", enabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.enabled = enabled
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: icon).font(.body.weight(.bold))
            }
            .padding(.horizontal, 18).padding(.vertical, 15)
            .foregroundStyle(enabled ? Ink.cream : Ink.moss)
            .background(enabled ? Ink.pine : Ink.sage, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain).disabled(!enabled)
    }
}

struct Pip: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lift = false
    private var still: Bool {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotScreen.current != nil { return true }
        #endif
        return reduceMotion
    }
    var body: some View {
        Image("Pip").resizable().scaledToFit()
            .rotationEffect(.degrees(still ? 0 : (lift ? 1.4 : -1.4)), anchor: .bottom)
            .offset(y: still ? 0 : (lift ? -2 : 1))
            .onAppear { lift = true }
            .animation(still ? nil : .easeInOut(duration: 1.75).repeatForever(autoreverses: true), value: lift)
            .accessibilityHidden(true)
    }
}

struct FieldCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content().padding(16).background(Ink.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Ink.line, lineWidth: 1) }
    }
}
