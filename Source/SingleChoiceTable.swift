import UIKit

protocol SingleChoiceTableDelegate: class {
        func single_choice_table(singleChoiceTable: SingleChoiceTable, didSelectColNameWithIndex: Int) -> Void
        func single_choice_table(singleChoiceTable: SingleChoiceTable, didSelectCellWithRowIndex: Int, andColIndex: Int) -> Void
}

class SingleChoiceTable: UIView, TiledScrollViewDelegate {

        let font = font_body
        let line_width = 1.0 as CGFloat

        override var frame: CGRect { didSet { propertiesDidChange() } }

        var rowNames: [String] = [] { didSet { propertiesDidChange() } }
        var colNames: [String] = [] { didSet { propertiesDidChange() } }
        var choices: [Int] = [] { didSet { propertiesDidChange() } }      // choices.count == rowNames.count. Each choice is in [0, colNames.count - 1]
        weak var delegate: SingleChoiceTableDelegate?

        let tiledScrollView = TiledScrollView(frame: CGRect.zero)

        var content_size = CGSize.zero
        var maximum_zoom_scale = 1.0 as CGFloat
        var minimum_zoom_scale = 1.0 as CGFloat

        let margin = 10 as CGFloat
        let rowWidth = 50 as CGFloat
        let rowHeight = 50 as CGFloat
        let circle_radius = 18 as CGFloat
        let circle_color = circle_color_green
        var rowNamesWidth = 0 as CGFloat
        var colNamesHeight = 0 as CGFloat

        override init(frame: CGRect) {
                super.init(frame: frame)
                tiledScrollView.delegate = nil
                addSubview(tiledScrollView)
        }

        required init(coder aDecoder: NSCoder) {fatalError("This initializer should not be called")}

        func tap_action(location location: CGPoint) {
                let (row, col) = row_col_for_point(point: location)
                if row == 0 && col > 0 {
                        delegate?.single_choice_table(self, didSelectColNameWithIndex: col - 1)
                } else if row > 0 && col > 0 {
                        choices[row - 1] = col - 1
                        delegate?.single_choice_table(self, didSelectCellWithRowIndex: row - 1, andColIndex: col - 1)
                }
        }

        func propertiesDidChange() {
                if rowNames.count > 0 && colNames.count > 0 && choices.count == rowNames.count {
                        tiledScrollView.frame = bounds
                        rowNamesWidth = drawing_max_width(names: rowNames, font: font) + margin
                        colNamesHeight = drawing_max_width(names: colNames, font: font) + margin
                        content_size.width = rowNamesWidth + CGFloat(colNames.count) * rowWidth
                        content_size.height = colNamesHeight + CGFloat(rowNames.count) * rowHeight
                        tiledScrollView.delegate = self
                } else {
                        tiledScrollView.delegate = nil
                }
        }

        func row_col_for_point(point point: CGPoint) -> (Int, Int) {
                var row = 0
                var col = 0
                if point.x >= rowNamesWidth {
                        col = Int(floor((point.x - rowNamesWidth) / rowWidth)) + 1
                }
                if point.y >= colNamesHeight {
                        row = Int(floor((point.y - colNamesHeight) / rowHeight)) + 1
                }
                return (row, col)
        }

        func draw(context context: CGContext, rect: CGRect) {
                let (upperLeftRow, upperLeftCol) = row_col_for_point(point: rect.origin)
                let (lowerRightRow, lowerRightCol) = row_col_for_point(point: CGPoint(x: CGRectGetMaxX(rect), y: CGRectGetMaxY(rect)))

                if upperLeftRow == 0 && upperLeftCol == 0 {
                        drawing_draw_cell(context: context, origin_x: 0, origin_y: 0, width: rowNamesWidth, height: colNamesHeight, line_width: line_width, top_line: false, right_line: true, bottom_line: true, left_line: false)
                }
                if upperLeftCol >= 0 {
                        for row in max(0, upperLeftRow - 1)..<min(lowerRightRow, rowNames.count) {
                                drawRowName(context: context, index: row)
                        }
                }
                if upperLeftRow == 0 {
                        for col in max(0, upperLeftCol - 1)..<min(lowerRightCol, colNames.count) {
                                drawColName(context: context, index: col)
                        }
                }
                for row in max(0, upperLeftRow - 1)..<min(lowerRightRow, rowNames.count) {
                        for col in max(0, upperLeftCol - 1)..<min(lowerRightCol, colNames.count) {
                                drawCell(context: context, row: row, col: col, choice: choices[row] == col)
                        }
                }
        }

        func drawRowName(context context: CGContext, index: Int) {
                let origin_y = colNamesHeight + CGFloat(index) * rowHeight
                let name = rowNames[index]
                let rect = CGRect(x: 0, y: origin_y, width: rowNamesWidth, height: rowHeight)
                let astring = astring_font_size_color(string: name, font: font, font_size: nil, color: nil)

                drawing_draw_cell_with_attributed_text(context: context, rect: rect, line_width: line_width, attributed_text: astring, background_color: nil, horizontal_cell: true, margin_horizontal: 0, margin_vertical: 0, text_centered: false, circle_color: nil, circle_radius: 0, top_line: false, right_line: true, bottom_line: index != rowNames.count - 1, left_line: false)
        }

        func drawColName(context context: CGContext, index: Int) {
                let origin_x = rowNamesWidth + CGFloat(index) * rowWidth
                let name = colNames[index]
                let rect = CGRect(x: origin_x, y: 0, width: rowWidth, height: colNamesHeight)
                let astring = astring_font_size_color(string: name, font: font, font_size: nil, color: nil)

                drawing_draw_cell_with_attributed_text(context: context, rect: rect, line_width: line_width, attributed_text: astring, background_color: nil, horizontal_cell: false, margin_horizontal: 0, margin_vertical: 0, text_centered: false, circle_color: nil, circle_radius: 0, top_line: false, right_line: index != colNames.count - 1, bottom_line: true, left_line: false)
        }

        func drawCell(context context: CGContext, row: Int, col: Int, choice: Bool) {
                let origin_x = rowNamesWidth + CGFloat(col) * rowWidth
                let origin_y = colNamesHeight + CGFloat(row) * rowHeight
                if choice {
                        drawing_draw_cell_with_centered_circle(context: context, origin_x: origin_x, origin_y: origin_y, width: rowWidth, height: rowHeight, line_width: line_width, top_line: false, right_line: col != colNames.count - 1, bottom_line: row != rowNames.count - 1, left_line: false, radius: circle_radius, color: circle_color)
                } else {
                        drawing_draw_cell(context: context, origin_x: origin_x, origin_y: origin_y, width: rowWidth, height: rowHeight, line_width: line_width, top_line: false, right_line: col != colNames.count - 1, bottom_line: row != rowNames.count - 1, left_line: false)
                }
        }

        func scroll_view_did_end_zooming(zoom_scale zoom_scale: CGFloat) {}
}
