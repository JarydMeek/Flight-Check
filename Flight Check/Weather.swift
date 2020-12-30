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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        currentTAF = TAFData.getSpecificTAF(code: getActive())
        }
        var newString = ""
        //FM
        for x in 0..<(currentTAF.count)-1 {
            if currentTAF[x] == "F" && currentTAF[x+1] == "M" {
                newString += "\n\t"
                newString += currentTAF[x]
            }else {
                newString += currentTAF[x]
                }
        }
        let temp = newString
        newString = ""
        for x in 0..<(temp.count)-4 {
            if temp[x] == "T" && temp[x+1] == "E" && temp[x+2] == "M" && temp[x+3] == "P" && temp[x+4] == "O" {
                newString += "\n\t"
                newString += temp[x]
            }else {
                newString += temp[x]
                }
        }
        let temp2 = newString
        newString = ""
        for x in 0..<(temp2.count)-4 {
            if temp2[x] == "S" && temp2[x+1] == "P" && temp2[x+2] == "E" && temp2[x+3] == "C" && temp2[x+4] == "I" {
                newString += "\n\t"
                newString += temp[x]
            }else {
                newString += temp[x]
                }
        }
        let temp3 = newString
        newString = ""
        for x in 0..<(temp.count)-4 {
            if temp3[x] == "B" && temp3[x+1] == "E" && temp3[x+2] == "C" && temp3[x+3] == "M" && temp3[x+4] == "G" {
                newString += "\n\t"
                newString += temp[x]
            }else {
                newString += temp[x]
                }
        }
        return newString
    }
    
    var body: some View {
        VStack{
        
            HStack{
                HStack{
                    Text(getActive())
                    if (getActive().count == 4) {
                        Text(" Weather")
                    }

                }
                .padding(10)
                .background(Color.accentColor)
                .foregroundColor(Color("darkLight"))
                .cornerRadius(10)
                .font(.largeTitle)
                
                
                Button(action: {
                    loadData()
                }, label: {
                    Image(systemName: "arrow.clockwise")
                        .padding(10)
                        .background(Color.accentColor)
                        .foregroundColor(Color("darkLight"))
                        .cornerRadius(10)
                        .font(.largeTitle)
                })
            }
            ScrollView{
                Text("METARs - ")
                    .padding(5)
                    .background(Color("lightDark").opacity(0.75))
                    .foregroundColor(Color("darkLight"))
                    .font(.title)
                    .cornerRadius(10)
                Text(getCurrentMETAR()).frame(height: 150)
                    .padding(15)
                Text("TAFs - ")
                    .padding(5)
                    .background(Color("lightDark").opacity(0.75))
                    .foregroundColor(Color("darkLight"))
                    .font(.title)
                    .cornerRadius(10)
                Text(getCurrentTAF())
                    .padding(15)
                Spacer()
            }.onAppear {
                loadData()
            }
        }
    }
}

struct Weather_Previews: PreviewProvider {
    static var previews: some View {
        Weather()
    }
}
