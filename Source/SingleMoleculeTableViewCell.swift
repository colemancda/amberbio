import UIKit

let single_molecule_table_view_cell_height = 500 as CGFloat

class SingleMoleculeTableViewCell: UITableViewCell {

        var molecule_index = 0
        var molecule_name = ""
        var factor_name: String?
        var annotation_names = [] as [String]
        var molecule_annotation_values = [] as [String]

        let inset_view = UIView()

        let molecule_name_button = UIButton(type: .System)
        var pdf_txt_buttons: PdfTxtButtons!

        let tiled_scroll_view = TiledScrollView(frame: CGRect.zero)
        var single_molecule_plot: SingleMoleculePlot?

        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)

                contentView.backgroundColor = UIColor.whiteColor()

                inset_view.clipsToBounds = true
                inset_view.layer.cornerRadius = 20
                inset_view.layer.borderWidth = 1
                inset_view.layer.borderColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1.0).CGColor
                contentView.addSubview(inset_view)

                molecule_name_button.addTarget(self, action: "molecule_name_action", forControlEvents: .TouchUpInside)
                inset_view.addSubview(molecule_name_button)

                pdf_txt_buttons = PdfTxtButtons(target: self, pdf_action: "pdf_action", txt_action: nil)
                inset_view.addSubview(pdf_txt_buttons)

                inset_view.addSubview(tiled_scroll_view)
        }

        required init(coder aDecoder: NSCoder) {fatalError("This initializer should not be called")}

        override func layoutSubviews() {
                super.layoutSubviews()

                inset_view.frame = CGRectInset(contentView.bounds, 10, 5)

                let inset_width = inset_view.frame.width
                let inset_height = inset_view.frame.height

                let top_margin = 5 as CGFloat
                let margin = 20 as CGFloat

                molecule_name_button.sizeToFit()
                molecule_name_button.center = CGPoint(x: inset_view.frame.width / 2.0, y: top_margin + molecule_name_button.frame.height / 2.0)

                var origin_y = CGRectGetMaxY(molecule_name_button.frame) + 5

                let origin_x = (inset_width - pdf_txt_buttons.contentSize.width) / 2
                pdf_txt_buttons.frame.size = pdf_txt_buttons.contentSize
                pdf_txt_buttons.frame.origin = CGPoint(x: origin_x, y: origin_y)

                origin_y += pdf_txt_buttons.contentSize.height + 5

                if let single_molecule_plot = single_molecule_plot {
                        let single_molecule_rect = CGRect(x: margin, y: origin_y, width: inset_width - 2 * margin, height: inset_height - origin_y)

                        let zoom_horizontal = max(0.2, min(1, single_molecule_rect.width / single_molecule_plot.content_size.width))
                        let zoom_vertical = max(0.2, min(1, single_molecule_rect.height / single_molecule_plot.content_size.height))

                        single_molecule_plot.minimum_zoom_scale = min(zoom_horizontal, zoom_vertical)

                        tiled_scroll_view.frame = single_molecule_rect
                        tiled_scroll_view.scroll_view.zoomScale = single_molecule_plot.minimum_zoom_scale
                }
        }

        func update(molecule_index molecule_index: Int, molecule_name: String, factor_name: String?, annotation_names: [String], molecule_annotation_values: [String], single_plot_names: [String], single_plot_colors: [[UIColor]], single_plot_values: [[Double]]) {
                self.molecule_index = molecule_index
                self.molecule_name = molecule_name
                self.factor_name = factor_name
                self.annotation_names = annotation_names
                self.molecule_annotation_values = molecule_annotation_values

                molecule_name_button.setAttributedTitle(astring_font_size_color(string: molecule_name, font: nil, font_size: 20, color: nil), forState: .Normal)

                single_molecule_plot = SingleMoleculePlot(names: single_plot_names, colors: single_plot_colors, values: single_plot_values)
                tiled_scroll_view.delegate = single_molecule_plot
        }

        func pdf_action() {
                let file_name_stem = "single-molecule-plot"

                var description = "Plot of molecule \(molecule_name).\n"
                if let factor_name = factor_name {
                        description += " The factor is \(factor_name).\n"
                }

                for i in 0 ..< annotation_names.count {
                        let annotation_name = annotation_names[i]
                        let value = molecule_annotation_values[i]
                        let text = "\(annotation_name): \(value).\n"
                        description += text
                }

                if let single_molecule_plot = single_molecule_plot {
                        state.insert_pdf_result_file(file_name_stem: file_name_stem, description: description, content_size: single_molecule_plot.content_size, draw: single_molecule_plot.draw)
                }
                state.render()
                

        }

        func molecule_name_action() {
                state.molecule_web_search.open_url(molecule_index: molecule_index)
        }
}
