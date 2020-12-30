//
//  Notices.swift
//  Flight Check
//
//  Created by Jaryd Meek on 12/19/20.
//  Copyright © 2020 Jaryd Meek. All rights reserved.
//

import SwiftUI

struct Notices: View {
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
        return "No Active Airport"
    }
    
    struct NOTAM {
        let Title:String?
        let Alert:String?
        let id = UUID()
    }
    
    func downloadNOTAMs(code: String) -> [NOTAM] {
        if let url = URL(string: "https://www.notams.faa.gov/dinsQueryWeb/queryRetrievalMapAction.do?reportType=Report&retrieveLocId=\(code)&actionType=notamRetrievalByICAOs&submit=View+NOTAMs") {
            do {
                let contents = try String(contentsOf: url)
                print(contents)
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
    @State var NOTAMs:[NOTAM] = []
    
    
    var body: some View {
        VStack {
            HStack{
                Text(getActive() + " NOTAMs")
                    .padding(10)
                    .background(Color.accentColor)
                    .foregroundColor(Color("darkLight"))
                    .cornerRadius(10)
                    .font(.largeTitle)
                Button(action: {
                    NOTAMs = downloadNOTAMs(code: getActive())
                }, label: {
                    Image(systemName: "arrow.clockwise")
                        .padding(10)
                        .background(Color.accentColor)
                        .foregroundColor(Color("darkLight"))
                        .cornerRadius(10)
                        .font(.largeTitle)
                })
            }
            ScrollView {
                VStack{
                    ForEach(NOTAMs, id: \.self.id) { notice in
                        Text(notice.Title!).bold() + Text(notice.Alert!)
                        Divider()
                    }
                }.padding(15)
            }
        }.onAppear(perform: {
            NOTAMs = downloadNOTAMs(code: getActive())
        })
    }
}

struct Notices_Previews: PreviewProvider {
    static var previews: some View {
        Notices()
    }
}
