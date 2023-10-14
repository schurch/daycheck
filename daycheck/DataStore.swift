//
//  DataStore.swift
//  daycheck
//
//  Created by Stefan Church on 23/04/23.
//

import Foundation
import SQLite3

class DataStore {
    private static let path: String = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return "\(documentsPath)/daycheck.sqlite"
    }()
    
    static func save(rating: Rating) {
        guard let value = rating.value else { return }
        guard let db = openConnection() else { return }
        defer { closeConnection(db: db) }
        
        ensureRatingsTable(db: db)
        
        var insertStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO ratings (date, rating, notes) VALUES (?, ?, ?);", -1, &insertStatement, nil) == SQLITE_OK {
            let date = rating.date.toISOString().cString(using: String.Encoding.utf8)
            sqlite3_bind_text(insertStatement, 1, date, -1, nil)
            
            let ratingValue = value.rawValue.cString(using: String.Encoding.utf8)
            sqlite3_bind_text(insertStatement, 2, ratingValue, -1, nil)
            
            let notes = rating.notes.flatMap { $0.cString(using: String.Encoding.utf8) }
            sqlite3_bind_text(insertStatement, 3, notes, -1, nil)
            
            if sqlite3_step(insertStatement) != SQLITE_DONE {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement is not prepared.")
        }
        
        sqlite3_finalize(insertStatement)
    }
    
    static func getRatings() -> [Rating] {
        guard let db = openConnection() else { return [] }
        defer { closeConnection(db: db) }
        
        ensureRatingsTable(db: db)
        
        var ratings = [Rating]()
        
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT date, rating, notes FROM ratings;", -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let dateString = String(cString: sqlite3_column_text(queryStatement, 0))
                let ratingValue = String(cString: sqlite3_column_text(queryStatement, 1))
                let notes = sqlite3_column_text(queryStatement, 2).map { String(cString: $0) }
                
                ratings.append(
                    Rating(
                        date: dateString.toDate(),
                        value: Rating.Value(rawValue: ratingValue)!,
                        notes: notes
                    )
                )
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("\nQuery is not prepared \(errorMessage)")
        }
        
        sqlite3_finalize(queryStatement)
        
        return ratings
    }
    
    static func getRating(forDate queryDate: Date) -> Rating? {
        guard let db = openConnection() else { return nil }
        defer { closeConnection(db: db) }
        
        ensureRatingsTable(db: db)
        
        var rating: Rating?
        
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT date, rating, notes FROM ratings WHERE date = ?;", -1, &queryStatement, nil) == SQLITE_OK {
            let date = queryDate.toISOString().cString(using: String.Encoding.utf8)
            sqlite3_bind_text(queryStatement, 1, date, -1, nil)
                        
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let dateString = String(cString: sqlite3_column_text(queryStatement, 0))
                let ratingValue = String(cString: sqlite3_column_text(queryStatement, 1))
                let notes = sqlite3_column_text(queryStatement, 2).map { String(cString: $0) }
                
                rating = Rating(
                    date: dateString.toDate(),
                    value: Rating.Value(rawValue: ratingValue)!,
                    notes: notes
                )
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("\nQuery is not prepared \(errorMessage)")
        }
        
        sqlite3_finalize(queryStatement)
        
        return rating
    }
    
    private static func openConnection() -> OpaquePointer? {
        var db: OpaquePointer?
        
        if sqlite3_open(DataStore.path, &db) == SQLITE_OK {
            return db
        } else {
            print("Unable to open database.")
            return nil
        }
    }
    
    private static func closeConnection(db: OpaquePointer) {
        sqlite3_close(db)
    }
    
    private static func ensureRatingsTable(db: OpaquePointer) {
//        let createTableString = """
//        DROP TABLE ratings;
//        """
        let createTableString = """
        CREATE TABLE IF NOT EXISTS ratings (
            date TEXT PRIMARY KEY NOT NULL CHECK (date IS date(date)),
            rating TEXT NOT NULL,
            notes TEXT
        );
        """
        
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                print("Error creating ratings table.")
            }
        } else {
            print("\nCREATE TABLE statement is not prepared.")
        }
        
        sqlite3_finalize(createTableStatement)
    }
}

extension Date {
    func toISOString() -> String {
        self.formatted(
            Date.ISO8601FormatStyle(timeZone: Calendar.current.timeZone)
                .year()
                .month()
                .day()
        )
    }
}

private extension String {
    func toDate() -> Date {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.formatOptions = [.withFullDate]
        return dateFormatter.date(from: self)!
    }
}
