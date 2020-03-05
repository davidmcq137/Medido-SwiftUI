//
//  MedidoMainChart.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 2/22/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//


import SwiftUI
import Combine

struct MedidoMainChart: View {
    
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
            if !tel.isMetric {
                chartRecorder(aspect: 2, hgrid: 6, vgrid: 4,
                              XP: tel.xp, YP: tel.yp, ZP: tel.zp,
                              xrange: 120.0, nlabel: 6,
                              ymin: -10.0, ymax: 10.0, ylabel: "Flow (oz/min) [-10,10]: ", yvalue: tel.flowRate, ycolor: Color.blue,
                              zmin: 0.0,   zmax: 2.0,  zlabel: "Press(psi) [0,2]: ",   zvalue: tel.pressPSI_mB, zcolor: Color.yellow
                )
            } else {
                chartRecorder(aspect: 2, hgrid: 6, vgrid: 4,
                              XP: tel.xp, YP: tel.yp, ZP: tel.zp,
                              xrange: 120.0, nlabel: 6,
                              ymin: -500.0, ymax: 500.0, ylabel: "F (ml/min) [-500,500]: ", yvalue: tel.flowRate, ycolor: Color.blue,
                              zmin: 0.0,   zmax: 200.0,  zlabel: "P (mB) [0,200]: ",   zvalue: tel.pressPSI_mB, zcolor: Color.yellow
                )
            }
            if tel.isMetric == false {
                Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.1f") oz)").font(.system(size: 20))
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
                    writeValue(data: "(Prs: \(self.tel.sliderPressure))")
                }
                .frame(width: sW, height: sH)
                .padding(5)
                .accentColor(Color.yellow)
                //.border(Color.red)
                Text("Max Pressure \(self.sMaxPress, specifier: "%.1f") PSI").font(.system(size: 15))
            } else {
                Slider(value: $sMaxPress, in: 0...1000, step: 10.0) { ss in
                    self.tel.sliderPressure = Int(self.sMaxPress * (14.5 / 1000) * 10) // sent units of psi * 10
                    if self.tel.sliderPressure > 145 { // just in case...
                        self.tel.sliderPressure = 145  // value sent as 10x in an Int
                    }
                    writeValue(data: "(Prs: \(self.tel.sliderPressure))")
                }
                .frame(width: sW, height: sH)
                .padding(5)
                .accentColor(Color.yellow)
                //.border(Color.red)
                Text("Max Pressure \(self.sMaxPress, specifier: "%.0f") mBar").font(.system(size: 15))
            }
            
            Slider(value: $sMaxSpeed, in: 0...100, step: 0.1) { ss in
                self.tel.sliderSpeed = Int(self.sMaxSpeed)
                writeValue(data: "(Spd: \(self.tel.sliderSpeed))")
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
                    clearChartRecData()
                    if tele.isSPIpump == false {
                        writeValue(data: String(format: "(CalE: %d)", Int(ppoE*10)))
                        writeValue(data: String(format: "(pMAX: %d)", tele.maxPWM))
                    }
                    writeValue(data: "(Empty)")
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
                    clearChartRecData()
                    if tele.isSPIpump == false {
                        writeValue(data: String(format: "(CalF: %d)", Int(ppoF*10)))
                        writeValue(data: String(format: "(pMAX: %d)", tele.maxPWM))
                    }
                    writeValue(data: "(Fill)")
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

            if !tele.isMetric {
                Text("Flow Rate (oz/min): \(tele.flowRate, specifier: "%.1f")")
            } else {
                Text("Flow Rate (ml/min): \(tele.flowRate, specifier: "%.0f")")
            }

            HStack () {
                VStack (alignment: .leading){
                    //Spacer()
                    Text("Pump Speed: \(Int(tele.pumpSpeed), specifier: "%d") %")
                    //Spacer()
                    Text("Running Time: " + (tele.runningTimeString))
                    Text("Pump battery: \(tele.battVolt, specifier: "%.2f") V")

                }.padding()//.border(Color.purple)
                Spacer()
                Button(action: {
                    clearChartRecData()
                    writeValue(data: "(Clear)")
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


   



