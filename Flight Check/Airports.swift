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
    @State var showsAlert = true
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
    @Environment(\.managedObjectContext) var context
    var body: some View {
        HStack{
            if(airport.active) {
                Image(systemName: "circle.fill").foregroundColor(.blue)
            } else {
                Image(systemName: "circle.fill").opacity(0)
            }
            Text(airport.code ?? "Error")
            Spacer()
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
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Airport.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Airport.favorite, ascending: false),
                          NSSortDescriptor(keyPath: \Airport.dateAdded, ascending: false)]
    ) var airports: FetchedResults<Airport>
    @Environment(\.presentationMode) var presentationMode
    
    @State var loadingViewShowing = false
    @State var downloading:Int? = 0
    
    var body: some View {
        VStack{
            LoadingView(isShowing: $loadingViewShowing) {
                List {
                    ForEach(airports){ airport in
                        Button(action: {
                            loadingViewShowing = true
                            self.makeActive(airport)
                        }){
                            airportRow(airport: airport)
                        }
                        
                    }.onDelete(perform: removeAirport)
                }
                .navigationBarTitle("Select Airport")
                .navigationBarItems(trailing:
                                        NavigationLink(destination: AddAirport(loadData: $loadingViewShowing)){
                                            Image(systemName: "plus")
                                        }
                )
            }
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
    @Binding var loadData:Bool
    
    
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
                                loadData = true
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
        let METARData = METARHandler()
        for curr in airports {
            curr.active = false
        }
        let newAirport = Airport(context: context)
        newAirport.id = UUID()
        newAirport.code = airportCode.uppercased()
        newAirport.dateAdded = Date()
        newAirport.active = true
        newAirport.lat = METARData.getLat(code: airportCode.uppercased())
        newAirport.lon = METARData.getLon()
        newAirport.favorite = false
        if (newAirport.lat == 0.0 && newAirport.lon == 0.0) {
            context.delete(newAirport)
            return false
        } else {
            try? context.save()
            return true
            
        }
    }
    
}

struct LoadingView<Content>: View where Content: View {
    
    
    @Binding var isShowing: Bool  // should the modal be visible?
    var content: () -> Content
    var text: String?  // the text to display under the ProgressView - defaults to "Loading..."
    @State private var downloadAmount = 0.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @Environment(\.presentationMode) var presentationMode
    
    
    //States for loading in data, 0 = not attempted, 1 = downloaded successfully, 2 = failed
    @State var metarDownload: Int = 0
    @State var tafDownload: Int = 0
    @State var notamDownload: Int = 0
    @State var ahasDownload: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // the content to display - if the modal is showing, we'll blur it
                content()
                    .disabled(isShowing)
                    .blur(radius: isShowing ? 2 : 0)
                
                // all contents inside here will only be shown when isShowing is true
                if isShowing {
                    // this Rectangle is a semi-transparent black overlay
                    Rectangle()
                        .fill(Color.black).opacity(isShowing ? 0.6 : 0)
                        .edgesIgnoringSafeArea(.all)
                    
                    // the magic bit - our ProgressView just displays an activity
                    // indicator, with some text underneath showing what we are doing
                    VStack{
                        Spacer()
                        Text("Downloading Data").font(.system(size:18))
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
                    
                    .onReceive(timer) { _ in
                        if downloadAmount < 100 {
                            downloadAmount += 2
                            if downloadAmount > 50{
                                ahasDownload = 1
                                tafDownload = 1
                                metarDownload = 1
                                
                            }
                        } else {
                            notamDownload = 2
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                            
                        }
                    }
                    .frame(width: 250, height: 200)
                    .background(Color.white)
                    .foregroundColor(Color.primary)
                    .cornerRadius(16)
                }
            }
        }
    }
}

struct Airports_Previews: PreviewProvider {
    static var previews: some View {
        Airports()
    }
}
