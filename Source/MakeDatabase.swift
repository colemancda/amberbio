import Foundation

func make_database() {
        let database_file_name = "amberbio-main.sqlite"
        let database_path = file_app_directory_url(file_name: database_file_name).path!

        var database: Database!

        do { try NSFileManager.defaultManager().removeItemAtPath(database_path) } catch _ { }

        database = sqlite_open(database_path: database_path)

        sqlite_begin(database: database)
        sqlite_database_main(database: database)
        sqlite_end(database: database)

        database_populate(database: database)

        print(database_path)
}
