//
//  ContentView.swift
//  FlightApp
//
//  Created by Jaryd Meek on 5/8/20.
//  Copyright © 2020 Jaryd Meek. All rights reserved.
//

import SwiftUI
import CoreData
import MapKit

struct ContentView: View {
    
@State private var selection = 0
    
var body: some View {
    TabView(selection: $selection){
            //First Page -> Weather?
            Airports().tabItem {
                    VStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Airports")
                    }
                }
                .tag(0)
            //
            Weather().tabItem {
                VStack {
                    Image(systemName: "cloud.sun")
                    Text("Weather")
                }
            }
                .tag(1)
            Notices().tabItem {
                VStack {
                    Image(systemName: "exclamationmark.circle")
                    Text("Notices")
                }
            }
                .tag(2)
            Birds().tabItem {
                VStack {
                    Image("chick")
                    Text("Birds")
                }
            }
                .tag(3)
        }
    }
}

/* HANDLERS */

/* METARS AND TAFS */

class METARHandler {
    @State var getDataSuccesfully = false
    var allMETARs:[String] = []
    
    init(){
        allMETARs = getAllMETARs()
    }
    
    func getAllMETARs() -> [String] {
        let rawData = downloadData()
        var lines:[String] = []
        rawData.enumerateLines { (line, _) -> () in
            lines.append(line)
        }
        return lines
    }
    
    func downloadData() -> String {
        if let url = URL(string: "https://www.aviationweather.gov/adds/dataserver_current/current/metars.cache.csv") {
            do {
                let contents = try String(contentsOf: url)
                getDataSuccesfully = true
                return contents
            } catch {
                return "ERROR"
            }
        } else {
            return "ERROR"
        }
    }

    func getSpecificMETAR(code: String) -> String {
        var counter = 0
        for currentMETAR in allMETARs {
            counter = counter + 1
            let array = currentMETAR.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true)
            if counter > 5 {
                let checkCode = array[1]
                if (code == checkCode) {
                    return String(array[0])
                }
            }
        }
        return "No Data Loaded"
    }

    func refresh() {
        allMETARs = getAllMETARs()
    }
}

class TAFHandler {
    @State var getDataSuccesfully = false
    var allTAFs:[String] = []
    
    init(){
        allTAFs = getAllTAFs()
    }
    
    func getAllTAFs() -> [String] {
        let rawData = downloadData()
        var lines:[String] = []
        rawData.enumerateLines { (line, _) -> () in
            lines.append(line)
        }
        return lines
    }
    
    func downloadData() -> String {
        if let url = URL(string: "https://www.aviationweather.gov/adds/dataserver_current/current/tafs.cache.csv") {
            do {
                let contents = try String(contentsOf: url)
                getDataSuccesfully = true
                return contents
            } catch {
                return "ERROR"
            }
        } else {
            return "ERROR"
        }
    }
    
    var lat:Double = 0.0
    var lon:Double = 0.0
    
    func getSpecificTAF(code: String) -> String {
        var counter = 0
        for currentTAF in allTAFs {
            counter = counter + 1
            let array = currentTAF.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true)
            if counter > 5 {
                let checkCode = array[1]
                if (code == checkCode) {
                    return String(array[0])
                }
            }
        }
        return "No Data Loaded"
    }
    
    func getLatLon(code: String) -> Double {
        var counter = 0
        for currentTAF in allTAFs {
            counter = counter + 1
            let array = currentTAF.split(separator: ",", maxSplits: 9, omittingEmptySubsequences: false)
            if counter > 5 {
                let checkCode = array[1]
                if (code == checkCode) {
                    lon = Double(array[8]) ?? 0.0
                    return Double(array[7]) ?? 0.0
                }
            }
        }
        return 0.0
    }
    
    func getLat(code: String) -> Double {
        return getLatLon(code: code)
    }
    
    func getLon() -> Double {
        return lon
    }
    
    func refresh() {
        allTAFs = getAllTAFs()
    }
    
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
