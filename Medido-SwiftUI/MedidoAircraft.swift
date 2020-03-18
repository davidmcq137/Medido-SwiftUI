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
    @State private var editcurrent = false
    @State private var acname: String = ""
    @State private var tankcapy: String = ""
    @State private var pumpspeed: String = ""
    @State private var maxpressure: String = ""
    @State private var showingAlert = false
    @State private var selectedID: String? = UserDefaults.standard.string(forKey: "selUUID")
    @EnvironmentObject var tele: Telem
    
    //let uuid = UUID().uuidString
    //var uuid = UUID(uuidString: yourString)
    
    let fsize: CGFloat = 25
    
    var body: some View {
        VStack{
            if submenu == true {
                
                VStack (spacing: 5){
                    TextField("Name", text: self.$acname).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 300, height: 30)
                    Text("Aircraft Name")
                }.padding()
                
                VStack (spacing: 5) {
                    if tele.isMetric == false {
                        TextField("Capacity (oz)", text: self.$tankcapy).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 300, height: 30)
                        Text("Fuel Tank Capcity (oz)")
                    } else {
                        TextField("Capacity (ml)", text: self.$tankcapy).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 300, height: 30)
                        Text("Fuel Tank Capcity (ml)")
                        
                    }

                }.padding()
                
                VStack (spacing: 5) {
                    TextField("Speed (0-100)%", text: self.$pumpspeed).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 300, height: 30)
                    Text("Fuel Pump Speed")
                }.padding()
                
                VStack (spacing: 5) {
                    if tele.isMetric == false {
                        TextField("Pressure (psi)", text: self.$maxpressure).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 300, height: 30)
                        Text("Regulated Delivery Pressure (psi)")
                    } else {
                        TextField("Pressure (mBar)", text: self.$maxpressure).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 300, height: 30)
                        Text("Regulated Delivery Pressure (mbar)")
                    }
                }.padding()
                
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
                        
                        if self.editcurrent == false {
                            if self.pumpspeed == "" {
                                print("setting pumpspeed default")
                                self.pumpspeed = "100.0"
                            }
                            if self.maxpressure == "" {
                                print("setting maxpressure default")
                                if self.tele.isMetric == false {
                                    self.maxpressure = "5.0"
                                } else {
                                    self.maxpressure = "400"
                                }
                            }
                        } else {
                            print("editcurrent")
                        }
                            
                        print("before big if let")
                        print("self.tankcapy: \(self.tankcapy)")
                        print("self.pumpspeed: \(self.pumpspeed)")
                        print("self.maxpressure: \(self.maxpressure)")

                        if let tsd = Double(self.tankcapy), let ssd = Double(self.pumpspeed), let psd = Double(self.maxpressure) {
                            print("tsd, ssd, psd: \(tsd), \(ssd), \(psd)")
                            if self.showingAlert == false {
                                let plane = Aircraft(context: self.moc)
                                if self.editcurrent == false {
                                    plane.id = UUID()
                                } else {
                                    for pl in self.planes { // delete the old one, we'll create a new one with the old values as defaults
                                        if pl.id == self.tele.selectedPlaneID {
                                            print("deleteing plane pl")
                                            self.moc.delete(pl) // will save shortly... a few lines down
                                        }
                                    }
                                    plane.id = UUID() // use a new UUID ... could have reused the deleted one .. hmm...
                                }
                                if self.acname == "" {
                                    plane.name = "Unknown"
                                } else {
                                    plane.name = self.acname
                                }
                                plane.tanksize = tsd
                                if ssd > 100 {
                                    plane.maxspeed = 100.0
                                } else if ssd < 0 {
                                    plane.maxspeed = 0.0
                                } else {
                                    plane.maxspeed = ssd
                                }
                                plane.maxpressure = psd
                                plane.maxpUnits = self.tele.isMetric ? "mbar" : "psi"
                                plane.tanksUnits = self.tele.isMetric ? "ml" : "oz"
                                do {
                                    print("self.tankcapy \(self.tankcapy), tsd \(tsd)")
                                    print("self.acname \(self.acname)")
                                    print("plane.acname: \(plane.name ?? "foo")")
                                    print("plane.tanksize: \(plane.tanksize)")
                                    print("plane tank units: \(plane.tanksUnits ?? "unk")")
                                    print("plane.maxspeed: \(plane.maxspeed)")
                                    print("plane.maxpressure: \(plane.maxpressure)")
                                    print("plane.maxpUnits: \(plane.maxpUnits ?? "unk")")
                                    print("about to moc.save")
                                    
                                    try self.moc.save()
                                    
                                    print("after try self.moc.save")
                                    self.tele.selectedPlaneName = plane.name ?? "unk"
                                    self.tele.selectedPlaneTankCap = plane.tanksize
                                    self.tele.selectedPlaneTankUnits = plane.tanksUnits ?? "unk"
                                    self.tele.selectedPlaneMaxSpeed = plane.maxspeed
                                    self.tele.selectedPlaneMaxPressure = plane.maxpressure
                                    self.tele.selectedPlaneMaxPressureUnits = plane.maxpUnits ?? "unk"
                                    self.tele.selectedPlaneID = plane.id

                                    self.tele.sliderSpeed = Int(plane.maxspeed)

                                    if self.tele.selectedPlaneMaxPressureUnits == "psi" {
                                        self.tele.sliderPressure = Int(10 * plane.maxpressure)
                                    } else if self.tele.selectedPlaneMaxPressureUnits == "mbar" {
                                        self.tele.sliderPressure = Int(10 * plane.maxpressure / 68.9476)
                                    } else {
                                        self.tele.sliderPressure = 0
                                    }
                                    if plane.id == nil {
                                        print("plane.id is nil")
                                    } else {
                                        print("plane.id = \(plane.id!)")
                                        self.selectedID = (plane.id!).uuidString
                                    }
                                    self.editcurrent = false
                                    self.tankcapy = ""
                                    self.acname = ""
                                    self.pumpspeed = ""
                                    self.maxpressure = ""
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
                        Text("Save plane data")
                    }
                    .alert(isPresented: self.$showingAlert) {
                        Alert(title: Text("Conversion Error"),
                              message: Text("Invalid number"),
                              dismissButton: .default(Text("OK")))
                    }
                    .padding()
                    .background(Color.secondary)
                    .cornerRadius(CGFloat(40))
                    .foregroundColor(Color.primary)
                    .padding()
                }
                Spacer()
                
            } else { // Main view to be shown if here
                Text("Stored Aircraft").font(.system(size: fsize))
                List {
                    HStack {
                        Text("Name").offset(x:50)
                        Spacer()
                        Text("Tank Size")
                        //if !tele.isMetric {
                        //    Text("Tank Size (oz)")
                        //} else {
                        //    Text("Tank Size (ml)")
                        //}
                    }
                    ForEach(planes, id: \.id) { plane in
                        HStack {
                            Button (action: {
                                //print("select!")
                                self.tele.selectedPlaneName = plane.name ?? "unk"
                                self.tele.selectedPlaneTankCap = plane.tanksize
                                self.tele.selectedPlaneMaxSpeed = plane.maxspeed
                                self.tele.selectedPlaneMaxPressure = plane.maxpressure
                                self.tele.selectedPlaneMaxPressureUnits = plane.maxpUnits ?? "unk"
                                self.tele.selectedPlaneTankUnits = plane.tanksUnits ?? "unk"
                                self.tele.sliderSpeed = Int(plane.maxspeed)
                                if self.tele.selectedPlaneMaxPressureUnits == "psi" { // tele.sliderPressure is Int of pressure * 10
                                    self.tele.sliderPressure = Int(10 * plane.maxpressure)
                                } else {
                                    self.tele.sliderPressure = Int(10 * plane.maxpressure / 68.9476) // convert mbar to psi
                                }
                                print("Selected: \(self.tele.selectedPlaneName)")
                                print("sliderSpeed: \(self.tele.sliderSpeed)")
                                print("sliderPressure: \(self.tele.sliderPressure)")
                                
                                if plane.id != nil {
                                    self.tele.selectedPlaneID = plane.id!
                                    self.selectedID = (plane.id!).uuidString
                                    print("setting user defaults: \(self.tele.selectedPlaneName)")
                                    UserDefaults.standard.set(self.selectedID, forKey: "selUUID")
                                    UserDefaults.standard.set(self.tele.selectedPlaneTankCap, forKey: "selTankCap")
                                    UserDefaults.standard.set(self.tele.selectedPlaneName, forKey: "selName")
                                    UserDefaults.standard.set(self.tele.selectedPlaneMaxSpeed, forKey: "selSpeed")
                                    UserDefaults.standard.set(self.tele.selectedPlaneMaxPressure, forKey: "selPressure")
                                    UserDefaults.standard.set(self.tele.selectedPlaneMaxPressureUnits, forKey: "selPressureUnits")
                                    UserDefaults.standard.set(self.tele.selectedPlaneTankUnits, forKey: "selTankUnits")
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
                            Text("\(plane.tanksUnits ?? "unk")").font(.system(size: 18))
                        }
                    }.onDelete(perform: removeFields)
                }
                HStack{
                    Button(action: {
                        self.submenu = true
                        self.editcurrent = false
                        self.acname = ""
                        self.tankcapy = ""
                        self.pumpspeed = ""
                        self.maxpressure = ""
                    }) {
                        Text("New plane")
                    }
                    .padding()
                    .background(Color.secondary)
                    .cornerRadius(CGFloat(40))
                    .foregroundColor(Color.primary)
                    .padding()
                    
                    Button(action: {
                        self.submenu = true
                        self.editcurrent = true
                        self.acname = self.tele.selectedPlaneName
                        self.tankcapy = "\(self.convertCapy(cap: self.tele.selectedPlaneTankCap, units: self.tele.selectedPlaneTankUnits, isM: self.tele.isMetric))"
                        self.pumpspeed = "\(self.tele.selectedPlaneMaxSpeed)"
                        self.maxpressure = "\(self.convertPress(press: self.tele.selectedPlaneMaxPressure, units: self.tele.selectedPlaneMaxPressureUnits, isM: self.tele.isMetric))"
                        print("edit current plane")
                    }) {
                        Text("Edit Current")
                    }
                    .padding()
                    .background(Color.secondary)
                    .cornerRadius(CGFloat(40))
                    .foregroundColor(Color.primary)
                    .padding()
                }
            }
        }
    }
    
    func convertCapy(cap: Double, units: String, isM: Bool ) -> String {
        let oz2ml = 29.5735
        if isM == true {
            if units == "ml" {
                return String(format: "%.2f", cap)
            } else {
                return String(format: "%.2f", cap * oz2ml)
            }
        } else {
            if units == "oz" {
                return String(format: "%.2f", cap)
            } else {
                return String(format: "%.2f", cap / oz2ml)
            }
        }
    }
    
    func convertPress(press: Double, units: String, isM: Bool ) -> String {
        let psi2mbar = 68.9476
        if isM == true {
            if units == "mbar" {
                return String(format: "%.2f", press)
            } else {
                return String(format: "%.2f", press * psi2mbar)
            }
        } else {
            if units == "psi" {
                return String(format: "%.2f", press)
            } else {
                return String(format: "%.2f", press / psi2mbar)
            }
        }
    }
    
    func nextTank()-> Double {
        nlat = nlat + 10
        return nlat
    }
    
    func removeFields(at offsets: IndexSet) {
        for index in offsets {
            print("in removeFields: index: \(index)")
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


