import AppKit
import DivGridCore
import SwiftUI

struct GridView: View {
    let grid: GridSize
    @ObservedObject var target: TargetInfo
    let onHover: (Bool) -> Void
    let onSettings: () -> Void
    let onSelect: (CellRange) -> Void

    @State private var dragStart: Cell?
    @State private var dragCurrent: Cell?

    private var selection: CellRange? {
        guard let dragStart, let dragCurrent else { return nil }
        return CellRange(from: dragStart, to: dragCurrent)
    }

    var body: some View {
        VStack(spacing: GridPanel.Layout.headerSpacing) {
            header
            cells
        }
        .padding(GridPanel.Layout.inset)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .onHover(perform: onHover)
    }

    private var header: some View {
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
        .frame(height: GridPanel.Layout.headerHeight)
    }

    private var cells: some View {
        GeometryReader { geometry in
            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                ForEach(0..<grid.rows, id: \.self) { row in
                    GridRow {
                        ForEach(0..<grid.columns, id: \.self) { column in
                            let isSelected = selection?.contains(Cell(column: column, row: row)) ?? false
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.12))
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { drag in
                        if dragStart == nil {
                            dragStart = GridGeometry.cell(at: drag.startLocation, in: geometry.size, grid: grid)
                        }
                        dragCurrent = GridGeometry.cell(at: drag.location, in: geometry.size, grid: grid)
                    }
                    .onEnded { _ in
                        if let selection { onSelect(selection) }
                        dragStart = nil
                        dragCurrent = nil
                    }
            )
        }
    }
}
