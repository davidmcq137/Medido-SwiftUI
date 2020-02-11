//
//  MedidoMain.swift
//
//
//  Created by David McQueeney on 1/19/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import SwiftUI
import Combine

struct MedidoMain: View {
    
    @State private var sMaxPress: Double = 5.0
    @State private var sMaxSpeed: Double = 0.0
    @EnvironmentObject var tel: Telem
    
    var gsize: CGFloat = 180
    var fsize: CGFloat = 25
    let hF = UIScreen.main.bounds.height / 812 // 812 is iPhone 10 height
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    VStack {
                        Gauge(value: self.tel.flowRate, title: "oz/min", labels: [-60, -40, -20, 0, 20, 40, 60], minValue: -60, maxValue: 60).frame(width:gsize*hF, height:gsize*hF).foregroundColor(.blue)//.border(Color.yellow)
                        Text("Flow Rate").font(.system(size: 15))
                    }//.padding(.top)
                    //Spacer()
                    VStack {
                        Gauge(value: self.tel.pressPSI, title: "psi", labels: [0, 2, 4, 6, 8, 10], minValue: 0.0, maxValue: 10.0).frame(width:gsize*hF, height:gsize*hF).foregroundColor(.yellow)//.border(Color.yellow)
                        Text("Pressure").font(.system(size: 15))
                    }//.padding(.top)
                }//.padding()
                if BLEConnected {
                    Text("BLE").offset(y: -80*hF).foregroundColor(Color.blue).font(.system(size: 18))
                } else {
                    Text("BLE").offset(y: -80*hF).foregroundColor(Color.red).font(.system(size: 18))
                }
            }
            Text("\(selectedPlaneName) (\(selectedPlaneTankCap, specifier: "%0.1f") oz)").font(.system(size: 15))//.foregroundColor(Color.yellow)
                .padding(4)
            Text("Total Fuel Flow \(tele.fuelFlow, specifier: "%.1f") oz").font(.system(size: 20))
            Spacer()
            Slider(value: $sMaxPress, in: 0...10, step: 0.1) { ss in
                //print("slider value change \(self.sMaxPress)")
                writeValue(data: "(Press: \(Int(self.sMaxPress * 10.0)))")
            }
                //.background(Color.secondary)
                .cornerRadius(.infinity)
                .accentColor(Color.blue)
                .frame(width: 300, height: 15)
                .padding()
            Text("Max Pressure \(self.sMaxPress, specifier: "%.1f") PSI").font(.system(size: 15))
            Slider(value: $sMaxSpeed, in: 0...100, step: 0.1) { ss in
                //print("slider value change \(self.sMaxSpeed)")
                writeValue(data: "(Speed: \(Int(self.sMaxSpeed)))")
                //writeValue(data: )
            }
            .cornerRadius(.infinity)
            .accentColor(Color.yellow)
            .frame(width: 300, height: 15)
            .padding()
            Text("Max Pump Speed \(Int(self.sMaxSpeed), specifier: "%d") %").font(.system(size: 15))
            //Spacer()
            HStack {
                Button(action: {
                    // user defaults is persistence model for cal factor, send it each time pumping is commanded
                    // to be sure the correct cal factor is being used
                    let ppoE = Double(UserDefaults.standard.integer(forKey: "ppoEmpty")) / 10.0
                    writeValue(data: String(format: "(CalFactEmpty: %d)", Int(ppoE*10)))
                    writeValue(data: "(Empty)")
                }){
                    Text("Empty")
                        .font(.system(size: fsize))
                        .frame(width: 70)
                        .padding(10)
                        .background(Color.yellow)
                        .cornerRadius(40)
                        .foregroundColor(Color.black)
                        .padding(20)
                        //.border(Color.yellow)
                }
                Spacer()
                Button(action: {
                    writeValue(data: "(Off)")
                }){
                    Text("Off")
                        .font(.system(size: fsize))
                        .frame(width: 70)
                        .padding(10)
                        .background(Color.red)
                        .cornerRadius(40)
                        .foregroundColor(Color.primary)
                        .padding(20)
                        //.border(Color.yellow)
                }
                Spacer()
                Button(action: {
                    // user defaults is persistence model for cal factor, send it each time pumping is commanded
                    // to be sure the correct cal factor is being used
                    autoOff = false
                    let ppoF = Double(UserDefaults.standard.integer(forKey: "ppoFill")) / 10.0
                    writeValue(data: String(format: "(CalFactFill: %d)", Int(ppoF*10)))
                    writeValue(data: "(Fill)")
                }){
                    Text("Fill")
                        .font(.system(size: fsize))
                        .frame(width: 70)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(40)
                        .foregroundColor(Color.primary)
                        .padding(20)
                        //.border(Color.yellow)
                }
            }//.border(Color.blue)
            HStack (alignment: .bottom){
                VStack (alignment: .leading){
                    Text("Flow Rate: \(tele.flowRate, specifier: "%.1f")")
                    //Spacer()
                    Text("Pump Speed: \(Int(tele.pumpSpeed), specifier: "%d") %")
                    //Spacer()
                    Text("Running Time: " + (tele.runningTimeString))
                }.padding()
                Spacer()
                Button(action: {
                    writeValue(data: "(Clear)")
                }){
                    Text("Clear")
                        .frame(width: 70)
                        .font(.system(size: fsize))
                        .padding(10)
                        .background(Color.purple)
                        .cornerRadius(40)
                        .foregroundColor(Color.primary)
                        .padding(20)
                }
            }.padding()
        }.padding()
    }
}


   



