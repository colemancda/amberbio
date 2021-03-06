import UIKit

let store_restore_table_view_cell_height = 200 as CGFloat

class StoreRestoreTableViewCell: UITableViewCell {

        let description_text = "Restore to make sure that all purchases with your Apple ID are known by the app on this device."

        let description_label = UILabel()
        let restore_button = UIButton(type: .System)
        let inset_view = UIView()

        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)

                selectionStyle = UITableViewCellSelectionStyle.None
                contentView.backgroundColor = UIColor.whiteColor()

                inset_view.clipsToBounds = true
                inset_view.layer.cornerRadius = 10
                inset_view.backgroundColor = color_from_hex(hex: color_brewer_qualitative_9_pastel1[0])
                contentView.addSubview(inset_view)

                description_label.text = description_text
                description_label.font = font_body
                description_label.textAlignment = .Left
                description_label.numberOfLines = 0
                inset_view.addSubview(description_label)

                let restore_text = astring_font_size_color(string: "Restore", font: nil, font_size: 24, color: nil)
                restore_button.setAttributedTitle(restore_text, forState: .Normal)
                restore_button.addTarget(self, action: "restore_action", forControlEvents: .TouchUpInside)
                inset_view.addSubview(restore_button)
        }

        required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
                super.layoutSubviews()

                inset_view.frame = CGRectInset(contentView.frame, 20, 8)

                let width = inset_view.frame.width

                var origin_y = 10 as CGFloat

                let description_width = min(width - 20, 500)
                description_label.frame = CGRect(x: (width - description_width) / 2, y: origin_y, width: description_width, height: 100)
                origin_y += description_label.frame.height + 10

                restore_button.sizeToFit()
                restore_button.frame.origin = CGPoint(x: (width - restore_button.frame.width) / 2, y: origin_y)
        }

        func restore_action() {
//                state.store.restore()
        }
}
