import UIKit

protocol PCA2dDelegate: class {
        func scroll_view_did_end_zooming(zoom_scale zoom_scale: CGFloat)
        func tap_action()
}

class PCA2dPlot: TiledScrollViewDelegate {

        var delegate: PCA2dDelegate?

        let width = 300 as CGFloat
        var content_size = CGSize(width: 300, height: 300)
        var maximum_zoom_scale = 1 as CGFloat
        var minimum_zoom_scale = 1 as CGFloat

        var circle_radius = 2 as CGFloat
        var names_font_size = 8 as CGFloat
        var axis_title_font_size = 4 as CGFloat

        var points_x = [] as [Double]
        var points_y = [] as [Double]
        var names = [] as [String]?
        var colors = [] as [UIColor]
        var axis_titles: [String]?

        var (min_x, max_x, min_y, max_y) = (0, 0, 0, 0) as (Double, Double, Double, Double)
        var (value_center_x, value_center_y) = (0, 0) as (Double, Double)

        var value_to_geometry_multiplier = 0 as CGFloat

        var tick_values = [] as [Double]

        var points = [] as [CGPoint]

        func update(points_x points_x: [Double], points_y: [Double], names: [String]?, colors: [UIColor]?, axis_titles: [String]?, symbol_size: Double) {
                self.points_x = points_x
                self.points_y = points_y
                self.names = names
                self.colors = colors == nil ? [UIColor](count: points_x.count, repeatedValue: UIColor.blueColor()) : colors!
                self.axis_titles = axis_titles

                (min_x, max_x) = math_min_max(numbers: points_x)
                (min_x, max_x) = padding_min_max(min: min_x, max: max_x)
                (min_y, max_y) = math_min_max(numbers: points_y)
                (min_y, max_y) = padding_min_max(min: min_y, max: max_y)

                value_center_x = (min_x + max_x) / 2
                value_center_y = (min_y + max_y) / 2

                let extent = max(max_x - min_x, max_y - min_y)
                if extent == 0 {
                        value_to_geometry_multiplier = 0
                } else {
                        value_to_geometry_multiplier = width / CGFloat(extent)
                }

                points = []
                for i in 0 ..< points_x.count {
                        let point = value_to_point(value_x: points_x[i], value_y: points_y[i])
                        points.append(point)
                }

                tick_values = []
                let max_number = max(abs(min_x), abs(max_x), abs(min_y), abs(max_y))
                let positive_tick_values = math_pca_tick_values(value: max_number)
                for tick_value in positive_tick_values {
                        tick_values.append(tick_value)
                        tick_values.append(-tick_value)
                }

                circle_radius = CGFloat(2 + symbol_size * 6)
                names_font_size = CGFloat(4 + symbol_size * 20)
                axis_title_font_size = CGFloat(2 + symbol_size * 4)
        }

        func padding_min_max(min min: Double, max: Double) -> (min: Double, max: Double) {
                let padding = (max - min) * 0.1
                return (min - padding, max + padding)
        }

        func value_to_point(value_x value_x: Double, value_y: Double) -> CGPoint {
                let x = CGFloat(value_x - value_center_x) * value_to_geometry_multiplier + width / 2
                let y = -CGFloat(value_y - value_center_y) * value_to_geometry_multiplier + width / 2
                return CGPoint(x: x, y: y)
        }

        func draw(context context: CGContext, rect: CGRect) {
                CGContextSaveGState(context)
                CGContextSetLineWidth(context, 1)
                CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)

                draw_x_axis(context: context)
                draw_y_axis(context: context)

                if let names = names {
                        for index in 0 ..< points.count {
                                draw_name(context: context, name: names[index], index: index, rect: rect)
                        }
                } else {
                        for index in 0 ..< points.count {
                                draw_circle(context: context, index: index, rect: rect)
                        }
                }

                CGContextRestoreGState(context)
        }

        func draw_x_axis(context context: CGContext) {
                var value_y = 0 as Double
                if min_y > 0 || max_y < 0 {
                        value_y = min_y + 0.1 * (max_y - min_y)
                }

                let point_y = value_to_point(value_x: min_x, value_y: value_y).y

                let point_x_min = 20 as CGFloat
                let point_x_max = width - 20

                let start_point = CGPoint(x: point_x_min, y: point_y)
                let end_point = CGPoint(x: point_x_max, y: point_y)
                Drawing.drawLine(context: context, startPoint: start_point, endPoint: end_point)
                let arrow_size = 6 as CGFloat
                var arrow_point = CGPoint(x: end_point.x - arrow_size, y: end_point.y - 0.8 * arrow_size)
                Drawing.drawLine(context: context, startPoint: end_point, endPoint: arrow_point)
                arrow_point = CGPoint(x: end_point.x - arrow_size, y: end_point.y + 0.8 * arrow_size)
                Drawing.drawLine(context: context, startPoint: end_point, endPoint: arrow_point)

                if let axis_titles = axis_titles {
                        let title = axis_titles[0]
                        let astring = astring_font_size_color(string: title, font: font_footnote, font_size: axis_title_font_size)
                        let text_origin = CGPoint(x: end_point.x - astring.size().width, y: end_point.y + 10)
                        Drawing.drawAttributedText(context: context, attributedText: astring, origin: text_origin, horizontal: true)
                }

                for tick_value in tick_values {
                        let point_x = self.value_to_point(value_x: tick_value, value_y: min_y).x
                        if point_x < 30 || point_x > (width - 30) {
                                continue
                        }

                        let start_point = CGPoint(x: point_x, y: point_y + 5)
                        let end_point = CGPoint(x: point_x, y: point_y - 5)
                        Drawing.drawLine(context: context, startPoint: start_point, endPoint: end_point)

                        let value_as_string = decimal_string(number: tick_value, fraction_digits: 1)
                        let astring = astring_font_size_color(string: value_as_string, font: font_footnote, font_size: 4)
                        let text_origin = CGPoint(x: point_x - astring.size().width / 2, y: point_y + 10)
                        Drawing.drawAttributedText(context: context, attributedText: astring, origin: text_origin, horizontal: true)
                }
        }

        func draw_y_axis(context context: CGContext) {
                var value_x = 0 as Double
                if min_x > 0 || max_x < 0 {
                        value_x = min_x + 0.1 * (max_x - min_x)
                }

                let point_x = value_to_point(value_x: value_x, value_y: min_y).x

                let point_y_min = 20 as CGFloat
                let point_y_max = width - 20

                let start_point = CGPoint(x: point_x, y: point_y_max)
                let end_point = CGPoint(x: point_x, y: point_y_min)
                Drawing.drawLine(context: context, startPoint: start_point, endPoint: end_point)
                let arrow_size = 6 as CGFloat
                var arrow_point = CGPoint(x: end_point.x - arrow_size, y: end_point.y + 0.8 * arrow_size)
                Drawing.drawLine(context: context, startPoint: end_point, endPoint: arrow_point)
                arrow_point = CGPoint(x: end_point.x + arrow_size, y: end_point.y + 0.8 * arrow_size)
                Drawing.drawLine(context: context, startPoint: end_point, endPoint: arrow_point)

                if let axis_titles = axis_titles {
                        let title = axis_titles[1]
                        let astring = astring_font_size_color(string: title, font: font_footnote, font_size: axis_title_font_size)
                        let text_origin = CGPoint(x: end_point.x - 10 - astring.size().width, y: end_point.y)
                        Drawing.drawAttributedText(context: context, attributedText: astring, origin: text_origin, horizontal: true)
                }

                for tick_value in tick_values {
                        let point_y = self.value_to_point(value_x: min_x, value_y: tick_value).y
                        if point_y < 30 || point_y > (width - 30) {
                                continue
                        }

                        let start_point = CGPoint(x: point_x - 5, y: point_y)
                        let end_point = CGPoint(x: point_x + 5, y: point_y)
                        Drawing.drawLine(context: context, startPoint: start_point, endPoint: end_point)

                        let value_as_string = decimal_string(number: tick_value, fraction_digits: 1)
                        let astring = astring_font_size_color(string: value_as_string, font: font_footnote, font_size: 4)
                        let text_origin = CGPoint(x: point_x - 10 - astring.size().width, y: point_y - astring.size().height / 2)
                        Drawing.drawAttributedText(context: context, attributedText: astring, origin: text_origin, horizontal: true)
                }
        }

        func draw_circle(context context: CGContext, index: Int, rect: CGRect) {
                let point = points[index]
                let color = colors[index]
                Drawing.drawCircle(context: context, centerX: point.x, centerY: point.y, radius: circle_radius, color: color)
        }

        func draw_name(context context: CGContext, name: String, index: Int, rect: CGRect) {
                let point = points[index]
                let color = colors[index]
                let astring = astring_font_size_color(string: name, font: font_footnote, font_size: names_font_size, color: color)
                let origin = CGPoint(x: point.x - astring.size().width / 2, y: point.y - astring.size().height / 2)
                Drawing.drawAttributedString(context: context, attributedString: astring, origin: origin, horizontal: true)
        }

        func scroll_view_did_end_zooming(zoom_scale zoom_scale: CGFloat) {
                delegate?.scroll_view_did_end_zooming(zoom_scale: zoom_scale)
        }

        func tap_action(location location: CGPoint) {
                delegate?.tap_action()
        }
}