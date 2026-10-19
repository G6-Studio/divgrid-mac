import CoreGraphics

/// Number of columns and rows in the selection grid.
public struct GridSize: Equatable, Sendable {
    public static let allowedRange = 2...20
    public static let `default` = GridSize(columns: 6, rows: 6)

    public let columns: Int
    public let rows: Int

    /// Values outside `allowedRange` are clamped.
    public init(columns: Int, rows: Int) {
        self.columns = columns.clamped(to: Self.allowedRange)
        self.rows = rows.clamped(to: Self.allowedRange)
    }
}

public struct Cell: Equatable, Sendable {
    public let column: Int
    public let row: Int

    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }
}

/// An inclusive rectangle of cells, normalized so the drag direction doesn't matter.
public struct CellRange: Equatable, Sendable {
    public let columns: ClosedRange<Int>
    public let rows: ClosedRange<Int>

    public init(columns: ClosedRange<Int>, rows: ClosedRange<Int>) {
        self.columns = columns
        self.rows = rows
    }

    /// The range spanned by the two corner cells of a drag, in any order.
    public init(from a: Cell, to b: Cell) {
        self.init(
            columns: min(a.column, b.column)...max(a.column, b.column),
            rows: min(a.row, b.row)...max(a.row, b.row))
    }

    public func contains(_ cell: Cell) -> Bool {
        columns.contains(cell.column) && rows.contains(cell.row)
    }
}

public enum GridGeometry {
    /// The cell under `point`, where `point` is in a top-left-origin space of the given size.
    /// Points outside the grid clamp to the nearest edge cell.
    public static func cell(at point: CGPoint, in size: CGSize, grid: GridSize) -> Cell {
        guard size.width > 0, size.height > 0 else { return Cell(column: 0, row: 0) }
        let column = Int((point.x / size.width * CGFloat(grid.columns)).rounded(.down))
        let row = Int((point.y / size.height * CGFloat(grid.rows)).rounded(.down))
        return Cell(
            column: column.clamped(to: 0...(grid.columns - 1)),
            row: row.clamped(to: 0...(grid.rows - 1)))
    }

    /// The frame, in AppKit screen coordinates (bottom-left origin), that `range` covers on a display
    /// whose usable area is `visibleFrame`. `margin` insets the result on every side.
    public static func frame(
        for range: CellRange, in visibleFrame: CGRect, grid: GridSize, margin: CGFloat = 0
    ) -> CGRect {
        let cellWidth = visibleFrame.width / CGFloat(grid.columns)
        let cellHeight = visibleFrame.height / CGFloat(grid.rows)
        let width = CGFloat(range.columns.count) * cellWidth
        let height = CGFloat(range.rows.count) * cellHeight
        let top = visibleFrame.maxY - CGFloat(range.rows.lowerBound) * cellHeight
        return CGRect(
            x: visibleFrame.minX + CGFloat(range.columns.lowerBound) * cellWidth + margin,
            y: top - height + margin,
            width: max(1, width - 2 * margin),
            height: max(1, height - 2 * margin))
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
