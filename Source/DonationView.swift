import Foundation

class DonationView: Component {

        let info_text = "Donations support hosting and development of the app.\n\nWith donations, the app can be free and benefit people across the world.\n\nPlease consider donating if the app is useful to you."

        let content_view = UIView()
        let close_button = UIButton(type: UIButtonType.System)
        let please_label = UILabel()
        let info_label = UILabel()
        let donate_button = UIButton(type: .System)
        let no_thanks_button = UIButton(type: .System)
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
                
                content_view.layer.cornerRadius = 20
                content_view.layer.borderColor =   UIColor.blackColor().CGColor
                content_view.layer.borderWidth = 1.5
                view.addSubview(content_view)
                content_view.backgroundColor = UIColor.whiteColor()
              
                close_button.setAttributedTitle(astring_body_size(string: "\u{2715}", font_size: 25), forState: .Normal)
                close_button.addTarget(self, action: "finish_action", forControlEvents: .TouchUpInside)
                content_view.addSubview(close_button)
                
                please_label.text = "Please donate"
                please_label.textAlignment = .Center
                please_label.font = font_body.fontWithSize(24)
                content_view.addSubview(please_label)
                
                info_label.numberOfLines = 0
                info_label.text = info_text
                info_label.font = font_body
                content_view.addSubview(info_label)
                
                donate_button.setAttributedTitle(astring_body_size(string: "Go to donations", font_size: 22), forState: .Normal)
                donate_button.addTarget(self, action: "donate_action", forControlEvents: .TouchUpInside)
                content_view.addSubview(donate_button)
                
                no_thanks_button.setAttributedTitle(astring_body_size(string: "No thanks", font_size: 22), forState: .Normal)
                no_thanks_button.addTarget(self, action: "finish_action", forControlEvents: .TouchUpInside)
                content_view.addSubview(no_thanks_button)
        }
        
        override func viewWillLayoutSubviews() {
                super.viewWillLayoutSubviews()
                
                let (width, height) = (view.frame.width, view.frame.height)

                let short = height < 400
                let content_width: CGFloat
                if short {
                        content_width = width - 10
                } else {
                        content_width = width < 590 ? CGFloat(width - 40) : CGFloat(550)
                }

                close_button.frame = CGRect(x: content_width - 40, y: 0, width: 40, height: 40)
                
                var origin_y = 20 as CGFloat
                
                please_label.frame = CGRect(x: 0, y: origin_y, width: content_width, height: 30)
                origin_y = CGRectGetMaxY(please_label.frame) + 20

                let info_size = info_label.sizeThatFits(CGSize(width: content_width - 40, height: 0))
                info_label.frame.origin = CGPoint(x: 20, y: origin_y)
                info_label.frame.size = info_size
                origin_y = CGRectGetMaxY(info_label.frame) + 20
                
                donate_button.sizeToFit()
                donate_button.frame.origin = CGPoint(x: (content_width - donate_button.frame.width) / 2, y: origin_y)
                origin_y = CGRectGetMaxY(donate_button.frame) + 20
                
                no_thanks_button.sizeToFit()
                no_thanks_button.frame.origin = CGPoint(x: (content_width - no_thanks_button.frame.width) / 2, y: origin_y)
                origin_y = CGRectGetMaxY(no_thanks_button.frame)

                let content_height: CGFloat
                if origin_y + 10 < height {
                        content_height = origin_y + 10
                } else {
                        content_height = origin_y
                }
                content_view.frame.size = CGSize(width: content_width, height: content_height)
                content_view.center = CGPoint(x: width / 2, y: height / 2)
        }
        
        func donate_action() {
                let page_state = ModuleStoreState()
                state.navigate(page_state: page_state)
                state.render_type = .full_page
                state.render()
        }
        
        func finish_action() {
                state.render_type = .full_page
                state.render()
        }
}
