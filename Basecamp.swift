import SwiftUI

private enum CampTab: String, CaseIterable {
    case camp = "Basecamp", trail = "Trail map", log = "Field log"
    var symbol: String {
        switch self {
        case .camp: "tent.fill"
        case .trail: "map.fill"
        case .log: "book.closed.fill"
        }
    }
}

struct Basecamp: View {
    @EnvironmentObject private var journal: Journal
    @State private var tab: CampTab = .camp
    @State private var activeMission: Mission?
    @State private var expanded: Int?
    private var featured: Mission { journal.current ?? Trailbook.missions[0] }

    init() {
        #if DEBUG && targetEnvironment(simulator)
        switch ScreenshotScreen.current {
        case .trailMap:
            _tab = State(initialValue: .trail)
            _expanded = State(initialValue: Trailbook.routes[0].id)
        case .fieldLog:
            _tab = State(initialValue: .log)
        case .missionBriefing, .readTheSignal, .buildALine:
            _activeMission = State(initialValue: Trailbook.routes[0].missions[0])
        case .missionComplete:
            _activeMission = State(initialValue: Trailbook.routes[0].missions[2])
        default:
            break
        }
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            masthead.padding(.horizontal, 22).padding(.top, 5).padding(.bottom, 9)
                .frame(maxWidth: 620)
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        switch tab {
                        case .camp: camp
                        case .trail: trail
                        case .log: logbook
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 7).padding(.bottom, 22)
                    .frame(maxWidth: 620).frame(maxWidth: .infinity)
                }
                .id(tab)
                .onChange(of: tab) { _, destination in
                    guard destination == .trail else { return }
                    let routeID = expanded ?? Trailbook.route(for: featured).id
                    if routeID > 1 { reader.scrollTo(routeID, anchor: .top) }
                }
            }
            footer
        }
        .background(Ink.paper.ignoresSafeArea()).foregroundStyle(Ink.pine)
        .fullScreenCover(item: $activeMission) { mission in
            MissionRoom(mission: mission, checkpoint: journal.checkpoint(mission))
                .environmentObject(journal)
        }
    }

    private var masthead: some View {
        HStack(spacing: 7) {
            Patch(symbol: "tree.fill", size: 29)
            Text("Patchwood").font(.custom("Georgia-Bold", size: 22)).tracking(-1.2)
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill").foregroundStyle(Ink.clay)
                Text("\(journal.xp) XP")
            }
            .font(.system(.caption, design: .monospaced, weight: .bold))
            .padding(.horizontal, 11).padding(.vertical, 6)
            .background(Ink.card, in: Capsule()).overlay { Capsule().strokeBorder(Ink.line) }
            .accessibilityElement(children: .combine)
        }
    }

    private func heading(_ title: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Rectangle().fill(Ink.clay).frame(width: 18, height: 2)
                Locator(label).foregroundStyle(Ink.moss)
            }
            Folio(title, 41).accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder private var camp: some View {
        heading("Basecamp", label: "Python field course · 100 levels")
        Button { activeMission = featured } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    GeometryReader { geo in
                        Image("Lookout").resizable().scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height).clipped()
                    }
                    Pip().frame(width: 136, height: 136).padding(.trailing, 12).padding(.bottom, 2)
                }
                .frame(height: 145)
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        Circle().fill(Ink.amber).frame(width: 6, height: 6)
                        Locator(journal.current == nil ? "Practice channel" : "On air with Pip")
                    }
                    .foregroundStyle(Ink.cream).padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Ink.deep, in: Capsule()).padding(12)
                }
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Locator((journal.saved(featured) ? "Continue" : journal.current == nil ? "Replay" : "Up next") + " · Level \(Trailbook.number(of: featured))")
                            .foregroundStyle(Ink.amber)
                        Folio(featured.title, 26).foregroundStyle(Ink.cream)
                        Text(featured.skill + "  ·  3 challenges").font(.subheadline).foregroundStyle(Ink.sage)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.right").font(.title3.bold()).foregroundStyle(Ink.deep)
                        .frame(width: 44, height: 44).background(Ink.amber, in: Circle())
                }
                .padding(.horizontal, 16).padding(.vertical, 13).background(Ink.deep)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain).accessibilityLabel("Open mission: " + featured.title)
        .accessibilityIdentifier("featuredMission")

        let route = Trailbook.route(for: featured)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Folio("Your trail", 25).accessibilityAddTraits(.isHeader)
                Spacer()
                Button { expanded = route.id; tab = .trail } label: {
                    HStack(spacing: 4) { Text("View map"); Image(systemName: "arrow.up.right") }
                        .font(.subheadline.weight(.semibold)).padding(.vertical, 6)
                }.buttonStyle(.plain)
            }
            FieldCard {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Patch(symbol: route.symbol, size: 37)
                        VStack(alignment: .leading, spacing: 3) {
                            Locator(String(format: "Route %02d", route.id)).foregroundStyle(Ink.clay)
                            Text(route.name).font(.headline)
                        }
                        Spacer()
                        Text("\(journal.count(route))/\(route.missions.count)").font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(Ink.moss)
                    }
                    Divider().overlay(Ink.line).padding(.top, 12)
                    ForEach(route.missions) { lesson in
                        lessonRow(lesson, number: Trailbook.number(of: lesson))
                    }
                }
            }
        }
    }

    private func lessonRow(_ mission: Mission, number: Int) -> some View {
        let isDone = journal.completed(mission)
        let isOpen = journal.unlocked(mission)
        return Button { activeMission = mission } label: {
            HStack(spacing: 11) {
                ZStack {
                    Circle().fill(isDone ? Ink.pine : isOpen ? Ink.amber : Ink.paper)
                    Circle().strokeBorder(isOpen ? Ink.pine.opacity(0.35) : Ink.line)
                    if isDone {
                        Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(Ink.cream)
                    } else {
                        Text(String(format: "%02d", number)).font(.system(.caption2, design: .monospaced, weight: .bold))
                    }
                }.frame(width: 29, height: 29)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mission.title).font(.subheadline.weight(.semibold))
                    Text(mission.skill).font(.caption).foregroundStyle(Ink.moss)
                }
                Spacer()
                Image(systemName: isOpen ? "chevron.right" : "lock.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(isOpen ? Ink.pine : Ink.moss)
            }
            .foregroundStyle(isOpen ? Ink.pine : Ink.moss).frame(minHeight: 48)
            .padding(.top, 3).contentShape(Rectangle())
        }
        .buttonStyle(.plain).disabled(!isOpen)
        .accessibilityLabel(mission.title + (isDone ? ", completed, replay" : isOpen ? ", available" : ", locked"))
        .accessibilityIdentifier("lesson-" + mission.id)
    }

    @ViewBuilder private var trail: some View {
        heading("Trail map", label: "Python field course")
        Text("\(journal.finishedLevels) of \(Trailbook.missions.count) levels complete · \(Trailbook.routes.count) forest stations").font(.subheadline).foregroundStyle(Ink.moss)
        ForEach(Trailbook.routes) { route in
            let open = (expanded ?? Trailbook.route(for: featured).id) == route.id
            FieldCard {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { expanded = open ? 0 : route.id }
                    } label: {
                        HStack(spacing: 12) {
                            Patch(symbol: route.symbol, size: 50, muted: !journal.unlocked(route.missions[0]))
                            VStack(alignment: .leading, spacing: 4) {
                                Locator(String(format: "Route %02d · %d/%d", route.id, journal.count(route), route.missions.count)).foregroundStyle(Ink.clay)
                                Folio(route.name, 21)
                                Text(route.skill).font(.caption).foregroundStyle(Ink.moss)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: open ? "chevron.up" : "chevron.down").font(.caption.bold())
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("route-\(route.id)")
                    HStack(spacing: 4) {
                        ForEach(route.missions) { mission in
                            Capsule().fill(journal.completed(mission) ? Ink.pine : Ink.line).frame(height: 4)
                        }
                    }.padding(.top, 12).accessibilityHidden(true)
                    if open {
                        ForEach(route.missions) { mission in
                            lessonRow(mission, number: Trailbook.number(of: mission))
                        }
                        if !journal.unlocked(route.missions[0]) {
                            Text("Complete the previous route to enter.").font(.caption).foregroundStyle(Ink.moss).padding(.top, 6)
                        }
                    }
                }
            }
            .id(route.id)
        }
    }

    @ViewBuilder private var logbook: some View {
        heading("Field log", label: "Operator record")
        HStack(spacing: 12) {
            metric("bolt.fill", "\(journal.xp)", "Total XP")
            TimelineView(.periodic(from: .now, by: 60)) { context in
                metric("flame.fill", "\(journal.streak(at: context.date))", "Day streak")
            }
        }
        Folio("Station patches", 25)
        ForEach(Trailbook.routes) { route in
            let claimed = journal.count(route) == route.missions.count
            FieldCard {
                HStack(spacing: 15) {
                    Patch(symbol: route.symbol, size: 57, muted: !claimed)
                    VStack(alignment: .leading, spacing: 5) {
                        Locator(claimed ? "Earned" : "\(journal.count(route)) of \(route.missions.count) levels").foregroundStyle(claimed ? Ink.clay : Ink.moss)
                        Folio(route.patch, 21)
                        Text(route.name).font(.caption).foregroundStyle(Ink.moss)
                    }
                    Spacer()
                }
            }
        }
        Text("Earn a patch by completing every level at its station. Replaying a mission keeps your streak going.")
            .font(.footnote).foregroundStyle(Ink.moss)
    }

    private func metric(_ icon: String, _ value: String, _ label: String) -> some View {
        FieldCard {
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: icon).foregroundStyle(Ink.clay)
                Folio(value, 32)
                Locator(label).foregroundStyle(Ink.moss)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Ink.line).frame(height: 1)
            HStack(spacing: 3) {
                ForEach(CampTab.allCases, id: \.self) { item in
                    Button { tab = item } label: {
                        VStack(spacing: 3) {
                            Image(systemName: item.symbol).font(.system(size: 17, weight: .bold))
                                .frame(width: 57, height: 25)
                                .background(tab == item ? Ink.sage : Color.clear, in: Capsule())
                            Text(item.rawValue).font(.caption2.weight(.semibold))
                        }.foregroundStyle(tab == item ? Ink.pine : Ink.moss).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(tab == item ? .isSelected : [])
                    .accessibilityIdentifier("tab-" + item.rawValue)
                }
            }
            .padding(.top, 8).padding(.bottom, 1).frame(maxWidth: 620)
        }.background(Ink.paper)
    }
}
