import UIKit

class DrawView: UIView, UIScrollViewDelegate, DrawViewTiledLayerViewDelegate {

        var content_size = CGSize.zero {
                didSet {
                        if (content_size.width != oldValue.width || content_size.height != oldValue.height) {
                                scroll_view.contentSize = content_size
                                zoom_scale = 1
                                initial_zoom = true
                                set_min_max_zoom_scales()
                                layout_scroll_view()
                        }
                }
        }

        var maximum_zoom_scale_multiplier = 1 as CGFloat
        var maximum_zoom_scale = 1 as CGFloat
        var minimum_zoom_scale = 1 as CGFloat
        var zoom_scale = 1 as CGFloat
        var initial_zoom = true

        let scroll_view = UIScrollView()
        var draw_view_tiled_layer_view: DrawViewTiledLayerView?

        init(frame: CGRect, tappable: Bool) {
                super.init(frame: frame)

                draw_view_tiled_layer_view = DrawViewTiledLayerView(frame: CGRect.zero, delegate: self)
                scroll_view.addSubview(draw_view_tiled_layer_view!)

                scroll_view.delegate = self
                addSubview(scroll_view)

                if tappable {
                        let tap_recognizer = UITapGestureRecognizer(target: self, action: "tap_action:")
                        draw_view_tiled_layer_view?.addGestureRecognizer(tap_recognizer)
                }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
                super.layoutSubviews()

                set_min_max_zoom_scales()
                layout_scroll_view()
        }

        func layout_scroll_view() {
                let (width, height) = (bounds.width, bounds.height)

                let scaled_content_size = CGSizeApplyAffineTransform(content_size, CGAffineTransformMakeScale(zoom_scale, zoom_scale))
                if scaled_content_size.width < width {
                        scroll_view.frame.origin.x = (width - scaled_content_size.width) / 2.0
                        scroll_view.frame.size.width = scaled_content_size.width
                } else {
                        scroll_view.frame.origin.x = 0
                        scroll_view.frame.size.width = width
                }

                if scaled_content_size.height < height {
                        scroll_view.frame.origin.y = (height - scaled_content_size.height) / 2.0
                        scroll_view.frame.size.height = scaled_content_size.height
                } else {
                        scroll_view.frame.origin.y = 0
                        scroll_view.frame.size.height = height
                }

                draw_view_tiled_layer_view!.frame = CGRect(origin: CGPoint.zero, size: scaled_content_size)

                draw_view_tiled_layer_view!.set_levels_of_detail(minimum_zoom_scale: minimum_zoom_scale, maximum_zoom_scale: maximum_zoom_scale)
        }

        func set_min_max_zoom_scales() {
                let (width, height) = (bounds.width, bounds.height)

                if width > 0 && height > 0 && content_size.width > 0 && content_size.height > 0 {
                        let scale_x = width / content_size.width
                        let scale_y = height / content_size.height

                        let scale_min = min(scale_x, scale_y)
                        if scale_min != minimum_zoom_scale {
                                minimum_zoom_scale = scale_min
                                scroll_view.minimumZoomScale = minimum_zoom_scale
                        }

                        let scale_max = maximum_zoom_scale_multiplier * max(1, scale_x, scale_y)
                        if scale_max != maximum_zoom_scale {
                                maximum_zoom_scale = scale_max
                                scroll_view.maximumZoomScale = maximum_zoom_scale
                        }

                        if initial_zoom {
                                initial_zoom = false
                                set_zoom_scale(zoom_scale: minimum_zoom_scale)
                        } else if zoom_scale < minimum_zoom_scale {
                                set_zoom_scale(zoom_scale: minimum_zoom_scale)
                        } else if zoom_scale > maximum_zoom_scale {
                                set_zoom_scale(zoom_scale: maximum_zoom_scale)
                        }
                } else {
                        minimum_zoom_scale = 1
                        scroll_view.minimumZoomScale = 1
                        maximum_zoom_scale = 1
                        scroll_view.maximumZoomScale = 1
                        set_zoom_scale(zoom_scale: 1)
                }
        }

        func set_zoom_scale(zoom_scale zoom_scale: CGFloat) {
                self.zoom_scale = min(maximum_zoom_scale, max(minimum_zoom_scale, zoom_scale))
                scroll_view.zoomScale = self.zoom_scale
                let scaled_content_size = CGSizeApplyAffineTransform(content_size, CGAffineTransformMakeScale(zoom_scale, zoom_scale))
                scroll_view.contentSize = scaled_content_size
        }

        func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
                return draw_view_tiled_layer_view
        }

        func scrollViewDidZoom(scrollView: UIScrollView) {
                zoom_scale = scrollView.zoomScale
                layout_scroll_view()
        }

        func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
                zoom_scale = scrollView.zoomScale
                layout_scroll_view()
        }

        func scrollViewDidScroll(scrollView: UIScrollView) {

        }

        func draw(context context: CGContext, rect: CGRect) {

        }

        func tap_action(recognizer: UITapGestureRecognizer) {

        }

        override func setNeedsDisplay() {
                super.setNeedsDisplay()
                scroll_view.setNeedsDisplay()
                scroll_view.setNeedsLayout()
                draw_view_tiled_layer_view?.setNeedsDisplay()
                setNeedsLayout()
        }
}

protocol DrawViewTiledLayerViewDelegate: class {
        func draw (context context: CGContext, rect: CGRect) -> Void
}

class DrawViewTiledLayerView: UIView {

        unowned let delegate: DrawViewTiledLayerViewDelegate
        
        init(frame: CGRect, delegate: DrawViewTiledLayerViewDelegate) {
                self.delegate = delegate
                super.init(frame: frame)
                backgroundColor = UIColor.whiteColor()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func set_levels_of_detail(minimum_zoom_scale minimum_zoom_scale: CGFloat, maximum_zoom_scale: CGFloat) {
                let levels_of_detail = Int(floor(log(maximum_zoom_scale / minimum_zoom_scale) / log(2.0)) + 1)
                let levels_of_detail_bias = maximum_zoom_scale < 1 ? 0 : (minimum_zoom_scale <= 1 ? Int(ceil(log(maximum_zoom_scale) / log(2.0))) : levels_of_detail)

                (layer as! CATiledLayer).levelsOfDetail = levels_of_detail
                (layer as! CATiledLayer).levelsOfDetailBias = levels_of_detail_bias
                setNeedsDisplay()
        }

        override class func layerClass() -> AnyClass {
                return CATiledLayer.self
        }

        override func drawRect(rect: CGRect) {
                if let context = UIGraphicsGetCurrentContext() {
                        delegate.draw(context: context, rect: rect)
                }
        }
}
