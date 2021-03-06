import UIKit

class MoleculeWebSearch {

        let system_urls = [
                "http://www.google.com/search?q="
        ]

        var custom_urls = [] as [String]

        init() {
                reset()
        }

        func reset() {

        }

        func url(molecule_index molecule_index: Int) -> NSURL? {
                let molecule_name = state.get_molecule_annotation_selected(molecule_index: molecule_index)
                let escaped_name = molecule_name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()) ?? " "
                let url = system_urls[0] + escaped_name
                return NSURL(string: url)
        }

        func open_url(molecule_index molecule_index: Int) {
                if let url = url(molecule_index: molecule_index) {
                        UIApplication.sharedApplication().openURL(url)
                }
        }
}
