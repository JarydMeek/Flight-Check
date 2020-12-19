//
//  Weather.swift
//  Flight Check
//
//  Created by Jaryd Meek on 12/19/20.
//  Copyright © 2020 Jaryd Meek. All rights reserved.
//

import SwiftUI

struct Weather: View {
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

struct Weather_Previews: PreviewProvider {
    static var previews: some View {
        Weather()
    }
}
