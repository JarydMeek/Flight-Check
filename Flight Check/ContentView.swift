//
//  ContentView.swift
//  FlightApp
//
//  Created by Jaryd Meek on 5/8/20.
//  Copyright © 2021 Jaryd Meek. All rights reserved.

//Import Libraries
import SwiftUI
import CoreData
import MapKit

//Main Variables to store handler objects for use later
let METARData = METARHandler()
let TAFData = TAFHandler()
//let NOTAMData = NOTAMHandler()
//let AHASData = AHASHandler()



//Default View
struct ContentView: View {
    //CoreData Stuff
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    
    //Variables
    @State private var selection = 0 //Tracks tab
    @State var showsAlert = true //tracks alerts
    @State var downloadData:Bool = false //shows download screen
    
    //Returns active airport code, if one exists
    func getActive() -> String {
        for curr in airports {
            if (curr.active) {
                return String(curr.code!)
            }
        }
        return "No Selected Airport Currently"
    }
    
    var body: some View {
        ZStack{
            if(getActive() == "No Selected Airport Currently"){ //checks to see if there's an active airport, if there isn't only show user the airports tab so they can select an airport
                Airports(showDownload: $downloadData)
            } else { //If a user has an active airport, show the bottom bar so they can choose what data they want to view.
                TabView(selection: $selection){
                    //Airports
                    Airports(showDownload: $downloadData).tabItem {
                        VStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text("Airports")
                        }
                    }
                    .tag(0)
                    //Weather
                    Weather().tabItem {
                        VStack {
                            Image(systemName: "cloud.sun")
                            Text("Weather")
                        }
                    }
                    .tag(1)
                    //NOTAMs
                    Notices().tabItem {
                        VStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("NOTAMs")
                        }
                    }
                    .tag(2)
                    //Birds
                    Birds().tabItem {
                        VStack {
                            Image("chick")
                            Text("AHAS Risk")
                        }
                    }
                    .tag(3)
                }.alert(isPresented: self.$showsAlert) {
                    //Disclaimer
                    Alert(title: Text("Warning"), message: Text("This app is intended for quick reference flight planning ONLY. It should not replace a thorough comprehensive flight planning process. While all data pulls from official sources, YOU are responsible for checking the validity of that data."), dismissButton: .default(Text("Understood")))
                }
            }
           if (downloadData){ //If we are downloading data, show the user a download screen
               downloadingData(isShowing: $downloadData)
           }
        }
        
    }
    
}

/* Downloading VIEW */
struct downloadingData: View {
    
    @Binding var isShowing: Bool //should the screen be showing?
    @Environment(\.presentationMode) var presentationMode //allows us to dismiss current screen
    @State private var feedback = UINotificationFeedbackGenerator() //haptics
    
    //States for loading in data, 0 = not attempted, 1 = downloaded successfully, 2 = failed, when a variable is updated, it triggers a check to see if all data has finished downloading.
    @State var metarDownload: Int = 0 {
        willSet{
            if newValue > 0 {
                checkDownloadCompletion()
            }
        }
    }
    @State var tafDownload: Int = 0 {
        willSet{
            if newValue > 0 {
                checkDownloadCompletion()
            }
        }
    }
    @State var notamDownload: Int = 0 {
        willSet{
            if newValue > 0 {
                checkDownloadCompletion()
            }
        }
    }
    @State var ahasDownload: Int = 0 {
        willSet{
            if newValue > 0 {
                checkDownloadCompletion()
            }
        }
    }
    
    
    //Function that Loads All Data
    func downloadAllData() {
        metarDownload = METARData.download()
        tafDownload = TAFData.download()
        notamDownload = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ahasDownload = 1
        }
    }
    
    func checkDownloadCompletion() {
        //Handle condition to remove view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {//Wait a sec so variable updates
            if (metarDownload > 0 && tafDownload > 0 && notamDownload > 0 && ahasDownload > 0 ) { //check if all data has been downloaded
                if (metarDownload == 2 || tafDownload == 2 || notamDownload == 2 || ahasDownload == 2) { //if one of the data sources couldn't be downloaded, error haptic
                    self.feedback.notificationOccurred(.error)
            } else { //all data could be downloaded, success haptic
                self.feedback.notificationOccurred(.success)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { //wait 2 seconds then dismiss modal
                isShowing = false
                self.presentationMode.wrappedValue.dismiss()
            }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                    Rectangle() //dims the background
                        .fill(Color.black).opacity(isShowing ? 0.75 : 0)
                        .edgesIgnoringSafeArea(.all)
                
                    //Shows download progress for all data being downloaded
                    VStack{
                        Text("Downloading Data").font(.system(size:18))
                            .onAppear{downloadAllData()}
                        Spacer()
                        HStack{
                            Text("METARs")
                            Spacer()
                            if (metarDownload == 0){
                                ProgressView()
                            }else if (metarDownload == 1) {
                                Image(systemName: "checkmark.circle").foregroundColor(.green)
                            }else{
                                Image(systemName: "xmark.circle").foregroundColor(.red)
                            }
                        }
                        Spacer()
                        HStack{
                            Text("TAFs")
                            Spacer()
                            if (tafDownload == 0){
                                ProgressView()
                            }else if (tafDownload == 1) {
                                Image(systemName: "checkmark.circle").foregroundColor(.green)
                            }else{
                                Image(systemName: "xmark.circle").foregroundColor(.red)
                            }
                        }
                        Spacer()
                        HStack{
                            Text("NOTAMs")
                            Spacer()
                            if (notamDownload == 0){
                                ProgressView()
                            }else if (notamDownload == 1) {
                                Image(systemName: "checkmark.circle").foregroundColor(.green)
                            }else{
                                Image(systemName: "xmark.circle").foregroundColor(.red)
                            }
                        }
                        Spacer()
                        HStack{
                            Text("AHAS Data")
                            Spacer()
                            if (ahasDownload == 0){
                                ProgressView()
                            }else if (ahasDownload == 1) {
                                Image(systemName: "checkmark.circle").foregroundColor(.green)
                            }else{
                                Image(systemName: "xmark.circle").foregroundColor(.red)
                            }
                        }
                    }.padding(15)
                    .frame(width: 250, height: 200)
                    .background(Color.white)
                    .foregroundColor(Color.primary)
                    .cornerRadius(16)
                }
            }
    }
    }



/* -------- */
/* HANDLERS */
/* -------- */
//Handles the download and interpretation of data from the various APIs

/* METARs */
class METARHandler {
    //Storage For METARs
    var METARs:[String] = []
    
    
    
    /* Download Function */
    //Returns 1 if Downloaded Successfully, 2 if Failed. (0 is default state, loading animation)
    func download() -> Int {
        //Storage for the raw downloaded content
        var contents:String
        //get the file (csv) from the api
        if let url = URL(string: "https://www.aviationweather.gov/adds/dataserver_current/current/metars.cache.csv") {
            do {
                //Load the raw data from the api into the string
                contents = try String(contentsOf: url)
            } catch {
                //err
                return 2
            }
        } else {
            //err
            return 2
        }
        //process the string
        var Temp:[String] = []
        contents.enumerateLines { (line, _) -> () in
            Temp.append(line)
        }
        METARs = Temp
        //successfully loaded data
        return 1
    }
    
    
    
    /* Get METAR For Specific Airport*/
    //Returns a string with the METAR for a specific Airport
    func getSpecificMETAR(code: String) -> String {
        var counter = 0
        for currentMETAR in METARs {
            counter = counter + 1
            //Split the current line on the delimiter
            let array = currentMETAR.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true)
            //Skip the first 5 lines of the file, since those contain garbage
            if counter > 5 {
                //Second box contains ICAO code
                let checkCode = array[1]
                //We found the airport, return the METAR
                if (code == checkCode) {
                    return String(array[0])
                }
            }
        }
        return "No Data Loaded"
    }
    
    
    
    /* Load Lattitude, Longitude*/
    //Returns a tuple containing lattitude and longitude for the given airport
    func getLocation(code: String) -> (lat: Double, lon: Double) {
        var counter = 0
        print(METARs.count)
        for currentMETAR in METARs {
            if counter >= METARs.count {
                break
            }
            let array = currentMETAR.split(separator: ",", maxSplits: 9, omittingEmptySubsequences: false)
            if counter > 5 {
                let checkCode = array[1]
                if (code == checkCode) {
                    return (Double(array[3]) ?? 0.0, Double(array[4]) ?? 0.0)
                }
            }
            counter = counter + 1
        }
        return (0.0, 0.0)
    }
}

/* TAFs */
class TAFHandler {
    //Storage For METARs
    var TAFs:[String] = []
    
    
    
    /* Download Function */
    //Returns 1 if Downloaded Successfully, 2 if Failed. (0 is default state, loading animation)
    func download() -> Int {
        //Storage for the raw downloaded content
        var contents:String
        //get the file (csv) from the api
        if let url = URL(string: "https://www.aviationweather.gov/adds/dataserver_current/current/tafs.cache.csv") {
            do {
                //Load the raw data from the api into the string
                contents = try String(contentsOf: url)
            } catch {
                //err
                return 2
            }
        } else {
            //err
            return 2
        }
        //process the string
        var lines:[String] = []
        contents.enumerateLines { (line, _) -> () in
            lines.append(line)
        }
        TAFs = lines
        //successfully loaded data
        return 1
    }
    
    
    
    /* Get TAF For Specific Airport*/
    //Returns a string with the TAF for a specific Airport
    func getSpecificTAF(code: String) -> String {
        var counter = 0
        for currentTAF in TAFs {
            counter = counter + 1
            //Split the current line on the delimiter
            let array = currentTAF.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true)
            //Skip the first 5 lines of the file, since those contain garbage
            if counter > 5 {
                //Second box contains ICAO code
                let checkCode = array[1]
                //We found the airport, return the METAR
                if (code == checkCode) {
                    return String(array[0])
                }
            }
        }
        return "No Data Loaded"
    }
    
    
    
    /* Load Lattitude, Longitude*/
    //Returns a tuple containing lattitude and longitude for the given airport
    func getLocation(code: String) -> (lat: Double, lon: Double) {
        var counter = 0
        for currentTAF in TAFs {
            counter = counter + 1
            let array = currentTAF.split(separator: ",", maxSplits: 9, omittingEmptySubsequences: false)
            if counter > 5 {
                let checkCode = array[1]
                if (code == checkCode) {
                    return (Double(array[3]) ?? 0.0, Double(array[4]) ?? 0.0)
                }
            }
        }
        return (0.0, 0.0)
    }
}

/* NOTAMs */
class NOTAMHandler {
    //Object to store notam alerts in
    struct NOTAM {
        let Title:String?
        let Alert:String?
        let id = UUID()
    }
    //Array to store all notams for an airport
    var NOTAMs:[NOTAM] = []
    
    func downloadNOTAMs(code: String) -> [NOTAM] {
        if let url = URL(string: "https://www.notams.faa.gov/dinsQueryWeb/queryRetrievalMapAction.do?reportType=Report&retrieveLocId=\(code)&actionType=notamRetrievalByICAOs&submit=View+NOTAMs") {
            do {
                let contents = try String(contentsOf: url)
                var rawNOTAMs = contents.components(separatedBy:"PRE")
                rawNOTAMs.remove(at: 0)
                var y = 0
                var processedNOTAMs:[NOTAM] = []
                for x in rawNOTAMs {
                    if (y%2 == 0) {
                        let start = x.index(x.startIndex, offsetBy: 4)
                        let end = x.index(x.endIndex, offsetBy: -3)
                        let cleanedNOTAMs = x[start...end]
                        let finalNOTAMs = cleanedNOTAMs.components(separatedBy:"</b>")
                        let temp = NOTAM(Title: finalNOTAMs[0], Alert: finalNOTAMs[1])
                        processedNOTAMs.append(temp)
                    }
                    y+=1
                }
                return processedNOTAMs
            } catch {
                return [NOTAM(Title: "", Alert: "NOTAMs For The Selected Airport Could Not Be Loaded")]
            }
        } else {
            return [NOTAM(Title: "", Alert: "NOTAMs For The Selected Airport Could Not Be Loaded")]
        }
        
    }
    
}

/* AHAS DATA */
class AHASHandler {
    
    
}

//Xcode Preview stuff.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


//String handling extension, adds substring functionality.
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


