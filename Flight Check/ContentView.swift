//
//  ContentView.swift
//  FlightApp
//
//  Created by Jaryd Meek on 5/8/20.
//  Copyright © 2020 Jaryd Meek. All rights reserved.
//

//if(Chicken){
// Little
//}




import SwiftUI
import CoreData
import MapKit

struct ContentView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
       entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    @State private var selection = 0
    @State var showsAlert = true
    
    
    func getActive() -> String {
        for curr in airports {
            if (curr.active) {
                return String(curr.code!)
            }
        }
        return "No Selected Airport Currently"
    }
    
var body: some View {
    if(getActive() == "No Selected Airport Currently"){
        Airports()
    } else {
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
                    Text("NOTAMs")
                }
            }
                .tag(2)
            Birds().tabItem {
                VStack {
                    Image("chick")
                    Text("Birbs")
                }
            }
                .tag(3)
    }.alert(isPresented: self.$showsAlert) {
        Alert(title: Text("Warning"), message: Text("This app is intended for quick reference flight planning ONLY. It should not replace a thorough comprehensive flight planning process. While all data pulls from official sources, YOU are responsible for checking the validity of that data."), dismissButton: .default(Text("Are you silly? I'm still gonna send it")))
    }
    //.alert(isPresented: self.$showsAlert) {
     //  Alert(title: Text("EVEN MORE IMPORTANT WARNING"), message: Text("If you're a FAIP, you legally have to tell us. Otherwise it's entrapment"), dismissButton: .default(Text("No, I didn't cry on Drop Night")))
   //}
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
    
    var lat:Double = 0.0
    var lon:Double = 0.0
    
    func getLatLon(code: String) -> Double {
        var counter = 0
        for currentTAF in allMETARs {
            counter = counter + 1
            let array = currentTAF.split(separator: ",", maxSplits: 9, omittingEmptySubsequences: false)
            if counter > 5 {
                let checkCode = array[1]
                if (code == checkCode) {
                    lon = Double(array[4]) ?? 0.0
                    return Double(array[3]) ?? 0.0
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


//String handling
extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}


