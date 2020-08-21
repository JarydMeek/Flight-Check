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
            FirstPage().tabItem {
                    VStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Airports")
                    }
                }
                .tag(0)
            //
            SecondPage().tabItem {
                VStack {
                    Image(systemName: "cloud.sun")
                    Text("Weather")
                }
            }
                .tag(1)
            ThirdPage().tabItem {
                VStack {
                    Image(systemName: "exclamationmark.circle")
                    Text("Notices")
                }
            }
                .tag(2)
            FourthPage().tabItem {
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

/* BEGINNING OF FIRST PAGE*/

/* AIRPORT MANAGER */

/* LISTS */

struct FirstPage: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
       entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    
    func getLat() -> Double {
        for curr in airports {
            if (curr.active) {
                return curr.lat
            }
        }
        return 0.0
    }
    
    func getLon() -> Double {
        for curr in airports {
            if (curr.active) {
                return curr.lon
            }
        }
        return 0.0
    }
    
    func getActive() -> String {
        for curr in airports {
            if (curr.active) {
                return String(curr.code!)
            }
        }
        return "No Active Airport"
    }
    /* MAPKIT STUFF */
    
    struct MapView: UIViewRepresentable {
        var coordinates: CLLocationCoordinate2D
        var span: MKCoordinateSpan
        
        func makeUIView(context: Context) -> MKMapView {
            MKMapView(frame: .zero)
        }
        
        func updateUIView(_ view: MKMapView, context: Context) {
            let region = MKCoordinateRegion(center: coordinates, span: span)
            view.setRegion(region, animated:false)
            view.isZoomEnabled = false
            view.isScrollEnabled = false
            view.isUserInteractionEnabled = false
        }
    }
    
    
    var body: some View {
        NavigationView{
            ZStack(alignment: .bottom) {
                if (getActive() != "No Active Airport") {
                    MapView(coordinates: CLLocationCoordinate2D(latitude: getLat(), longitude: getLon()), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.12))
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    MapView(coordinates: CLLocationCoordinate2D(latitude: 34.8283, longitude: -95.5795), span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 65))
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                }

                Text(getActive())
                    .padding(5)
                    .background(Color("darkLight").opacity(0.75))
                    .foregroundColor(Color("lightDark"))
                    .font(.largeTitle)
                    .cornerRadius(10)
                    .frame(height: 200)
                    NavigationLink(destination: AirportEditor()) {
                        Text("Change Active Airport")
                    }
                    .padding(10)
                    .background(Color.accentColor)
                    .foregroundColor(Color("darkLight"))
                    .cornerRadius(10)
                    .frame(height: 75)
            }.frame(maxHeight: .infinity)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct airportRow: View {
    @ObservedObject var airport: Airport
    var body: some View {
        HStack{
            if(airport.active) {
                Image(systemName: "circle.fill").foregroundColor(.blue)
            } else {
                Image(systemName: "circle.fill").opacity(0)
            }
            Text(airport.code ?? "Error")
        }
    }
}
struct AirportEditor: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
       entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    @Environment(\.presentationMode) var presentationMode
    
        var body: some View {
            VStack{
                List {
                    ForEach(airports){ airport in
                        Button(action: {
                            self.makeActive(airport)
                        }){
                        airportRow(airport: airport)
                        }

                    }.onDelete(perform: removeAirport)
                }
                .navigationBarTitle("Select Airport")
                .navigationBarItems(trailing:
                NavigationLink(destination: AddAirport()) {
                    Image(systemName: "plus")
                }
                )
            }
        }
        func removeAirport(at offsets: IndexSet) {
            for index in offsets {
                let airport = airports[index]
                context.delete(airport)
                try? context.save()
            }
        }
    func makeActive(_ airport: Airport){
        for curr in airports {
            curr.active = false
        }
        airport.active = true
        self.presentationMode.wrappedValue.dismiss()
    }
}



struct AddAirport: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
       entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    @Environment(\.presentationMode) var presentationMode
    
    enum activeAlert {
        case duplicate, wrongLength, invalidCode
    }
    

    
    @State private var airportCode: String = ""
    @State private var showAlert = false
    @State private var selectAlert: activeAlert = .wrongLength
    

    
    @State var goBack = false
    
    var body: some View {
        NavigationView{
            VStack{
                    TextField("Enter Airport Code", text: $airportCode)
                        .padding(5)
                        .background(Color("lightDark").opacity(0.10))
                        .foregroundColor(Color("lightDark"))
                        .font(.title)
                        .cornerRadius(10)
                        .frame(width: 250)
                        .multilineTextAlignment(.center)
                        .disableAutocorrection(true)
                    Button(action: {
                        if (self.airportCode.count == 4) {
                            var duplicate = false
                            for curr in self.airports {
                                if (curr.code == self.airportCode.uppercased()) {
                                    duplicate = true
                                }
                            }
                            if (duplicate) {
                                self.selectAlert = .duplicate
                                self.showAlert = true
                            } else {
                                let resultOfAdd = self.addAirport()
                                
                                if (resultOfAdd) {
                                    self.presentationMode.wrappedValue.dismiss()
                                } else {
                                    self.selectAlert = .invalidCode
                                    self.showAlert = true
                                }
                                

                            }
                        } else {
                            self.selectAlert = .wrongLength
                            self.showAlert = true
                            
                        }
                    }){
                        Text("Add Airport")
                    }.alert(isPresented: $showAlert) {
                        switch selectAlert{
                            case .wrongLength:
                                return Alert(title: Text("Error Adding Airport"), message: Text("Please Enter A 4 Digit Airport Identifier"), dismissButton: .default(Text("Got it!")))
                            case .duplicate:
                                   return Alert(title: Text("Error Adding Airport"), message: Text("Airport Already Added"), dismissButton: .default(Text("Got it!")))
                            case .invalidCode:
                                   return Alert(title: Text("Error Adding Airport"), message: Text("Invalid Airport Code"), dismissButton: .default(Text("Got it!")))
                        }
                        
                    }
                    .padding(10)
                    .background(Color.accentColor)
                    .foregroundColor(Color("darkLight"))
                    .cornerRadius(10)
                    .frame(height: 75)
                Spacer()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        .navigationBarTitle("Add A New Airport")
    }
    func addAirport() -> Bool {
        let TAFData = TAFHandler()
        for curr in airports {
            curr.active = false
        }
        let newAirport = Airport(context: context)
        newAirport.id = UUID()
        newAirport.code = airportCode.uppercased()
        newAirport.dateAdded = Date()
        newAirport.active = true
        newAirport.lat = TAFData.getLat(code: airportCode.uppercased())
        newAirport.lon = TAFData.getLon()
        if (newAirport.lat == 0.0 && newAirport.lon == 0.0) {
            context.delete(newAirport)
            return false
        } else {
            try? context.save()
            return true
            
        }
    }

}


/* BEGINNING OF SECOND PAGE*/

/* WEATHER */

struct SecondPage: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
       entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    
    
    let METARData = METARHandler()
    let TAFData = TAFHandler()
    @State var currentMETAR: String = "Loading..."
    @State var currentTAF: String = "Loading..."
    
    func getActive() -> String {
        for curr in airports {
            if (curr.active) {
                return String(curr.code!)
            }
        }
        return "No Selected Airport Currently"
    }

    func loadData() {
        METARData.refresh()
        currentMETAR = METARData.getSpecificMETAR(code: getActive())
        TAFData.refresh()
        currentTAF = TAFData.getSpecificTAF(code: getActive())
    }

    func getCurrentMETAR() -> String {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentMETAR = METARData.getSpecificMETAR(code: getActive())
        }
        return currentMETAR
    }
    func getCurrentTAF() -> String {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        currentTAF = TAFData.getSpecificTAF(code: getActive())
        }
        return currentTAF
    }
    
    var body: some View {
        VStack{
            HStack{
                HStack{
                    Text(getActive())
                    if (getActive().count == 4) {
                        Text("Current Weather")
                    }

                }
                .padding(10)
                .background(Color.accentColor)
                .foregroundColor(Color("darkLight"))
                .cornerRadius(10)
                .frame(height: 50)
                
                
                Button(action: {
                    loadData()
                }, label: {
                    Image(systemName: "arrow.clockwise")
                        .padding(10)
                        .background(Color.accentColor)
                        .foregroundColor(Color("darkLight"))
                        .cornerRadius(10)
                        .frame(height: 50)
                })
            }

            Text("METARs - ")
                .padding(10)
                .background(Color.accentColor)
                .foregroundColor(Color("darkLight"))
                .cornerRadius(10)
                .frame(height: 35)
            Text(getCurrentMETAR()).frame(height: 150)
            Text("TAFs - ")
                .padding(10)
                .background(Color.accentColor)
                .foregroundColor(Color("darkLight"))
                .cornerRadius(10)
                .frame(height: 35)
            Text(getCurrentTAF()).frame(height: 200)
            Spacer()
        }.onAppear {
            loadData()
        }
    }
}
    

/* BEGINNING OF THIRD PAGE*/
    
/* NOTICES */

/*  */

struct ThirdPage: View {
    var body: some View {
        VStack{
            Text("Notices")
        }
    }
}

/* BEGINNING OF FOURTH PAGE*/

/* BIRBS */

/*  */


struct FourthPage: View {
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
                print("File Read Error for file \(filepath)")
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
        return "Not Found"
    }
    
    func makeURL(icao: String) -> String {
        var url = "http://www.usahas.com/webservices/AHAS.asmx/GetAHASRisk12?Area=%27"
        let name = getName(icao: icao)
        
        for char in name {
            if char == " " {
                url = url + "%20"
            } else {
                url = url + String(char)
            }
        }
        //SHEPPARD%20AFB%20WICHITA%20FALLS%20MUNI%27&iMonth=8&iDay=20&iHour=6
        url = url + "%27&iMonth=" + String(Calendar.current.dateComponents([.month], from: Date()).month!) + "&iDay=" + String(Calendar.current.dateComponents([.day], from: Date()).day!) + "&iHour=" +  String(Calendar.current.dateComponents([.hour], from: Date()).hour!)
        print(url)
        return url
    }
    
    struct birdData {
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
    
    func downloadData(inputURL: String) -> String {
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

    func loadData() -> [birdData] {
        let data = Data(downloadData(inputURL: makeURL(icao: getActive())).utf8) // Get the NSData
        let xmlParser = XMLParser(data: data)
        let delegate = MyDelegate() // This is your own delegate - see below
        xmlParser.delegate = delegate
        if xmlParser.parse() {
            print("Result \(delegate.data)")
            return delegate.data
        }
        return delegate.data
    }
    
    class MyDelegate: NSObject, XMLParserDelegate {
        // Simple state machine to capture fields and add completed Person to array
        var data: [birdData] = []
        enum State { case none, Route, Segment, Hour, DateTime, NEXRADRISK, SOARRISK, AHASRISK, BasedON, TIDepth }
        var state: State = .none
        var newData: birdData? = nil

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
            switch elementName {
            case "Table" :
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
    /*
        class XMLHandler: NSObject, XMLParserDelegate{
            var data: [birdData] = []
            var elementName: String = String()
            var Route = String()
            var Segment = String()
            var Hour = String()
            var DateTime = String()
            var NEXRADRISK = String()
            var SOARRISK = String()
            var AHASRISK = String()
            var BasedON = String()
            var TIDepth = Int()
            
            func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

                if elementName == "title" {
                    Route = String()
                    Segment = String()
                    Hour = String()
                    DateTime = String()
                    NEXRADRISK = String()
                    SOARRISK = String()
                    AHASRISK = String()
                    BasedON = String()
                    TIDepth = Int()
                }

                self.elementName = elementName
            }
            func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
                if elementName == "book" {
                    let currentData = birdData(Route: Route, Segment: Segment, Hour: Hour, DateTime: DateTime,NEXRADRISK: NEXRADRISK, SOARRISK: SOARRISK, AHASRISK: AHASRISK, BasedON: BasedON, TIDepth: TIDepth)
                    data.append(currentData)
                }
            }
            func parser(_ parser: XMLParser, foundCharacters string: String) {
                let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                if (!data.isEmpty) {
                    if self.elementName == "Route" {
                        Route += data
                    } else if self.elementName == "Segment" {
                        Segment += data
                    }else if self.elementName == "Hour" {
                        Hour += data
                    }else if self.elementName == "DateTime" {
                        DateTime += data
                    }else if self.elementName == "NEXRADRISK" {
                        NEXRADRISK += data
                    }else if self.elementName == "SOARRISK" {
                        SOARRISK += data
                    }else if self.elementName == "BasedON" {
                        BasedON += data
                    }else if self.elementName == "TIDepth" {
                        TIDepth += Int(data)!
                    }
                }
            }
        }
    */
    
    var body: some View {
        VStack{
            //Text(data.downloadData(input: makeURL(icao: getActive())))
            Text(loadData()[0].Segment)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
