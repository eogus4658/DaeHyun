///
//  ViewController.swift
//  PageControl
//
//  Created by truetech on 2020/02/06.
//  Copyright © 2020 truetech. All rights reserved.
//

import UIKit
import SQLite3

class RecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var db : OpaquePointer?
    
    var RecordArray : [String] = []
    
    var DateArray : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        RecordArray.removeAll()
        DateArray.removeAll()
        
        
        print("RecordViewController viewdidload")
       _UpdateTable()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section : Int) -> Int {
        return DateArray.count
    }
    
    func tableView(_ tableView : UITableView, cellForRowAt indexPath : IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let currentRecordOfList = RecordArray[indexPath.row]
        let currentDateInfo = DateArray[indexPath.row]
        
        cell.textLabel?.text = currentRecordOfList
        cell.detailTextLabel?.text = currentDateInfo
        print("tableview cell")
        
        return cell
    }

    func _SaveToDatabase(record : String, date : String){
        let fileUrl = try!
        FileManager.default.url(for: .documentDirectory,
        in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("HappyRunDB.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("Error opening database")
            return
        }
        
        let myrecord = record.trimmingCharacters(in: .whitespacesAndNewlines)
        let mydate = date.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if(myrecord.isEmpty) {
            print("Record data is empty")
            return
        }
        
        if(mydate.isEmpty) {
            print("Date data is empty")
            return
        }
        
        var stmt: OpaquePointer? // statement
        
        let insertQuery = "INSERT INTO HappyRun (record, date) VALUES (?, ?)"
        
        if sqlite3_prepare(db, insertQuery, -1, &stmt, nil) != SQLITE_OK {
            print("Error binding query")
        }
        
        if sqlite3_bind_text(stmt, 1, myrecord, -1, nil) != SQLITE_OK {
            print("Error binding record")
        }
        
        if sqlite3_bind_text(stmt, 2, mydate, -1, nil) != SQLITE_OK {
            print("Error binding date")
        }
        if sqlite3_step(stmt) == SQLITE_DONE {
            print("Record saved successfully")
        } else {
            print("save Failed")
        }
        sqlite3_finalize(stmt)
    }
    
    func _UpdateTable(){
        print("Updatetable")
        let fileUrl = try!
               FileManager.default.url(for: .documentDirectory,
               in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("HappyRunDB.sqlite")
               
               if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
                   print("Error opening database")
                   return
               }
               
               let createTableQuery = "CREATE TABLE IF NOT EXISTS HappyRun (id INTEGER PRIMARY KEY AUTOINCREMENT, record REAL, date TEXT)"
               
               if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
                   print("Error creating table")
                   return
               }
               print("Everything is fine")
               
               let queryString = "SELECT * FROM HappyRun"
               
               var stmtquery : OpaquePointer?
               if sqlite3_prepare(db, queryString, -1, &stmtquery, nil) != SQLITE_OK {
                   print("Error loading database")
                   return
               }
               print("database Loading successfully")
               print ("sqlite3_step : " + String(format: "%d", sqlite3_step(stmtquery) ))
               print ("SQLITE_ROW : " + String(format: "%d", SQLITE_ROW ))
               while(sqlite3_step(stmtquery) == SQLITE_ROW) {
                   let record = String(cString: sqlite3_column_text(stmtquery, 1))
                   let date = String(cString: sqlite3_column_text(stmtquery, 2))
                   //print("Loading Step")
                   //print("record : " + record)
                   //print("date : " + date)
                   RecordArray.append(record)
                   DateArray.append(date)
               }
               sqlite3_finalize(stmtquery)
//        if tableView != nil{
//            print("reload data")
//            tableView.reloadData()
//        } else {
//            print("viewdidload 에서 호출")
//        }
    }
    
}

