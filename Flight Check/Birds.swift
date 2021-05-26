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
    
    var body: some View {
        VStack {
            HStack{
                Text(getActive() + " Avian Risk")
                    .padding(10)
                    .background(Color.accentColor)
                    .foregroundColor(Color("darkLight"))
                    .cornerRadius(10)
                    .font(.largeTitle)
            }
            if AHASData.getBirdData(code: getActive()).count != 0 {
                ScrollView {
                    VStack{
                        ForEach (AHASData.getBirdData(code: getActive()), id: \.self.id) { data in
                            HStack{
                                Spacer()
                                VStack {
                                    Text(data.DateTime).bold()
                                        .font(.title2)
                                    Text("Segment - ").bold()
                                    Text(data.Segment)
                                    Text("Risk Evalutation Based On - ").bold()
                                    Text(data.BasedON)
                                    HStack {
                                        Text("Height - ").bold()
                                    if data.TIDepth == String(99999) {
                                        Text("No Data")
                                    } else {
                                        Text(data.TIDepth)
                                    }
                                    }
                                }.multilineTextAlignment(.center)
                                Spacer()
                                if data.AHASRISK.uppercased() == "LOW" {
                                    Text(data.AHASRISK.uppercased())
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(Color("darkLight"))
                                        .frame(width: 125)
                                } else if data.AHASRISK.uppercased() == "MODERATE" {
                                    Text(data.AHASRISK.uppercased())
                                        .padding()
                                        .background(Color.yellow)
                                        .foregroundColor(Color("darkLight"))
                                        .frame(width: 125)
                                }else if data.AHASRISK.uppercased() == "SEVERE" {
                                    Text(data.AHASRISK.uppercased())
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(Color("darkLight"))
                                        .frame(width: 125)
                                }
                                Spacer().frame(width:5)
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
