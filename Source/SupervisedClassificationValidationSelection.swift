import UIKit

class SupervisedClassificationValidationSelectionState: PageState {

        let supervised_classification: SupervisedClassification

        init(supervised_classification: SupervisedClassification) {
                self.supervised_classification = supervised_classification
                super.init()
                name = "supervised_classification_validation_selection"
                switch supervised_classification.supervised_classification_type {
                case .KNN:
                        title = astring_body(string: "k nearest neighbor classifier")
                case .SVM:
                        title = astring_body(string: "support vector machine")
                }
                info = "Select the type of validation.\n\nLeave one out cross validation is a special case of k fold cross validation where k is equal to the number of samples."
        }
}

class SupervisedClassificationValidationSelection: Component, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

        var supervised_classification: SupervisedClassification!

        let table_view = UITableView()

        override func loadView() {
                view = table_view
        }

        override func viewDidLoad() {
                super.viewDidLoad()

                table_view.registerClass(CenteredHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
                table_view.registerClass(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "footer")
                table_view.registerClass(CenteredTableViewCell.self, forCellReuseIdentifier: "cell")
                table_view.registerClass(CrossValidationTableViewCell.self, forCellReuseIdentifier: "text field cell")
                table_view.backgroundColor = UIColor.whiteColor()
                table_view.separatorStyle = .None

                let tap_recognizer = UITapGestureRecognizer(target: self, action: "tap_action")
                tap_recognizer.cancelsTouchesInView = false
                view.addGestureRecognizer(tap_recognizer)
        }

        override func render() {
                supervised_classification = (state.page_state as! SupervisedClassificationValidationSelectionState).supervised_classification
                table_view.dataSource = self
                table_view.delegate = self
                table_view.reloadData()
        }

        func numberOfSectionsInTableView(tableView: UITableView) -> Int {
                return 1
        }

        func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
                return centered_header_footer_view_height + 20
        }

        func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
                let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("header") as! CenteredHeaderFooterView

                header.update_normal(text: "Select validation type")

                return header
        }

        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return 3
        }

        func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
                return indexPath.row < 2 ? centered_table_view_cell_height + 10 : cross_validation_table_view_cell_height
        }

        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
                switch indexPath.row {
                case 0:
                        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! CenteredTableViewCell
                        let text = "Fixed training and test set"
                        cell.update_selectable_arrow(text: text)
                        return cell
                case 1:
                        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! CenteredTableViewCell
                        let text = "Leave one out cross validation"
                        cell.update_selectable_arrow(text: text)
                        return cell
                default:
                        let cell = tableView.dequeueReusableCellWithIdentifier("text field cell") as! CrossValidationTableViewCell
                        let text = "k fold cross validation"
                        cell.update(text: text, k_fold: supervised_classification.k_fold, tag: 0, delegate: self)
                        return cell
                }
        }

        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
                let page_state: PageState
                switch indexPath.row {
                case 0:
                        supervised_classification.validation_training_test()
                        page_state = SupervisedClassificationTrainingSelectionState(supervised_classification: supervised_classification)
                case 1:
                        supervised_classification.validation_leave_one_out()
                        page_state = SupervisedClassificationParameterSelectionState(supervised_classification: supervised_classification)
                default:
                        supervised_classification.validation_k_fold_cross_validation()
                        page_state = SupervisedClassificationParameterSelectionState(supervised_classification: supervised_classification)
                }
                state.navigate(page_state: page_state)
                state.render()
        }

        func textFieldDidEndEditing(textField: UITextField) {
                correct_text_field(text_field: textField)
                let k_fold = Int(textField.text!)!
                supervised_classification.set_k_fold(k_fold: k_fold)
        }

        func textFieldShouldReturn(textField: UITextField) -> Bool {
                textField.resignFirstResponder()
                return true
        }

        func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
                if range.length != 0 && string.isEmpty {
                        return true
                }

                return Int(string) != nil
        }

        func correct_text_field(text_field text_field: UITextField) {
                let text = text_field.text ?? ""
                if let number = Int(text) {
                        if number < 2 {
                                text_field.text = "2"
                        } else if number > supervised_classification.max_k_fold() {
                                text_field.text = "\(supervised_classification.max_k_fold())"
                        }
                } else {
                        text_field.text = "2"
                }
        }

        func tap_action() {
                let cell = table_view.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as? CrossValidationTableViewCell
                cell?.text_field.resignFirstResponder()
        }
}
