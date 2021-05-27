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
let NOTAMData = NOTAMHandler()
let AHASData = AHASHandler()

var lastDownloaded:Date? = nil

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
    @State var downloadData:Bool = false //shows download screen
    @State var firstOpen = false //Show first warning
    
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
                    .sheet(isPresented: $firstOpen) {
                    WelcomeScreen(showWarning: $firstOpen)
                    }.onAppear{
                        firstOpen = true
                    }
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
                }
                .onAppear{
                    downloadData = true
                }
            }
           if (downloadData){ //If we are downloading data, show the user a download screen
            downloadingData(isShowing: $downloadData)
           }
        }
        .accentColor(Color("lightBlue"))
        
    }
    
}

/* First Welcome / Warning */

//Helper
struct Row: View {
    var image: String
    var title: String
    var subtitle: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32)
                .foregroundColor(color)
                    
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
}

struct WelcomeScreen: View {
    @Binding var showWarning: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Flight Check")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            Image("plane")
            Spacer()
            VStack(spacing: 24) {
                Row(image: "exclamationmark.triangle", title: "Warning", subtitle: "This app is intended for quick reference flight planning ONLY. It should not replace a thorough comprehensive flight planning process. While all data pulls from official sources, YOU are responsible for checking the validity of that data.", color: .orange)
                
                Row(image: "terminal", title: "Open Source", subtitle: "This app is entirely open source and any issues can be reported at: \nhttps://github.com/JarydMeek/Flight-Check", color: .blue)
            }
            .padding(.leading)
            
            Spacer()
            Spacer()
            
            Button(action: { showWarning = false }) {
                HStack {
                    Spacer()
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            .frame(height: 50)
            .background(Color.accentColor)
            .cornerRadius(15)
        }
        .accentColor(Color("lightBlue"))
        .padding()
    }
}

/* Downloading VIEW */
struct downloadingData: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    
    
    func getActive() -> String {
        for curr in airports {
            if (curr.active) {
                return String(curr.code!)
            }
        }
        return "No Selected Airport Currently"
    }
    
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
        lastDownloaded = Date()
        metarDownload = METARData.download()
        tafDownload = TAFData.download()
        notamDownload = NOTAMData.download(code: getActive())
        ahasDownload = AHASData.download(code: getActive())
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
                    .background(Color("darkLight"))
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
        return "No METAR Available For The Given Airport"
    }
    
    
    
    /* Load Lattitude, Longitude*/
    //Returns a tuple containing lattitude and longitude for the given airport
    func getLocation(code: String) -> (lat: Double, lon: Double) {
        var counter = 0
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
        return "No TAF Available For The Given Airport"
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
    
    func getNOTAMS(code: String) -> [NOTAM] {
        
        return NOTAMs
    }
    
    //download notams and clean them
    func download(code: String) -> Int {
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
                NOTAMs = processedNOTAMs
                return 1
            } catch {
                return 2
            }
        } else {
            return 2
        }
        
    }
    
}

/* AHAS DATA */
//Dear US Government,
//Why can't you give me clean data.
class AHASHandler {
    
    var birdStorage: [birdData] = []
    
    struct airportTranslator {
        let code: String?
        let name: String?
    }
    
    var knownAirports = [airportTranslator]()
    
    func csvToString(fileName:String, fileType: String)-> String!{
            guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
                else {
                    return nil
            }
            do {
                return try String(contentsOfFile: filepath, encoding: .utf8)
            } catch {
                return nil
            }
        }
    
    func cleanCSVToArray(data: String) -> [[String]] {
            var result: [[String]] = []
            let rows = data.components(separatedBy: "\n")
            for row in rows {
                let columns = row.components(separatedBy: ",")
                result.append(columns)
            }
            return result
        }
    
    func readCSV() -> [[String]] {
        let data = csvToString(fileName: "icaoToNameAHAS", fileType: "csv")
        return cleanCSVToArray(data: data!)
    }
    
    func getName(icao: String) -> String {
        
        let data = readCSV()
        
        for current in data {
            if current[0] == icao {
                return current[1]
            }
        }
        return "NULL"
    }
    
    func makeURL(icao: String) -> String {
        var url = "http://www.usahas.com/webservices/AHAS.asmx/GetAHASRisk12?Area=%27"
        let name = getName(icao: icao)
        
        if (name == "NULL") {
            return "NULL"
        } else {
            for char in name {
                if char == " " {
                    url = url + "%20"
                } else {
                    url = url + String(char)
                }
            }
            url = url + "%27&iMonth=" + String(Calendar.current.dateComponents([.month], from: Date()).month!) + "&iDay=" + String(Calendar.current.dateComponents([.day], from: Date()).day!) + "&iHour=" +  String(Calendar.current.dateComponents([.hour], from: Date()).hour!)
            return url
        }
    }
    
    struct birdData {
        var id = UUID()
        var Route = ""
        var Segment = ""
        var Hour = ""
        var DateTime = ""
        var NEXRADRISK = ""
        var SOARRISK = ""
        var AHASRISK = ""
        var BasedON = ""
        var TIDepth = ""
    }
    
    func getFromURL(inputURL: String) -> String {
        if let url = URL(string: inputURL) {
            do {
                let contents = try String(contentsOf: url)
                return contents
            } catch {
                return "ERROR"
            }
        } else {
            return "ERROR"
        }
    }

    func loadData(code: String) -> [birdData] {
        if makeURL(icao: code) != "NULL" {
            let data = Data(getFromURL(inputURL: makeURL(icao: code)).utf8) // Get the NSData
            let xmlParser = XMLParser(data: data)
            let delegate = MyDelegate()
            xmlParser.delegate = delegate
            if xmlParser.parse() {
                return delegate.data
            }
            return delegate.data
        }
        return []
    }
    func download(code: String) -> Int {
        birdStorage = loadData(code: code)
        if birdStorage.count == 0 {
            return 2
        }
        return 1
    }
    
    func getBirdData(code: String) -> [birdData] {
        return birdStorage
    }
    
    class MyDelegate: NSObject, XMLParserDelegate {
        var data: [birdData] = []
        enum State { case none, Route, Segment, Hour, DateTime, NEXRADRISK, SOARRISK, AHASRISK, BasedON, TIDepth }
        var state: State = .none
        var newData: birdData? = nil

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
            switch elementName {
            case "Table" :
                self.newData = birdData()
                self.state = .none
            case "Table1" :
                self.newData = birdData()
                self.state = .none
            case "Table2" :
                self.newData = birdData()
                self.state = .none
            case "Table3" :
                self.newData = birdData()
                self.state = .none
            case "Table4" :
                self.newData = birdData()
                self.state = .none
            case "Table5" :
                self.newData = birdData()
                self.state = .none
            case "Table6" :
                self.newData = birdData()
                self.state = .none
            case "Table7" :
                self.newData = birdData()
                self.state = .none
            case "Table8" :
                self.newData = birdData()
                self.state = .none
            case "Table9" :
                self.newData = birdData()
                self.state = .none
            case "Table10" :
                self.newData = birdData()
                self.state = .none
            case "Table11" :
                self.newData = birdData()
                self.state = .none
            case "Route":
                self.state = .Route
            case "Segment":
                self.state = .Segment
            case "Hour":
                self.state = .Hour
            case "DateTime":
                self.state = .DateTime
            case "NEXRADRISK":
                self.state = .NEXRADRISK
            case "SOARRISK":
                self.state = .SOARRISK
            case "AHASRISK":
                self.state = .AHASRISK
            case "BasedON":
                self.state = .BasedON
            case "TIDepth":
                self.state = .TIDepth
            default:
                self.state = .none
            }
        }
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if let newData = self.newData, elementName == "Table" {
                self.data.append(newData)
                self.newData = nil
            } else if let newData = self.newData, elementName == "Table1" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table2" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table3" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table4" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table5" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table6" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table7" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table8" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table9" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table10" {
                self.data.append(newData)
                self.newData = nil
            }else if let newData = self.newData, elementName == "Table11" {
                self.data.append(newData)
                self.newData = nil
            }
            self.state = .none
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            guard let _ = self.newData else { return }
            switch self.state {
            case .Route:
                self.newData!.Route = string
            case .Segment:
                self.newData!.Segment = string
            case .Hour:
                self.newData!.Hour = string
            case .DateTime:
                self.newData!.DateTime = string
            case .NEXRADRISK:
                self.newData!.NEXRADRISK = string
            case .SOARRISK:
                self.newData!.SOARRISK = string
            case .AHASRISK:
                self.newData!.AHASRISK = string
            case .BasedON:
                self.newData!.BasedON = string
            case .TIDepth:
                self.newData!.TIDepth = string
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        }
    }
    
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


