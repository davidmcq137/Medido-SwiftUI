//
//  MedidoAircraft.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 2/8/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData

var nlat: Double = 200

struct MedidoAircraft: View {
    
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(
        entity: Aircraft.entity(),
        sortDescriptors: []
    ) var planes: FetchedResults<Aircraft>
    
    @State private var submenu =  false
    @State private var acname: String = ""
    @State private var tankcapy: String = ""
    @State private var showingAlert = false
    @State private var selectedID: String? = UserDefaults.standard.string(forKey: "selUUID")
    @EnvironmentObject var tele: Telem
    
    //let uuid = UUID().uuidString
    //var uuid = UUID(uuidString: yourString)
    
    let fsize: CGFloat = 25
    
    var body: some View {
        VStack{
            if self.submenu == true {
                TextField("Aircraft Name", text: self.$acname).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 300, height: 30)
                    .padding()
                TextField("Capacity (oz)", text: self.$tankcapy).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 300, height: 30)
                    .padding()
                HStack{
                    Button(action: {
                        self.submenu = false
                    }) {
                        Text("Cancel")
                    }
                    .padding()
                    .background(Color.secondary)
                    .cornerRadius(CGFloat(40))
                    .foregroundColor(Color.primary)
                    .padding()

                    Button(action: {
                        if let tsd = Double(self.tankcapy) {
                            if self.showingAlert == false {
                                let plane = Aircraft(context: self.moc)
                                plane.id = UUID()
                                if self.acname == "" {
                                    plane.name = "Unknown"
                                } else {
                                    plane.name = self.acname
                                }
                                //plane.id = UUID()
                                plane.tanksize = tsd
                                do {
                                    print("self.tankcapy \(self.tankcapy), tsd \(tsd)")
                                    print("self.acname \(self.acname)")
                                    print("about to moc.save")
                                    try self.moc.save()
                                    print("after try self.moc.save")
                                    self.tele.selectedPlaneName = self.acname
                                    self.tele.selectedPlaneTankCap = tsd
                                    self.tankcapy = ""
                                    self.acname = ""
                                    self.submenu = false
                                } catch {
                                    print("core data error")
                                }
                            }
                        } else {
                            print("Conversion error")
                            self.showingAlert = true
                        }
                    }) {
                        Text("Add this new plane")
                    }
                    .alert(isPresented: self.$showingAlert) {
                        Alert(title: Text("Conversion Error"),
                              message: Text("Tank size must be a number"),
                              dismissButton: .default(Text("OK")))
                    }
                    .padding()
                    .background(Color.secondary)
                    .cornerRadius(CGFloat(40))
                    .foregroundColor(Color.primary)
                    .padding()
                }
                Spacer()
            } else {
                Text("Aircraft").font(.system(size: fsize))
                List {
                    HStack {
                        Text("Name").offset(x:50)
                        Spacer()
                        if !tele.isMetric {
                            Text("Tank Size (oz)")
                        } else {
                            Text("Tank Size (ml)")
                        }
                    }
                    ForEach(planes, id: \.id) { plane in
                        HStack {
                            Button (action: {
                                //print("select!")
                                self.tele.selectedPlaneName = plane.name ?? "unk"
                                self.tele.selectedPlaneTankCap = plane.tanksize
                                if plane.id != nil {
                                    self.tele.selectedPlaneID = plane.id!
                                    self.selectedID = (plane.id!).uuidString
                                    UserDefaults.standard.set(self.selectedID, forKey: "selUUID")
                                    UserDefaults.standard.set(self.tele.selectedPlaneTankCap, forKey: "selTankCap")
                                    UserDefaults.standard.set(self.tele.selectedPlaneName, forKey: "selName")
                                }
                               // print("selectedID: \(String(describing: plane.id))")
                            }) {
                                Text("Select").font(.system(size: 12))
                            }
                            .padding(5)
                            .background(Color.secondary)
                            .cornerRadius(CGFloat(40))
                            .foregroundColor(Color.primary)
                            Text(plane.name ?? "unk").font(.system(size: 18))
                            if plane.id != nil && self.selectedID != nil {
                                if (plane.id!).uuidString == self.selectedID! {
                                    Image(systemName: "airplane")
                                }
                            }
                            Spacer()
                            Text("\(plane.tanksize, specifier: "%0.1f")").font(.system(size: 18))
                        }
                    }.onDelete(perform: removeFields)
                }
                Button(action: {
                    self.submenu = true
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
    
    
    func nextTank()-> Double {
        nlat = nlat + 10
        return nlat
    }
    
    func removeFields(at offsets: IndexSet) {
        for index in offsets {
            let plane = planes[index]
            moc.delete(plane)
        }
        do {
            try self.moc.save()
        } catch {
            // handle the Core Data error
        }
    }
}


