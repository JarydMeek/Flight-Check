//
//  ContentView.swift
//  FlightApp
//
//  Created by Jaryd Meek on 5/8/20.
//  Copyright © 2020 Jaryd Meek. All rights reserved.
//

import SwiftUI
import CoreData

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

/* BEGINNING OF FIRST PAGE*/

/* AIRPORT MANAGER */

/* LISTS */

struct FirstPage: View {
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
    
    
    var body: some View {
        NavigationView{
            HStack{
                Text(getActive())
                NavigationLink(destination: AirportEditor()) {
                    Text("Edit")
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct airportRow: View {
    var airport: Airport
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
    
    @State private var airportCode: String = ""
    @State private var showAlert = false
    @State private var showingAlert = false
    
    @State var goBack = false
    
    var body: some View {
        NavigationView{
            VStack{
                HStack{
                    TextField("Airport Code", text: $airportCode).disableAutocorrection(true)
                    Button(action: {
                        if (self.airportCode.count == 4) {
                            var duplicate = false
                            for curr in self.airports {
                                if (curr.code == self.airportCode.uppercased()) {
                                    duplicate = true
                                }
                            }
                            if (duplicate) {
                                self.showAlert = true
                            } else {
                                self.addAirport()
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            self.showingAlert = true
                            
                        }
                    }){
                        Text("Add Airport")
                    }.alert(isPresented: $showingAlert) {
                        Alert(title: Text("Error Adding Airport"), message: Text("Please Enter A 4 Digit Airport Identifier"), dismissButton: .default(Text("Got it!")))
                    }.alert(isPresented: $showAlert) {
                        Alert(title: Text("Error Adding Airport"), message: Text("Airport Already Added"), dismissButton: .default(Text("Got it!")))
                    }
                }
                Spacer().frame(height: 200)
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    func addAirport() {
        for airport in airports {
            airport.active = false;
        }
        let newAirport = Airport(context: context)
        newAirport.id = UUID()
        newAirport.code = airportCode.uppercased()
        newAirport.dateAdded = Date()
        newAirport.active = true
        try? context.save()
    }

}


/* BEGINNING OF SECOND PAGE*/

/* WEATHER */

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
        return "LOLNOPE"
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
        return "LOLNOPE"
    }
}

struct SecondPage: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
       entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    
    
    let METARData = METARHandler()
    let TAFData = TAFHandler()
    @State private var code: String = "NULL"

    func getActive() -> String {
        for curr in airports {
            if (curr.active) {
                return String(curr.code!)
            }
        }
        return "No Selected Airport Currently"
    }
    
    var body: some View {
        VStack{
            Text(getActive())
            
            Text("METARs - ")
            Text(METARData.getSpecificMETAR(code: getActive())).frame(height: 100)
            Text("TAFs - ")
            Text(TAFData.getSpecificTAF(code: getActive())).frame(height: 200)
            Spacer().frame(height: 200)
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
    var body: some View {
        VStack{
            Text("Birds")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
