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
    
    @State private var sMaxPress: Double = 0.0
    @State private var sMaxSpeed: Double = 0.0
    
    @EnvironmentObject var tel: Telem
    
    var gsize: CGFloat = 180
    var fsize: CGFloat = 25
    let hF = UIScreen.main.bounds.height / 812 // 812 is iPhone 10 height
    let sW = 320*UIScreen.main.bounds.width / 375 // 375 is iPhone 10 width
    let sH = 20*UIScreen.main.bounds.height / 812
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    VStack {
                        if tel.isMetric == false {
                            Gauge(value: self.tel.flowRate, fmtstr: "%.0f", title: "Flow Rate", units: "oz/min", labels: [-60, -40, -20, 0, 20, 40, 60], minValue: -60, maxValue: 60).foregroundColor(.blue)//.border(Color.yellow)
                        } else {
                            Gauge(value: self.tel.flowRate*1000, fmtstr: "%.0f", title: "Flow Rate", units: "l/min", labels: [-2, -1, 0, 1, 2], minValue: -2, maxValue: 2).foregroundColor(.blue)//.border(Color.yellow)
                        }
                    }
                    VStack {
                        if tel.isMetric == false {
                            Gauge(value: self.tel.pressPSI, fmtstr: "%.0f", title: "Pressure", units: "psi", labels: [0, 2, 4, 6, 8, 10], minValue: 0.0, maxValue: 10.0).foregroundColor(.yellow)//.border(Color.yellow)
                        } else {
                            Gauge(value: self.tel.pressPSI*1000, fmtstr: "%.1f", title: "Pressure", units: "Bar", labels: [0.0, 0.2, 0.4, 0.6, 0.8], minValue: 0.0, maxValue: 0.8).foregroundColor(.yellow)//.border(Color.yellow)
                        }
                    }
                }
                if tel.BLEConnected {
                    Text("BLE").offset(y: -70).foregroundColor(Color.blue).font(.system(size: 18))
                } else {
                    Text("BLE").offset(y: -70).foregroundColor(Color.red).font(.system(size: 18))
                }
            }
            if tel.isMetric == false {
                Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.0f") oz)").font(.system(size: 20))
                    .padding(5)
                Text("Total Fuel Flow \(tele.fuelFlow, specifier: "%.1f") oz").font(.system(size: 25))
                    .padding(5)
            } else {
                Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.0f") ml)").font(.system(size: 20))
                    .padding(5)
                Text("Total Fuel Flow \(tele.fuelFlow, specifier: "%.0f") ml").font(.system(size: 25))
                    .padding(5)
            }
            
            if tel.isMetric == false {
                Slider(value: $sMaxPress, in: 0...10, step: 0.1) { ss in
                    self.tel.sliderPressure = Int(self.sMaxPress * 10)
                    writeValue(data: "(Prs: \(self.tel.sliderPressure)")
                }
                .frame(width: sW, height: sH)
                .padding(5)
                .accentColor(Color.yellow)
                //.border(Color.red)
                Text("Max Pressure \(self.sMaxPress, specifier: "%.1f") PSI").font(.system(size: 15))
            } else {
                Slider(value: $sMaxPress, in: 0...1000, step: 10.0) { ss in
                    self.tel.sliderPressure = Int(self.sMaxPress * 14.5 / 1000 * 10)
                    if self.tel.sliderPressure > 15 { // just in case...
                        self.tel.sliderPressure = 15
                    }
                    writeValue(data: "(Prs: \(self.tel.sliderPressure)")
                }
                .frame(width: sW, height: sH)
                .padding(5)
                .accentColor(Color.yellow)
                //.border(Color.red)
                Text("Max Pressure \(self.sMaxPress, specifier: "%.0f") mBar").font(.system(size: 15))
            }
            
            Slider(value: $sMaxSpeed, in: 0...100, step: 0.1) { ss in
                self.tel.sliderSpeed = Int(self.sMaxSpeed)
                writeValue(data: "(Spd: \(self.tel.sliderSpeed)")
            }
            .frame(width: sW, height: sH)
            .padding(5)
            .accentColor(Color.blue)
            //.border(Color.red)
            Text("Max Pump Speed \(Int(self.sMaxSpeed), specifier: "%d") %").font(.system(size: 15))
            HStack {
                Button(action: {
                    // user defaults is persistence model for cal factor, send it each time pumping is commanded
                    // to be sure the correct cal factor is being used
                    let ppoE = Double(UserDefaults.standard.integer(forKey: "ppoEmpty")) / 10.0
                    writeValue(data: String(format: "(CalE: %d)", Int(ppoE*10)))
                    writeValue(data: "(Empty)")
                    clearChartRecData()
                }){
                    Text("Empty")
                        .font(.system(size: fsize))
                        .frame(width: 70)
                        .padding(10)
                        .background(Color.yellow)
                        .cornerRadius(40)
                        .foregroundColor(Color.black)
                        .padding(10)
                        //.border(Color.yellow)
                }
                //Spacer()
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
                        .padding(10)
                        //.border(Color.yellow)
                }
                Button(action: {
                    // user defaults is persistence model for cal factor, send it each time pumping is commanded
                    // to be sure the correct cal factor is being used
                    autoOff = false
                    let ppoF = Double(UserDefaults.standard.integer(forKey: "ppoFill")) / 10.0
                    writeValue(data: String(format: "(CalF: %d)", Int(ppoF*10)))
                    writeValue(data: "(Fill)")
                    clearChartRecData()
                }){
                    Text("Fill")
                        .font(.system(size: fsize))
                        .frame(width: 70)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(40)
                        .foregroundColor(Color.primary)
                        .padding(10)
                        //.border(Color.yellow)
                }
            }.padding()
            HStack (alignment: .bottom){
                VStack (alignment: .leading){
                    if tel.isMetric == false {
                        Text("Flow Rate (oz/min): \(tele.flowRate, specifier: "%.1f")")
                    } else {
                        Text("Flow Rate (ml/min): \(tele.flowRate, specifier: "%.0f")")
                    }
                    //Spacer()
                    Text("Pump Speed: \(Int(tele.pumpSpeed), specifier: "%d") %")
                    //Spacer()
                    Text("Running Time: " + (tele.runningTimeString))
                    Text("Pump battery: \(tele.battVolt, specifier: "%.2f") V")

                }.padding()//.border(Color.purple)
                Spacer()
                Button(action: {
                    writeValue(data: "(Clear)")
                    clearChartRecData()
                    // TESTING!!!
                    setInfoMessage(msg: "This is a test .. CLEAR!")
                }){
                    Text("Clear")
                        .frame(width: 70)
                        .font(.system(size: fsize))
                        .padding(10)
                        .background(Color.purple)
                        .cornerRadius(40)
                        .foregroundColor(Color.primary)
                        .padding(10)
                        //.border(Color.red)
                }
            }//.padding()
            Text(tele.msgStr).foregroundColor(.blue).font(.system(size: 15))
        }//.padding()
    }
}


   



