import UIKit

class HierarchicalClusteringSelectionState: PageState {

        var distance_measure = "euclidean"
        var linkage = "average"
        var value_correction = "centered"
        var molecules_shown = "none"
        var order_of_molecules = "correlation"
        var selected_factors = [Bool](count: state.factor_ids.count, repeatedValue: true)
        var selected_samples = [Bool](count: state.number_of_samples, repeatedValue: true)

        override init() {
                super.init()
                name = "hierarchical_clustering_selection"
                title = astring_body(string: "Hierarchical Clustering")
                info = "Tap the button \"create figure\" after setting all options.\n\nThe samples are clustered, not the molecules.\n\nAll molecules without missing values are used for sample clustering.\n\nThe molecules shown in the heatmap can be either all, none, or those without missing values.\n\nThe values can be the original values of the data set or centered such that the mean is zero for each molecule."
        }
}

class HierarchicalClusteringSelection: Component, UITableViewDataSource, UITableViewDelegate {

        var hierarchical_clustering_selection_state: HierarchicalClusteringSelectionState!

        var number_of_present_molecules = 0
        var is_present_molecule = [] as [Int]

        let create_plot_button = UIButton(type: .System)
        let number_of_molecules_label = UILabel()
        let table_view = UITableView()

        override func viewDidLoad() {
                super.viewDidLoad()

                create_plot_button.setAttributedTitle(astring_body(string: "Create the plot"), forState: .Normal)
                create_plot_button.setAttributedTitle(astring_font_size_color(string: "Create the plot", color: color_disabled), forState: .Disabled)
                create_plot_button.addTarget(self, action: "create_plot_action", forControlEvents: .TouchUpInside)
                create_plot_button.sizeToFit()
                view.addSubview(create_plot_button)

                number_of_molecules_label.font = font_body
                number_of_molecules_label.textAlignment = .Center

                view.addSubview(number_of_molecules_label)

                table_view.registerClass(CenteredHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
                table_view.registerClass(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "footer")
                table_view.registerClass(CenteredTableViewCell.self, forCellReuseIdentifier: "cell")
                table_view.dataSource = self
                table_view.delegate = self
                table_view.backgroundColor = UIColor.whiteColor()
                table_view.separatorStyle = .None
                view.addSubview(table_view)
        }

        override func viewWillLayoutSubviews() {
                super.viewWillLayoutSubviews()

                let width = view.frame.width

                var origin_y = 10 as CGFloat
                create_plot_button.frame.origin = CGPoint(x: (width - create_plot_button.frame.width) / 2, y: origin_y)
                origin_y += create_plot_button.frame.height + 10
                number_of_molecules_label.frame = CGRect(x: 0, y: origin_y, width: width, height: 20)
                origin_y += 40
                table_view.frame = CGRect(x: 0, y: origin_y, width: width, height: view.frame.height - origin_y)
        }

        override func render() {
                hierarchical_clustering_selection_state = state.page_state as! HierarchicalClusteringSelectionState
                render_top_part()
        }

        func numberOfSectionsInTableView(tableView: UITableView) -> Int {
                return 7
        }

        func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
                return centered_header_footer_view_height - 30
        }

        func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
                let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("header") as! CenteredHeaderFooterView
                let text: String
                switch section {
                case 0:
                        text = "Distance measure"
                case 1:
                        text = "Linkage"
                case 2:
                        text = "Values"
                case 3:
                        text = "Molecules shown"
                case 4:
                        text = "Order of molecules"
                case 5:
                        text = "Factors to include"
                default:
                        text = "Samples to include"
                }

                header.update_normal(text: text)

                return header
        }

        func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
                return 15
        }

        func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
                let footer = tableView.dequeueReusableHeaderFooterViewWithIdentifier("footer")
                footer?.contentView.backgroundColor = UIColor.whiteColor()
                return footer
        }

        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                switch section {
                case 0:
                        return 2
                case 1:
                        return 3
                case 2:
                        return 2
                case 3:
                        return 3
                case 4:
                        return 2
                case 5:
                        return state.factor_ids.count
                default:
                        return state.sample_ids.count
                }
        }

        func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
                return centered_table_view_cell_height
        }

        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! CenteredTableViewCell
                let row = indexPath.row

                let text: String
                let selected: Bool

                switch indexPath.section {
                case 0:
                        text = ["Euclidean", "Correlation"][row]
                        let distance_measure = hierarchical_clustering_selection_state.distance_measure
                        selected = (row == 0 && distance_measure == "euclidean") || (row == 1 && distance_measure == "correlation")
                case 1:
                        text = ["Average", "Minimum", "Maximum"][row]
                        let linkage = hierarchical_clustering_selection_state.linkage
                        selected = (row == 0 && linkage == "average") || (row == 1 && linkage == "minimum") || (row == 2 && linkage == "maximum")
                case 2:
                        text = ["Centered", "Original"][row]
                        let value_correction = hierarchical_clustering_selection_state.value_correction
                        selected = (row == 0 && value_correction == "centered") || (row == 1 && value_correction == "original")
                case 3:
                        text = ["None", "Molecules without missing values", "All"][row]
                        let molecules_shown = hierarchical_clustering_selection_state.molecules_shown
                        selected = (row == 0 && molecules_shown == "none") || (row == 1 && molecules_shown == "present") || (row == 2 && molecules_shown == "all")
                case 4:
                        text = ["Correlation", "Orignal"][row]
                        let order_of_molecules = hierarchical_clustering_selection_state.order_of_molecules
                        selected = (row == 0 && order_of_molecules == "correlation") || (row == 1 && order_of_molecules == "original")
                case 5:
                        text = state.factor_names[row]
                        selected = hierarchical_clustering_selection_state.selected_factors[row]
                default:
                        text = state.sample_names[row]
                        selected = hierarchical_clustering_selection_state.selected_samples[row]
                }

                if selected {
                        cell.update_selected_checkmark(text: text)
                } else {
                        cell.update_unselected(text: text)
                }

                return cell
        }

        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
                let row = indexPath.row

                switch indexPath.section {
                case 0:
                        hierarchical_clustering_selection_state.distance_measure = row == 0 ? "euclidean" : "correlation"
                case 1:
                        hierarchical_clustering_selection_state.linkage = row == 0 ? "average" : row == 1 ? "minimum" : "maximum"
                case 2:
                        hierarchical_clustering_selection_state.value_correction = row == 0 ? "centered" : "original"
                case 3:
                        hierarchical_clustering_selection_state.molecules_shown = row == 0 ? "none" : row == 1 ? "present" : "all"
                case 4:
                        hierarchical_clustering_selection_state.order_of_molecules = row == 0 ? "correlation" : "original"
                case 5:
                        hierarchical_clustering_selection_state.selected_factors[row] = !hierarchical_clustering_selection_state.selected_factors[row]
                default:
                        hierarchical_clustering_selection_state.selected_samples[row] = !hierarchical_clustering_selection_state.selected_samples[row]
                }
                tableView.reloadData()
                render_top_part()
        }

        func render_top_part() {
                let selected_sample_indices = [Int](0 ..< state.sample_ids.count).filter { self.hierarchical_clustering_selection_state.selected_samples[$0] }

                is_present_molecule = [Int](count: state.number_of_molecules, repeatedValue: 0)

                calculate_molecules_without_missing_values(state.values, state.number_of_molecules, state.sample_ids.count, selected_sample_indices, selected_sample_indices.count, &number_of_present_molecules, &is_present_molecule)

                number_of_molecules_label.text = "Molecules without missing values: \(number_of_present_molecules)"

                create_plot_button.enabled = selected_sample_indices.count != 0 && number_of_present_molecules > 1
        }

        func create_plot_action() {
                let hierarchical_clustering_plot_state = HierarchicalClusteringPlotState(distance_measure: hierarchical_clustering_selection_state.distance_measure, linkage: hierarchical_clustering_selection_state.linkage, value_correction: hierarchical_clustering_selection_state.value_correction, molecules_shown: hierarchical_clustering_selection_state.molecules_shown, order_of_molecules: hierarchical_clustering_selection_state.order_of_molecules, selected_factors: hierarchical_clustering_selection_state.selected_factors, selected_samples: hierarchical_clustering_selection_state.selected_samples)
                state.navigate(page_state: hierarchical_clustering_plot_state)
                state.render()
        }
}