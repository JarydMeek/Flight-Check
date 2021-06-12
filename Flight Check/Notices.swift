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
    var body: some View {
        VStack {
            HStack{
                Text(getActive() + " NOTAMs")
                    .padding(10)
                    .background(Color.accentColor)
                    .foregroundColor(Color("darkLight"))
                    .cornerRadius(10)
                    .font(.largeTitle)
            }
            if NOTAMData.getNOTAMS(code: getActive()).count >= 1 {
                ScrollView {
                    VStack{
                        ForEach(NOTAMData.getNOTAMS(code: getActive()), id: \.self.id) { notice in
                            HStack{
                                VStack(alignment: .leading){
                                    HStack{
                                        Text(notice.Title!).bold().font(.title2) + Text(notice.Alert!)
                                    }
                                    Spacer().frame(height:10)
                                    Text(notice.Until!).bold()
                                    Spacer().frame(height:10)
                                    Text(notice.Created!).italic()
                                    Spacer().frame(height:10)
                                }
                                Spacer()
                            }
                            Divider()
                        }
                    }.padding(15)
                }
            }else {
                Spacer()
                Text("NOTAMs could not be loaded for selected airport")
                Spacer()
            }
        }
    }
}

struct Notices_Previews: PreviewProvider {
    static var previews: some View {
        Notices()
    }
}
