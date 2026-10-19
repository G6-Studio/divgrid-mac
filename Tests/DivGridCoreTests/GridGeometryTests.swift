import CoreGraphics
import Testing

@testable import DivGridCore

@Suite struct GridGeometryTests {
    let grid = GridSize(columns: 6, rows: 6)
    let size = CGSize(width: 600, height: 300)

    @Test func cellAtPointMapsToGrid() {
        #expect(GridGeometry.cell(at: CGPoint(x: 1, y: 1), in: size, grid: grid) == Cell(column: 0, row: 0))
        #expect(GridGeometry.cell(at: CGPoint(x: 150, y: 80), in: size, grid: grid) == Cell(column: 1, row: 1))
        #expect(GridGeometry.cell(at: CGPoint(x: 599, y: 299), in: size, grid: grid) == Cell(column: 5, row: 5))
    }

    @Test func cellBoundariesBelongToTheNextCell() {
        #expect(GridGeometry.cell(at: CGPoint(x: 100, y: 50), in: size, grid: grid) == Cell(column: 1, row: 1))
    }

    @Test func pointsOutsideClampToEdgeCells() {
        #expect(GridGeometry.cell(at: CGPoint(x: -40, y: -10), in: size, grid: grid) == Cell(column: 0, row: 0))
        #expect(GridGeometry.cell(at: CGPoint(x: 9000, y: 9000), in: size, grid: grid) == Cell(column: 5, row: 5))
    }

    @Test func nonSquareGridHitTesting() {
        let wide = GridSize(columns: 10, rows: 2)
        #expect(GridGeometry.cell(at: CGPoint(x: 550, y: 200), in: size, grid: wide) == Cell(column: 9, row: 1))
    }

    @Test func emptySizeDoesNotCrash() {
        #expect(GridGeometry.cell(at: CGPoint(x: 5, y: 5), in: .zero, grid: grid) == Cell(column: 0, row: 0))
    }

    @Test(arguments: [
        (Cell(column: 1, row: 1), Cell(column: 3, row: 4)),
        (Cell(column: 3, row: 4), Cell(column: 1, row: 1)),
        (Cell(column: 3, row: 1), Cell(column: 1, row: 4)),
        (Cell(column: 1, row: 4), Cell(column: 3, row: 1)),
    ])
    func rangeNormalizesDragDirection(a: Cell, b: Cell) {
        let range = CellRange(from: a, to: b)
        #expect(range.columns == 1...3)
        #expect(range.rows == 1...4)
        #expect(range.contains(Cell(column: 2, row: 2)))
        #expect(!range.contains(Cell(column: 0, row: 2)))
    }

    @Test func gridSizeClamps() {
        #expect(GridSize(columns: 0, rows: 99) == GridSize(columns: 2, rows: 20))
    }

    // Frames use AppKit coordinates: origin at the bottom-left, y grows upward.
    let screen = CGRect(x: 0, y: 0, width: 1200, height: 600)

    @Test func fullGridCoversVisibleFrame() {
        let all = CellRange(columns: 0...5, rows: 0...5)
        #expect(GridGeometry.frame(for: all, in: screen, grid: grid) == screen)
    }

    @Test func topLeftCell() {
        let cell = CellRange(columns: 0...0, rows: 0...0)
        #expect(GridGeometry.frame(for: cell, in: screen, grid: grid) == CGRect(x: 0, y: 500, width: 200, height: 100))
    }

    @Test func bottomRightCell() {
        let cell = CellRange(columns: 5...5, rows: 5...5)
        #expect(GridGeometry.frame(for: cell, in: screen, grid: grid) == CGRect(x: 1000, y: 0, width: 200, height: 100))
    }

    @Test func leftHalf() {
        let half = CellRange(columns: 0...2, rows: 0...5)
        #expect(GridGeometry.frame(for: half, in: screen, grid: grid) == CGRect(x: 0, y: 0, width: 600, height: 600))
    }

    @Test func marginInsetsEverySide() {
        let all = CellRange(columns: 0...5, rows: 0...5)
        let frame = GridGeometry.frame(for: all, in: screen, grid: grid, margin: 10)
        #expect(frame == CGRect(x: 10, y: 10, width: 1180, height: 580))
    }

    @Test func offsetVisibleFrameForMenuBarAndDock() {
        // Dock on the left (80pt) and menu bar on top (25pt) of a 1280x800 display.
        let visible = CGRect(x: 80, y: 0, width: 1200, height: 775)
        let all = CellRange(columns: 0...5, rows: 0...5)
        #expect(GridGeometry.frame(for: all, in: visible, grid: grid) == visible)
    }

    @Test func secondaryDisplayWithNegativeOrigin() {
        let left = CGRect(x: -1920, y: 200, width: 1920, height: 1080)
        let cell = CellRange(columns: 0...0, rows: 5...5)
        let frame = GridGeometry.frame(for: cell, in: left, grid: grid)
        #expect(frame == CGRect(x: -1920, y: 200, width: 320, height: 180))
    }

    @Test func hugeMarginNeverProducesEmptyFrame() {
        let cell = CellRange(columns: 0...0, rows: 0...0)
        let frame = GridGeometry.frame(for: cell, in: screen, grid: grid, margin: 500)
        #expect(frame.width >= 1 && frame.height >= 1)
    }
}
