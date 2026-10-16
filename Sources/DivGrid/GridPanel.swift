import AppKit
import SwiftUI

/// Lets the very first click on the (never-activating) panel reach the grid.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class GridPanel: NSPanel {
    var onCancel: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { onCancel?() }
}

/// Click-through accent outline drawn around the window that will be resized.
final class OutlinePanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        let v = NSView()
        v.wantsLayer = true
        v.layer?.borderWidth = 3
        v.layer?.borderColor = NSColor.controlAccentColor.cgColor
        v.layer?.cornerRadius = 10
        v.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
        contentView = v
    }
}

final class TargetInfo: ObservableObject {
    @Published var icon: NSImage?
    @Published var appName = ""
    @Published var windowTitle = ""
}

struct GridView: View {
    let columns: Int
    let rows: Int
    @ObservedObject var target: TargetInfo
    let onHover: (Bool) -> Void
    let onSettings: () -> Void
    let onSelect: (ClosedRange<Int>, ClosedRange<Int>) -> Void

    @State private var start: (c: Int, r: Int)?
    @State private var current: (c: Int, r: Int)?

    private func cell(at p: CGPoint, in size: CGSize) -> (c: Int, r: Int) {
        (min(max(Int(p.x / size.width * CGFloat(columns)), 0), columns - 1),
         min(max(Int(p.y / size.height * CGFloat(rows)), 0), rows - 1))
    }

    private func isSelected(_ c: Int, _ r: Int) -> Bool {
        guard let s = start, let e = current else { return false }
        return (min(s.c, e.c)...max(s.c, e.c)).contains(c) && (min(s.r, e.r)...max(s.r, e.r)).contains(r)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if let icon = target.icon {
                    Image(nsImage: icon).resizable().frame(width: 28, height: 28)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(target.appName).font(.headline).lineLimit(1)
                    if !target.windowTitle.isEmpty {
                        Text(target.windowTitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape").font(.title3).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .frame(height: 36)

            GeometryReader { geo in
                Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                    ForEach(0..<rows, id: \.self) { r in
                        GridRow {
                            ForEach(0..<columns, id: \.self) { c in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected(c, r) ? Color.accentColor : Color.primary.opacity(0.12))
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { v in
                            if start == nil { start = cell(at: v.startLocation, in: geo.size) }
                            current = cell(at: v.location, in: geo.size)
                        }
                        .onEnded { _ in
                            if let s = start, let e = current {
                                onSelect(min(s.c, e.c)...max(s.c, e.c), min(s.r, e.r)...max(s.r, e.r))
                            }
                            start = nil; current = nil
                        }
                )
            }
        }
        .padding(10)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .onHover(perform: onHover)
    }
}
