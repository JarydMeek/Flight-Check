//
//  Birds.swift
//  Flight Check
//
//  Created by Jaryd Meek on 12/19/20.
//  Copyright © 2020 Jaryd Meek. All rights reserved.
//

import SwiftUI

struct Birds: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
       entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>

    @State var validArea = Bool()


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
        if makeURL(icao: getActive()) == "NULL" {
            print(makeURL(icao: getActive()))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                validArea = false
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                validArea = true
            }
            let data = Data(downloadData(inputURL: makeURL(icao: getActive())).utf8) // Get the NSData
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

    func loadAllData() -> String {
        _ = loadData()
        return getActive()
    }
    
    var body: some View {
        VStack {
            Text(loadAllData())
                .padding(10)
                .background(Color.accentColor)
                .foregroundColor(Color("darkLight"))
                .cornerRadius(10)
            if validArea {
                ScrollView {
                    VStack{
                        ForEach (loadData(), id: \.self.id) { data in
                            HStack{
                                Spacer()
                                VStack {
                                    Text("Segment - " + data.Segment)
                                    Text(data.DateTime)
                                    HStack {
                                        Text("NEXTRAD - " + data.NEXRADRISK)
                                        Text("SOAR - " + data.SOARRISK)
                                    }
                                    Text("Risk Evalutation Based On - " + data.BasedON)
                                    if data.TIDepth == String(99999) {
                                        Text("Height - No Data")
                                    } else {
                                        Text("Height - " + data.TIDepth)
                                    }
                                }
                                Spacer()
                                if data.AHASRISK.uppercased() == "LOW" {
                                    Text(data.AHASRISK.uppercased())
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(Color("darkLight"))
                                } else if data.AHASRISK.uppercased() == "MODERATE" {
                                    Text(data.AHASRISK.uppercased())
                                        .padding()
                                        .background(Color.yellow)
                                        .foregroundColor(Color("darkLight"))
                                }else if data.AHASRISK.uppercased() == "SEVERE" {
                                    Text(data.AHASRISK.uppercased())
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(Color("darkLight"))
                                }
                                Spacer()
                            }
                            Divider()
                        }
                    }
                }
            }else {
                VStack{
                    Spacer()
                    Text("Avian Hazard Data Could Not Be Loaded For The Selected Airport").multilineTextAlignment(.center)
                    Spacer()
                }
            }
        }
    }
}

struct Birds_Previews: PreviewProvider {
    static var previews: some View {
        Birds()
    }
}
