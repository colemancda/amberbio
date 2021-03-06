import UIKit

enum GEOStatus {
        case NoInput
        case CorrectInput
        case IncorrectInput
        case Downloading
        case NoConnection
        case FileNotFound
        case Importing
        case ImportError
        case Done
}

class GEOState: PageState {

        var session: NSURLSession!
        var state = GEOStatus.NoInput
        var geo_id = ""

        override init() {
                super.init()
                name = "geo"
                title = astring_body(string: "Gene expression omnibus")
                info = "Download data set and series records from Gene expression omnibus (GEO).\n\nDataset records have ids of the form GDSxxxx.\n\nSeries records have ids of the form GSExxxx.\n\nxxxx denotes any number of digits.\n\nData sets can be searched on http://www.ncbi.nlm.nih.gov/sites/GDSbrowser."
        }
}

class GEO: Component, UITextFieldDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate {

        var geo_state: GEOState!

        let scroll_view = UIScrollView()
        let info_label = UILabel()
        let message_label = UILabel()
        let text_field = UITextField()
        let button = UIButton(type: .System)
        let link_label = UILabel()
        let link_button = UIButton(type: .System)

        let serial_queue = dispatch_queue_create("GEO download", DISPATCH_QUEUE_SERIAL)
        var session: NSURLSession!
        var task: NSURLSessionDataTask?
        var content_length: Int?
        var received_data = NSMutableData()
        var response_status_code = 200
        var canceled = false

        override func viewDidLoad() {
                super.viewDidLoad()

                session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())

                info_label.text = "Download a GEO data set (GDSxxxx) or GEO series record (GSExxxx)"
                info_label.textAlignment = .Left
                info_label.font = font_body
                info_label.numberOfLines = 0
                scroll_view.addSubview(info_label)

                message_label.numberOfLines = 0
                scroll_view.addSubview(message_label)

                text_field.keyboardType = UIKeyboardType.NamePhonePad
                text_field.clearButtonMode = UITextFieldViewMode.WhileEditing
                text_field.font = font_body
                text_field.autocorrectionType = UITextAutocorrectionType.No
                text_field.textAlignment = NSTextAlignment.Center
                text_field.borderStyle = UITextBorderStyle.Bezel
                text_field.layer.masksToBounds = true
                text_field.delegate = self
                scroll_view.addSubview(text_field)

                button.addTarget(self, action: "button_action", forControlEvents: .TouchUpInside)
                scroll_view.addSubview(button)

                link_label.text = "Web search for data sets"
                link_label.font = font_body
                scroll_view.addSubview(link_label)

                link_button.setAttributedTitle(astring_body(string: "www.ncbi.nlm.nih.gov/sites/GDSbrowser"), forState: .Normal)
                link_button.addTarget(self, action: "link_action", forControlEvents: .TouchUpInside)
                scroll_view.addSubview(link_button)

                view.addSubview(scroll_view)

                let tap_recognizer = UITapGestureRecognizer(target: self, action: "tap_action")
                view.addGestureRecognizer(tap_recognizer)
        }

        override func viewWillLayoutSubviews() {
                super.viewWillLayoutSubviews()

                let width = view.frame.width

                var origin_y = 30 as CGFloat

                let info_label_size = info_label.sizeThatFits(CGSize(width: width - 40, height: 0))
                info_label.frame = CGRect(x: (width - info_label_size.width) / 2, y: origin_y, width: info_label_size.width, height: info_label_size.height)
                origin_y = CGRectGetMaxY(info_label.frame) + 50

                let message_label_size = message_label.sizeThatFits(CGSize(width: width - 40, height: 0))
                message_label.frame = CGRect(x: 20, y: origin_y, width: width - 40, height: message_label_size.height)
                origin_y = CGRectGetMaxY(message_label.frame) + 40

                let text_field_width = min(width - 40, 300)
                text_field.frame = CGRect(x: (width - text_field_width) / 2, y: origin_y, width: text_field_width, height: 50)
                origin_y = CGRectGetMaxY(text_field.frame) + 40

                button.sizeToFit()
                button.frame.origin = CGPoint(x: (width - button.frame.width) / 2, y: origin_y)
                origin_y = CGRectGetMaxY(button.frame) + 50

                link_label.sizeToFit()
                link_label.frame.origin = CGPoint(x: (width - link_label.frame.width) / 2, y: origin_y)
                origin_y = CGRectGetMaxY(link_label.frame) + 10

                link_button.sizeToFit()
                link_button.frame.origin = CGPoint(x: (width - link_button.frame.width) / 2, y: origin_y)
                origin_y = CGRectGetMaxY(link_button.frame) + 10

                scroll_view.contentSize = CGSize(width: width, height: origin_y)
                scroll_view.frame = view.bounds
        }

        override func render() {
                geo_state = state.page_state as! GEOState

                if text_field.text != geo_state.geo_id {
                        text_field.text = geo_state.geo_id
                }

                text_field.hidden = false
                button.enabled = true
                button.hidden = false

                let message_text: String
                let message_color: UIColor

                switch geo_state.state {
                case .NoInput:
                        message_text = "Type GDSxxxx or GSExxxx"
                        message_color = UIColor.blackColor()
                        set_button_title(title: "Download and import")
                        button.enabled = false
                case .IncorrectInput:
                        message_text = "Type GDSxxxx or GSExxxx"
                        message_color = UIColor.redColor()
                        set_button_title(title: "Download and import")
                        button.enabled = false
                case .CorrectInput:
                        message_text = "The id has the correct form"
                        message_color = UIColor.blackColor()
                        set_button_title(title: "Download and import")
                case .Downloading:
                        let nbytes = received_data.length
                        let nmb = megabytes(nbytes: nbytes)
                        if let content_length = content_length {
                                let total_nbm = megabytes(nbytes: content_length)
                                message_text = "\(nmb) of \(total_nbm) downloaded"
                        } else {
                                message_text = "Starting download"
                        }
                        message_color = UIColor.blackColor()
                        set_button_title(title: "Cancel")
                        button.enabled = true
                        text_field.hidden = true
                case .NoConnection:
                        message_text = "There is a problem with the internet connection"
                        message_color = UIColor.redColor()
                        set_button_title(title: "Download and import")
                case .FileNotFound:
                        message_text = "The data set does not exist"
                        message_color = UIColor.redColor()
                        set_button_title(title: "Download and import")
                case .Importing:
                        message_text = "The downloaded data set is being imported"
                        message_color = UIColor.blackColor()
                        button.hidden = true
                        text_field.hidden = true
                case .ImportError:
                        message_text = "The file was not of the expected format"
                        message_color = UIColor.redColor()
                        button.hidden = true
                case .Done:
                        message_text = "The project \(geo_state.geo_id) has been created"
                        message_color = UIColor.blueColor()
                        set_button_title(title: "Download and import")
                        button.enabled = false
                }

                message_label.attributedText = astring_font_size_color(string: message_text, font: nil, font_size: 20, color: message_color)
                message_label.textAlignment = .Center

                view.setNeedsLayout()
        }

        override func finish() {
                canceled = true
                session.invalidateAndCancel()
                session = nil
                if geo_state.state == .Downloading {
                        geo_state.state = .CorrectInput
                }
        }

        func textFieldShouldReturn(textField: UITextField) -> Bool {
                textField.resignFirstResponder()
                return true
        }

        func textFieldDidEndEditing(textField: UITextField) {
                let original_text = textField.text ?? ""

                let text = trim(string: original_text.uppercaseString)

                if text == "" {
                        geo_state.state = .NoInput
                } else if text.hasPrefix("GSE") || text.hasPrefix("GDS") {
                        let substring = text.substringFromIndex(text.startIndex.advancedBy(3))
                        if Int(substring) == nil {
                                geo_state.state = .IncorrectInput
                        } else {
                                geo_state.state = .CorrectInput
                        }
                } else {
                        geo_state.state = .IncorrectInput
                }

                if text != original_text && geo_state.state == .CorrectInput {
                        textField.text = text
                }
                geo_state.geo_id = text
                state.render()
        }

        func button_action() {
                text_field.resignFirstResponder()
                if geo_state.state == .CorrectInput || geo_state.state == .NoConnection {
                        download()
                } else if geo_state.state == .Downloading {
                        cancel_download()
                }
        }

        func url_of_data_set() -> NSURL {
//                http://ftp.ncbi.nlm.nih.gov/geo/datasets/GDS1nnn/GDS1001/soft/GDS1001_full.soft.gz
//                http://ftp.ncbi.nlm.nih.gov/geo/series/GSEnnn/GSE1/soft/GSE1_family.soft.gz
                let id = geo_state.geo_id
                let prefix = id.substringWithRange(id.startIndex ..< id.startIndex.advancedBy(3))
                let digits = [Character](id.substringFromIndex(id.startIndex.advancedBy(3)).characters).map { String($0) } as [String]
                let is_gds = prefix == "GDS"

                var url = "http://ftp.ncbi.nlm.nih.gov/geo/"
                url += is_gds ? "datasets/GDS" : "series/GSE"
                if digits.count > 3 {
                        for i in 0 ..< digits.count - 3 {
                                url += digits[i]
                        }
                }
                url += "nnn/" + id + "/soft/" + id + "_"
                url += is_gds ? "full" : "family"
                url += ".soft.gz"

                let nsurl = NSURL(string: url)!
                return nsurl
        }

        func download() {
                received_data = NSMutableData()
                canceled = false
                response_status_code = 0
                content_length = nil
                let url = url_of_data_set()
                task = session?.dataTaskWithURL(url)

                dispatch_async(serial_queue, {
                        self.task?.resume()
                })

                geo_state.state = .Downloading
                state.render()
        }

        func cancel_download() {
                dispatch_async(serial_queue, {
                        self.task?.cancel()
                        self.task = nil
                })

                received_data = NSMutableData()
                canceled = true
        }

        func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
                received_data.appendData(data)
                render()
        }

        func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
                if canceled {
                        geo_state.state = .CorrectInput
                } else if error != nil {
                        geo_state.state = .NoConnection
                } else if response_status_code == 404 {
                        geo_state.state = .FileNotFound
                } else {
                        geo_state.state = .Importing
                        NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: "import_data_set", userInfo: nil, repeats: false)
                }
                state.render()
        }

        func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
                if let response = response as? NSHTTPURLResponse {
                        response_status_code = response.statusCode
                        content_length = Int(response.expectedContentLength)
                } else {
                        response_status_code = 404
                }
                completionHandler(NSURLSessionResponseDisposition.Allow)
        }

        func import_data_set() {
                if let inflated_data = gunzip(data: received_data) {
                        if geo_state.geo_id.hasPrefix("GDS") {
                                let gds = GDS(data: inflated_data)
                                if gds.valid {
                                        import_data_set(sample_name: gds.sample_names, number_of_molecules: gds.number_of_molecules, values: gds.values, molecule_annotation_names: gds.molecule_annotation_names, molecule_annotation_values: gds.molecule_annotation_values, factor_names: gds.factor_names, level_names_for_factor: gds.level_names_for_factor, header: gds.header)
                                } else {
                                        geo_state.state = .ImportError
                                        render()
                                }
                        } else {
                                let gse = GSE(data: inflated_data)
                                if gse.valid {
                                        import_data_set(sample_name: gse.sample_names, number_of_molecules: gse.number_of_molecules, values: gse.values, molecule_annotation_names: gse.molecule_annotation_names, molecule_annotation_values: gse.molecule_annotation_values, factor_names: gse.factor_names, level_names_for_factor: gse.level_names_for_factor, header: gse.header)
                                } else {
                                        geo_state.state = .ImportError
                                        render()
                                }
                        }
                } else {
                        geo_state.state = .ImportError
                        render()
                }
        }

        func import_data_set(sample_name sample_names: [String], number_of_molecules: Int, values: [Double], molecule_annotation_names: [String], molecule_annotation_values: [[String]], factor_names: [String], level_names_for_factor: [[String]], header: String) {
                let project_name = geo_state.geo_id

                var molecule_names = [] as [String]
                if molecule_annotation_names.count == 1 {
                        molecule_names = molecule_annotation_values[0]
                } else {
                        for i in 0 ..< number_of_molecules {
                                let molecule_name = "\(molecule_annotation_values[0][i]) (\(molecule_annotation_values[1][i]))"
                                molecule_names.append(molecule_name)
                        }
                }

                sqlite_begin(database: state.database)
                let project_id = state.insert_project(project_name: project_name, data_set_name: "Original data set", values: values, sample_names: sample_names, molecule_names: molecule_names)
                state.insert_molecule_annotations(project_id: project_id, molecule_annotation_names: molecule_annotation_names, molecule_annotation_values: molecule_annotation_values)
                for i in 0 ..< factor_names.count {
                        state.insert_factor(project_id: project_id, factor_name: factor_names[i], level_names_of_samples: level_names_for_factor[i])
                }
                state.insert_project_note(project_note_text: header, project_note_type: "auto", project_note_user_name: state.get_user_name(), project_id: project_id)

                sqlite_end(database: state.database)

                let data_set_id = state.get_original_data_set_id(project_id: project_id)
                state.set_active_data_set(data_set_id: data_set_id)

                geo_state.state = .Done
                state.render()
        }

        func tap_action() {
                text_field.resignFirstResponder()
        }

        func set_button_title(title title: String) {
                button.setAttributedTitle(astring_font_size_color(string: title, font: nil, font_size: 20, color: nil), forState: .Normal)
                button.setAttributedTitle(astring_font_size_color(string: title, font: nil, font_size: 20, color: color_disabled), forState: .Disabled)
        }

        func link_action() {
                let link = "http://www.ncbi.nlm.nih.gov/sites/GDSbrowser"
                if let url = NSURL(string: link) {
                        print(url)
                        UIApplication.sharedApplication().openURL(url)
                }
        }

        func megabytes(nbytes nbytes: Int) -> String {
                let n100kb = nbytes / 100_000
                let nmb = Double(n100kb) / 10
                return "\(nmb) MB"
        }
}
