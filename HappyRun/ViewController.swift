//
//  ViewController.swift
//  HappyRun
//
//  Created by truetech on 2020/02/06.
//  Copyright © 2020 truetech. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation
import SQLite3

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var lblTimeInfo: UILabel!
    @IBOutlet weak var lblDistanceInfo: UILabel!
    @IBOutlet weak var lblDebug: UILabel!
    @IBOutlet weak var lblDebug2: UILabel!
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    
    let recordview : RecordViewController = RecordViewController()
    
    let annotation = MKPointAnnotation() // 이거 없으면 두번째 실행때 튕김
    let timeSelector: Selector = #selector(ViewController.updateTime)
    let interval = 1.0
    let synthesizer = AVSpeechSynthesizer()
    
    
    var count = 0
    var distance : CLLocationDistance = 0.0
    var bFirst : Bool?
    var bStartClicked : Bool?
    var test = 0
    var test2 = 0
    var test3 = 0
    var locationData : Array<CLLocationCoordinate2D> = []
    
    
    let locationManager = CLLocationManager()
    var formerlocation : CLLocation? = nil
    var currentlocation : CLLocation? = nil
    var myTimer : Timer?
    
    var db : OpaquePointer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
        myMap.delegate = self
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        myMap.showsUserLocation = true
        lblTimeInfo.text = ""
        lblDistanceInfo.text = ""
        lblDebug.text = ""
        bStartClicked = false
        btnStop.isEnabled = false
    }
    
    class customPin: NSObject, MKAnnotation {
        var coordinate: CLLocationCoordinate2D
        var title: String?
        var subtitle: String?
        
        init(pinTitle:String, pinSubTitle:String, location:CLLocationCoordinate2D) {
            self.title = pinTitle
            self.subtitle = pinSubTitle
            self.coordinate = location
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func goLocation(latitude latitudeValue : CLLocationDegrees, longitude longitudeValue : CLLocationDegrees, delta span : Double ) {
        let pLocation = CLLocationCoordinate2D(latitude: latitudeValue, longitude: longitudeValue)
        let spanValue = MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        let pRegion = MKCoordinateRegion(center: pLocation, span: spanValue)
        myMap.setRegion(pRegion, animated: true)
    }
    
       func locationManager(_ manager: CLLocationManager, didUpdateLocations locations : [CLLocation]){
            test = test + 1
            let pLocation = locations.last
            goLocation(latitude: (pLocation?.coordinate.latitude)!, longitude: (pLocation?.coordinate.longitude)!, delta: 0.001)
            if pLocation != nil && bStartClicked == true {
                currentlocation = CLLocation(latitude: (pLocation?.coordinate.latitude)!, longitude: (pLocation?.coordinate.longitude)!)
                // 선 그리기
                locationData.append(currentlocation!.coordinate)
                let aPolyline = MKPolyline(coordinates: locationData, count: locationData.count)
                myMap.addOverlay(aPolyline)
                
                if bFirst == false {
                    // --- 시작점 표시
                    let startPin = customPin(pinTitle: "시작위치", pinSubTitle: "", location: pLocation!.coordinate)
                    self.myMap.addAnnotation(startPin)
                    bFirst = true
                } else{
                    distance = distance + currentlocation!.distance(from: formerlocation!)
            }
                formerlocation = currentlocation
           
        }
    }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay : overlay)
            renderer.strokeColor = UIColor.green
            renderer.lineWidth = 4.0
            return renderer
        }

        @IBAction func btnClickedStart(_ sender: UIButton) {
            count = 0
            distance = 0.0
            bFirst = false
            bStartClicked = true
            btnStart.isEnabled = false
            btnStop.isEnabled = true
            myTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: timeSelector, userInfo: nil, repeats: true)
            locationData.removeAll()
            locationManager.startUpdatingLocation()

            let utterance = AVSpeechUtterance(string: "즐거운 달리기 되세요~~")
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
            utterance.rate = 0.4
            synthesizer.speak(utterance)

        }

        @IBAction func btnClickedStop(_ sender: UIButton) {
            myTimer?.invalidate()
            bFirst = true
            bStartClicked = false
            btnStart.isEnabled = true
            btnStop.isEnabled = false
            locationManager.stopUpdatingLocation() // 위치 업데이트를 멈춤 내가 주석침
            myMap.showsUserLocation = false
            let utterance = AVSpeechUtterance(string: "달리기가 끝났어여~~ 오예~ 참고로 달리기 시간은" +
                String(format : "%d", count) + "이고 거리는" + String(format: "%02f인데요?", distance))
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
            utterance.rate = 0.4
            synthesizer.speak(utterance)
            if currentlocation != nil{
                let endPin = customPin(pinTitle: "종료위치", pinSubTitle: "", location: currentlocation!.coordinate)
                self.myMap.addAnnotation(endPin)
            }
            let time = countToTime(count: count)
            let date = NSDate()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss EEE"
            let myrecord = "거리 :" + String(format: "%.2f", distance) + " m , 시간 : \(time[0])시간 \(time[1])분 \(time[2])초"
            let mydate = formatter.string(from: date as Date)
            recordview._SaveToDatabase(record: myrecord, date: mydate)
        }

        @objc func updateTime(){
            count = count + 1
            let time = countToTime(count: count)
            let strtime = String(format: "경과 시간 : %02d : %02d : %02d", time[0], time[1], time[2])
            lblTimeInfo.text = strtime
            lblDistanceInfo.text = String(format : "%02f m(미터)", distance)
        }
    
    func countToTime(count : Int) -> Array<Int> {
        var timearr : [Int] = []
        var i = count
        var hour : Int?
        var min : Int?
        var sec : Int?
        hour = i/(60*60)
        i = i % (60*60)
        min = i/60
        i = i % 60
        sec = i
        timearr.append(hour!)
        timearr.append(min!)
        timearr.append(sec!)
        return timearr
    }
    }




