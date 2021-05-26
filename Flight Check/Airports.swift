//
//  Airports.swift
//  Flight Check
//
//  Created by Jaryd Meek on 12/19/20.
//  Copyright © 2020 Jaryd Meek. All rights reserved.
//
import SwiftUI
import CoreData
import MapKit

/* BEGINNING OF FIRST PAGE*/

/* AIRPORT MANAGER */

/* LISTS */

struct Airports: View {
    
    //Coredata stuff
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    
    //Variables
    @Binding var showDownload:Bool //controls download modal
    
    //Get lattitude of current airport
    func getLat() -> Double {
        for curr in airports {
            if (curr.active) {
                return curr.lat
            }
        }
        return 0.0
    }
    
    //Get longitude of current airport
    func getLon() -> Double {
        for curr in airports {
            if (curr.active) {
                return curr.lon
            }
        }
        return 0.0
    }
    //get current airport
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
                // show map of current active airport
                if (getActive() != "No Active Airport") {
                    MapView(coordinates: CLLocationCoordinate2D(latitude: getLat(), longitude: getLon()), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.12))
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    //us map if no airport is selected
                    MapView(coordinates: CLLocationCoordinate2D(latitude: 34.8283, longitude: -95.5795), span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 65))
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                }

                //Airport Name
                VStack{
                    Spacer()
                    Text(getActive())
                        .font(.largeTitle)
                        .padding(5)
                        .background(Color("darkLight").opacity(0.75))
                        .foregroundColor(Color("lightDark"))
                        .cornerRadius(10)
                    HStack{
                        VStack{
                            Text("Last Data Refresh:")
                            HStack{
                                if lastDownloaded != nil {
                                    Text(lastDownloaded!, style: .time)
                                    Text("-")
                                    Text(lastDownloaded!, style: .date)
                                } else {
                                    Text("Data Never Loaded")
                                }
                            }
                        }
                        Button(action: {
                            showDownload = true
                        }, label: {
                            Image(systemName: "arrow.clockwise")
                                .padding(10)
                                .foregroundColor(Color.accentColor)
                        })
                    }
                    .padding(5)
                    .background(Color("darkLight").opacity(0.75))
                    .foregroundColor(Color("lightDark"))
                    .cornerRadius(10)
                    //Change active airport Button
                    NavigationLink(destination: AirportEditor(showDownload: $showDownload)) {
                        Text("Change Selected Airport")
                    }
                    .padding(10)
                    .background(Color.accentColor)
                    .foregroundColor(Color("darkLight"))
                    .cornerRadius(10)
                    Spacer().frame(height:20)
                }
            }.frame(maxHeight: .infinity)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct airportRow: View {
    //coredata
    @Environment(\.managedObjectContext) var context
    
    //airport object
    @ObservedObject var airport: Airport
    
    var body: some View {
        HStack{
            //adds dot if the row is the active airport
            if(airport.active) {
                Image(systemName: "circle.fill").foregroundColor(.blue)
            } else {
                Image(systemName: "circle.fill").opacity(0)
            }
            //airport code
            Text(airport.code ?? "Error")
            Spacer()
            //Favorite airports/stars
            if(airport.favorite) {
                Button(action: {
                    airport.favorite.toggle()
                    try? context.save()
                }) {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                }
            } else {
                Button(action: {
                    airport.favorite.toggle()
                    try? context.save()
                }) {
                    Image(systemName: "star").foregroundColor(.gray)
                }
            }
        }
    }
}


struct AirportEditor: View {
    //more coredata
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.favorite, ascending: false),
                          NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    
    //presentationmode so we can dismiss views
    @Environment(\.presentationMode) var presentationMode
    
    //trigger to show download dialogue
    @Binding var showDownload:Bool
    
    var body: some View {
        VStack{
            List {
                //show all airports
                ForEach(airports){ airport in
                    Button(action: { //if airport is picked, make active, download data, and dismiss view.
                        showDownload = true
                        self.presentationMode.wrappedValue.dismiss()
                        self.makeActive(airport)
                    }){
                        airportRow(airport: airport)
                    }
                    
                }.onDelete(perform: removeAirport) // swipe to delete
            }
            .navigationBarTitle("Select Airport")
            .navigationBarItems(trailing:
                                    NavigationLink(destination: AddAirport(loadData: $showDownload)){
                                        Image(systemName: "plus")
                                    }
            )
        }
    }
    
    //remove the airport from coredata storage.
    func removeAirport(at offsets: IndexSet) {
        for index in offsets {
            let airport = airports[index]
            context.delete(airport)
            try? context.save()
        }
    }
    //make the selected airport active
    func makeActive(_ airport: Airport){
        showDownload = true
        for curr in airports { //makes all the other airports not active
            curr.active = false
        }
        airport.active = true //makes selected airport active
        try? context.save()
    }
}



struct AddAirport: View {
    //coredata
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    
    //presentationMode
    @Environment(\.presentationMode) var presentationMode
    
    //selection for alerts of errors
    enum activeAlert {
        case duplicate, wrongLength, invalidCode, noInternet
    }
    
    //vibration
    @State private var feedback = UINotificationFeedbackGenerator()
    
    //variables
    @State private var airportCode: String = "" //stores airport code
    @State private var showAlert = false //triggers alert
    @State private var selectAlert: activeAlert = .wrongLength //sets default alert
    @Binding var loadData:Bool //triggers download data modal.
    
    var body: some View {
        NavigationView{
            VStack{
                //box to add airport code
                TextField("Enter Airport Code", text: $airportCode)
                    .padding(5)
                    .background(Color("lightDark").opacity(0.10))
                    .foregroundColor(Color("lightDark"))
                    .font(.title)
                    .cornerRadius(10)
                    .frame(width: 250)
                    .multilineTextAlignment(.center)
                    .disableAutocorrection(true)
                //add airport button.
                Button(action: {
                    //makes sure we can verify the icao code
                    if (METARData.download() == 2) {
                        self.feedback.notificationOccurred(.error)
                        self.selectAlert = .noInternet
                        self.showAlert = true
                        //makes sure length is 4
                    } else if (self.airportCode.count == 4) {
                        //checks for duplicate
                        var duplicate = false
                        for curr in self.airports {
                            if (curr.code == self.airportCode.uppercased()) {
                                duplicate = true
                            }
                        }
                        if (duplicate) {
                            self.feedback.notificationOccurred(.error)
                            self.selectAlert = .duplicate
                            self.showAlert = true
                        } else {
                            //otherwise try to add
                            let resultOfAdd = self.addAirport()
                            
                            if (resultOfAdd) {
                                
                                self.presentationMode.wrappedValue.dismiss()
                                loadData = true
                            } else {
                                //invalid code err
                                self.feedback.notificationOccurred(.error)
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
                    
                    //alerts
                    switch selectAlert{
                    case .wrongLength:
                        return Alert(title: Text("Error Adding Airport"), message: Text("Please Enter A 4 Digit Airport Identifier"), dismissButton: .default(Text("Got it!")))
                    case .duplicate:
                        return Alert(title: Text("Error Adding Airport"), message: Text("Airport Already Added"), dismissButton: .default(Text("Got it!")))
                    case .invalidCode:
                        return Alert(title: Text("Error Adding Airport"), message: Text("Invalid Airport Code"), dismissButton: .default(Text("Got it!")))
                    case .noInternet:
                        return Alert(title: Text("Error Adding Airport"), message: Text("Couldn't Load Airports. Check Your Internet Connection"), dismissButton: .default(Text("Got it!")))
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
        //create new airport object and add neccesary information.
        let newAirport = Airport(context: context)
        newAirport.id = UUID()
        newAirport.code = airportCode.uppercased()
        newAirport.dateAdded = Date()
        
        let results = METARData.getLocation(code: airportCode.uppercased())
        newAirport.lat = results.lat
        newAirport.lon = results.lon
        newAirport.favorite = false
        //if invalid airport (no location)
        if (newAirport.lat == 0.0 && newAirport.lon == 0.0) {
            context.delete(newAirport)
            return false
        } else {
            //save new airport and make it active.
            for curr in airports {
                curr.active = false
            }
            newAirport.active = true
            try? context.save()
            return true
            
        }
    }
    
}
