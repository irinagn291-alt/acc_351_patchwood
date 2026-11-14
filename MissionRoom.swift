import SwiftUI

struct MissionRoom: View {
    @EnvironmentObject private var journal: Journal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let mission: Mission
    @State private var state: Checkpoint
    @State private var finished = false
    @State private var earned = false
    @State private var patchEarned = false

    init(mission: Mission, checkpoint: Checkpoint) {
        self.mission = mission
        _state = State(initialValue: checkpoint)
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotScreen.current == .missionComplete && mission.id == Trailbook.routes[0].missions[2].id {
            _state = State(initialValue: Checkpoint(step: mission.challenges.count - 1,
                                                     selection: mission.challenges.last?.answer ?? [], checked: true))
            _finished = State(initialValue: true)
            _earned = State(initialValue: true)
            _patchEarned = State(initialValue: true)
        }
        #endif
    }

    private var exercise: Challenge? {
        mission.challenges.indices.contains(state.step) ? mission.challenges[state.step] : nil
    }

    private var correct: Bool { exercise.map { state.selection == $0.answer } ?? false }
    private var route: Route { Trailbook.route(for: mission) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.body.weight(.bold)).frame(width: 44, height: 44)
                        .background(Ink.card, in: Circle()).overlay { Circle().strokeBorder(Ink.line) }
                }.buttonStyle(.plain).accessibilityLabel("Return to basecamp")
                HStack(spacing: 4) {
                    ForEach(mission.challenges.indices, id: \.self) { i in
                        Capsule().fill(finished || i < state.step ? Ink.pine : i == state.step ? Ink.amber : Ink.line)
                            .frame(height: 6)
                    }
                }.accessibilityHidden(true)
                Locator(finished ? "Logged" : state.step < 0 ? "Briefing" : "\(state.step + 1) / \(mission.challenges.count)")
            }
            .padding(.vertical, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if finished { debrief }
                    else if let exercise { challenge(exercise) }
                    else { briefing }
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
            }
            .id(finished ? 99 : state.step)
            .scrollIndicators(.hidden)
            VStack(spacing: 10) {
                if state.checked, !finished, let exercise {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: correct ? "checkmark.circle.fill" : "arrow.counterclockwise.circle.fill")
                            .font(.title3).foregroundStyle(correct ? Ink.pine : Ink.clay)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(correct ? "Signal received!" : "Let's tune that line.").font(.headline)
                            Text(exercise.explanation).font(.footnote).fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12).background(correct ? Ink.sage : Ink.amber.opacity(0.24), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .combine)
                }
                ActionButton(actionTitle, icon: actionIcon, enabled: actionEnabled, action: advance)
                    .accessibilityIdentifier("missionAction")
            }.padding(.top, 8).padding(.bottom, 5)
        }
        .padding(.horizontal, 20).frame(maxWidth: 620).frame(maxWidth: .infinity)
        .background(Ink.paper.ignoresSafeArea()).foregroundStyle(Ink.pine)
        .sensoryFeedback(.success, trigger: state.checked && correct)
    }

    @ViewBuilder private var briefing: some View {
        Locator("Level \(Trailbook.number(of: mission)) / " + route.name).foregroundStyle(Ink.clay)
        Folio(mission.title, 35)
        Text(mission.briefing).font(.body).foregroundStyle(Ink.deep).fixedSize(horizontal: false, vertical: true)
        CodePanel(code: mission.example)
        HStack(alignment: .center, spacing: 12) {
            Pip().frame(width: 72, height: 78)
            VStack(alignment: .leading, spacing: 5) {
                Locator("Pip · Field radio").foregroundStyle(Ink.clay)
                Text(mission.dispatch).font(.callout.weight(.medium))
            }
            Spacer(minLength: 0)
        }.padding(12).background(Ink.sage.opacity(0.66), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder private func challenge(_ q: Challenge) -> some View {
        Locator(q.kind.rawValue).foregroundStyle(Ink.clay)
        Folio(q.prompt, 31)
        CodePanel(code: q.code)
        if q.kind == .assemble {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Locator("Your line")
                    Spacer()
                    Button("Undo") {
                        state.selection.removeLast()
                        journal.save(state, for: mission)
                    }
                    .font(.subheadline.weight(.semibold)).buttonStyle(.plain)
                    .disabled(state.selection.isEmpty || state.checked)
                    .opacity(state.selection.isEmpty || state.checked ? 0.48 : 1)
                    .accessibilityIdentifier("undo")
                }
                Text(state.selection.isEmpty ? "Tap the pieces in order" : assembled(q))
                    .font(.system(.body, design: .monospaced, weight: .medium))
                    .foregroundStyle(state.selection.isEmpty ? Ink.moss : Ink.pine)
                    .frame(minHeight: 30, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(13).background(Ink.sage.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: q.options.contains { $0.count > 11 } ? 135 : 76), spacing: 8)], spacing: 8) {
                ForEach(q.options.indices, id: \.self) { idx in
                    Button {
                        pick(idx, in: q)
                    } label: {
                        Text(verbatim: q.options[idx]).fixedSize(horizontal: false, vertical: true).font(.system(.subheadline, design: .monospaced, weight: .semibold))
                            .padding(.horizontal, 4).frame(maxWidth: .infinity, minHeight: 45)
                            .background(Ink.card, in: RoundedRectangle(cornerRadius: 9))
                            .overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(Ink.line) }
                    }
                    .buttonStyle(.plain).disabled(state.checked || state.selection.contains(idx))
                    .opacity(state.selection.contains(idx) ? 0.36 : 1)
                    .accessibilityIdentifier("choice-\(idx)")
                }
            }
        } else {
            VStack(spacing: 8) {
                ForEach(q.options.indices, id: \.self) { idx in
                    let selected = state.selection.contains(idx)
                    Button { pick(idx, in: q) } label: {
                        HStack(spacing: 12) {
                            Text(["A", "B", "C"][idx])
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .frame(width: 26, height: 26)
                                .background(selected ? Ink.pine : Ink.paper, in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(selected ? Ink.cream : Ink.moss)
                            Text(verbatim: q.options[idx]).font(.system(.body, design: .monospaced, weight: .medium))
                            Spacer()
                            if selected { Image(systemName: "checkmark.circle.fill") }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(selected ? Ink.sage : Ink.card, in: RoundedRectangle(cornerRadius: 12))
                        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Ink.pine : Ink.line, lineWidth: selected ? 2 : 1) }
                    }
                    .buttonStyle(.plain).disabled(state.checked)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("choice-\(idx)")
                }
            }
        }
    }

    private func assembled(_ q: Challenge) -> String {
        if let fragments = q.fragments { return state.selection.map { fragments[$0] }.joined() }
        return state.selection.map { q.options[$0] }.joined(separator: " ")
            .replacingOccurrences(of: "( ", with: "(")
            .replacingOccurrences(of: " (", with: "(")
            .replacingOccurrences(of: " )", with: ")")
            .replacingOccurrences(of: " [", with: "[")
            .replacingOccurrences(of: "[ ", with: "[")
            .replacingOccurrences(of: " ]", with: "]")
            .replacingOccurrences(of: " :", with: ":")
    }

    @ViewBuilder private var debrief: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Ink.amber.opacity(0.35)).frame(width: 154, height: 154)
                Pip().frame(width: 145, height: 145)
            }.padding(.top, 8)
            Locator("Transmission logged").foregroundStyle(Ink.clay)
            Folio("Mission complete!", 32)
            Text(mission.title).font(.headline)
            HStack(spacing: 12) {
                resultStat(earned ? "+30" : "+0", "XP earned")
                resultStat("\(mission.challenges.count - state.missed.count)/\(mission.challenges.count)", "First try")
            }.padding(.top, 3)
            if patchEarned {
                FieldCard {
                    HStack(spacing: 12) {
                        Patch(symbol: route.symbol, size: 51)
                        VStack(alignment: .leading, spacing: 4) {
                            Locator("New station patch").foregroundStyle(Ink.clay)
                            Folio(route.patch, 22)
                        }
                        Spacer()
                    }
                }
            }
            Text(journal.current == nil ? "All 100 levels are complete. Your patches are waiting in the field log." :
                    earned ? "The next mission is open on your trail." : "Practice logged. Your station is still on the air.")
                .font(.subheadline).foregroundStyle(Ink.moss).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity)
    }

    private func resultStat(_ value: String, _ title: String) -> some View {
        FieldCard {
            VStack(spacing: 4) { Folio(value, 26); Locator(title).foregroundStyle(Ink.moss) }
                .frame(maxWidth: .infinity)
        }
    }

    private var actionTitle: String {
        if finished { return "Back to basecamp" }
        if state.step < 0 { return "Start challenges" }
        if !state.checked { return "Check answer" }
        if !correct { return "Try again" }
        return state.step == mission.challenges.count - 1 ? "Log mission" : "Continue"
    }
    private var actionIcon: String { state.checked && !correct ? "arrow.counterclockwise" : "arrow.right" }
    private var actionEnabled: Bool { finished || state.step < 0 || state.checked || !state.selection.isEmpty }

    private func pick(_ index: Int, in q: Challenge) {
        if q.kind == .assemble { state.selection.append(index) }
        else { state.selection = [index] }
        journal.save(state, for: mission)
    }

    private func advance() {
        if finished { dismiss(); return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            if state.step < 0 { state.step = 0 }
            else if !state.checked {
                state.checked = true
                if !correct { state.missed.insert(state.step) }
            } else if correct && state.step == mission.challenges.count - 1 {
                earned = !journal.completed(mission)
                journal.finish(mission)
                patchEarned = earned && journal.count(route) == route.missions.count
                finished = true
                return
            } else {
                if correct { state.step += 1 }
                state.selection = []
                state.checked = false
            }
            journal.save(state, for: mission)
        }
    }
}

private struct CodePanel: View {
    let code: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left.forwardslash.chevron.right").font(.caption.bold())
                Locator("Python")
                Spacer()
                HStack(spacing: 3) {
                    ForEach(1..<5) { n in
                        Capsule().fill(Ink.sage.opacity(0.55)).frame(width: 3, height: CGFloat(3 + n * 2))
                    }
                }.accessibilityHidden(true)
            }
            .foregroundStyle(Ink.amber)
            Divider().overlay(Ink.cream.opacity(0.25))
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(code.components(separatedBy: "\n").enumerated()), id: \.offset) { idx, line in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(String(format: "%02d", idx + 1)).foregroundStyle(Ink.sage.opacity(0.7)).accessibilityHidden(true)
                            Text(verbatim: line.isEmpty ? " " : line)
                                .foregroundStyle(line.trimmingCharacters(in: .whitespaces).hasPrefix("#") ? Ink.sage : Ink.cream)
                        }
                    }
                }.font(.system(.subheadline, design: .monospaced)).fixedSize(horizontal: true, vertical: false)
            }
        }.padding(16).background(Ink.deep, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore).accessibilityLabel("Python code. " + code)
    }
}
