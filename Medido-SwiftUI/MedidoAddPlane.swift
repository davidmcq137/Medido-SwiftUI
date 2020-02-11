//
//  MedidoAddPlane.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 2/8/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import SwiftUI


struct MedidoAddPlane: View {
    
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(
        entity: Aircraft.entity(),
        sortDescriptors: []
    ) var planes: FetchedResults<Aircraft>
    
    @State private var acname: String = ""
    @State private var tankcapy: String = ""

    
    var body: some View {
        
        VStack {
            TextField("Aircraft Name", text: self.$acname).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 200, height: 20)
            TextField("Capacity (oz)", text: self.$tankcapy).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 200, height: 20)
            
            Button(action: {
                let plane = Aircraft(context: self.moc)
                plane.id = UUID()
                if self.acname == "" {
                    plane.name = "Unknown"
                } else {
                    plane.name = self.acname
                }
                if let tsd = Double(self.tankcapy) {
                    let plane = Aircraft(context: self.moc)
                    plane.id = UUID()
                    plane.tanksize = tsd
                    do {
                        try self.moc.save()
                    } catch {
                        // handle the Core Data error
                    }
                }
            }) {
                Text("Add a new plane")
            }
            .padding()
            .background(Color.secondary)
            .cornerRadius(CGFloat(40))
            .foregroundColor(Color.primary)
            .padding()
        }
    }
}

