import UIKit

class ModuleStoreState: PageState {

        override init() {
                super.init()
                name = "module_store"
                title = astring_body(string: "Donations")
                info = "The Amberbio app is free to use.\n\nDonations support hosting and development of the app.\n\nWith donations, the app can be free and benefit people across the world.\n\nPlease consider donating if the app is useful to you."

                state.store.request_products()
        }
}

class ModuleStore: Component, UITableViewDataSource, UITableViewDelegate {

        let table_view = UITableView()

        override func loadView() {
                view = table_view
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()

                table_view.registerClass(CenteredHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "centered header")
                table_view.registerClass(StoreProductTableViewCell.self, forCellReuseIdentifier: "product cell")
                table_view.registerClass(CenteredTableViewCell.self, forCellReuseIdentifier: "centered cell")

                table_view.dataSource = self
                table_view.delegate = self
                table_view.backgroundColor = UIColor.whiteColor()
                table_view.separatorStyle = .None
        }

        override func render() {
                table_view.reloadData()
        }

        func numberOfSectionsInTableView(tableView: UITableView) -> Int {
                return 1
        }

        func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
                return centered_header_footer_view_height
        }

        func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
                let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("centered header") as! CenteredHeaderFooterView

                let text = "Donations support the development of the app"
                header.update_multiline(text: text)
                
                return header
        }

        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return state.store.request_products_pending ? 1 : state.store.products.count
        }

        func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
                return state.store.request_products_pending ? centered_table_view_cell_height : store_product_table_view_cell_height
        }

        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
                if state.store.request_products_pending {
                        let cell = tableView.dequeueReusableCellWithIdentifier("centered cell") as! CenteredTableViewCell
                        let text = "Waiting for the server"
                        cell.update_unselected(text: text)
                        return cell
                } else {
                        let cell = tableView.dequeueReusableCellWithIdentifier("product cell") as! StoreProductTableViewCell
                        let color = color_from_hex(hex: color_brewer_qualitative_9_pastel1[5])
                        cell.update(product: state.store.products[indexPath.row], color: color)
                        return cell
                }
        }
}
