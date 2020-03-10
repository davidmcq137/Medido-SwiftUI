
//
//  MedidoMain.swift
//
//
//  Created by David McQueeney on 1/19/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import SwiftUI
import Combine

struct MedidoMainCombo: View {
    
    @State private var sMaxPress: Double = 0.0
    @State private var sMaxSpeed: Double = 0.0
    
    @EnvironmentObject var tel: Telem
    
    var fsize: CGFloat = 18
    let devmbh = UIScreen.main.bounds.height
    let devmbw = UIScreen.main.bounds.width

    var body: some View {
        VStack {
            if tel.isMetric == false {
                Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.0f") oz)").fontWeight(.semibold).font(.system(size: 20))
            } else {
                Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.0f") ml)").fontWeight(.semibold).font(.system(size: 20))
            }
            ZStack {
                HStack {
                    VStack {
                        if tel.isMetric == false {
                            Gauge(value: self.tel.flowRate, fmtstr: "%.0f", title: "Flow Rate", units: "oz/min", labels: [-45, -30, -15, 0, 15, 30, 45], minValue: -45, maxValue: 45).foregroundColor(.blue)//.border(Color.yellow)
                        } else {
                            Gauge(value: self.tel.flowRate / 1000, fmtstr: "%.1f", title: "Flow Rate", units: "l/min", labels: [-1.0, -0.5, 0, 0.5, 1.0], minValue: -1, maxValue: 1).foregroundColor(.blue)//.border(Color.yellow)
                        }
                    }
                    VStack {
                        if tel.isMetric == false {
                            Gauge(value: self.tel.pressPSI_mB, fmtstr: "%.0f", title: "Pressure", units: "psi", labels: [0, 2, 4, 6, 8, 10], minValue: 0.0, maxValue: 10.0).foregroundColor(.yellow)//.border(Color.yellow)
                        } else {
                            Gauge(value: self.tel.pressPSI_mB/1000.0, fmtstr: "%.1f", title: "Pressure", units: "Bar", labels: [0.0, 0.2, 0.4, 0.6, 0.8], minValue: 0.0, maxValue: 0.8).foregroundColor(.yellow)//.border(Color.yellow)
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
                //Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.0f") oz)").font(.system(size: 20))
                Text("Total Fuel Flow \(tele.fuelFlow, specifier: "%.1f") oz").font(.system(size: 20))
            } else {
                //Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.0f") ml)").font(.system(size: 20))
                Text("Total Fuel Flow \(tele.fuelFlow, specifier: "%.0f") ml").font(.system(size: 20))
            }
            
            if tel.isMetric == false {
                Text("Flow Rate (oz/min) \(tele.flowRate, specifier: "%.1f")")
            } else {
                Text("Flow Rate (ml/min) \(tele.flowRate, specifier: "%.0f")")
            }
            
            Spacer()
            
            if !tel.isMetric {
                chartRecorder(aspect: 2.0 * 812 / devmbh, hgrid: 6, vgrid: 4, //812 is height of 11pro .. scale from there
                              XP: tel.xp, YP: tel.yp, ZP: tel.zp,
                              xrange: 120.0, nlabel: 6,
                              ymin: -10.0, ymax: 10.0, ylabel: "Flow (oz/min) [-10,10] ", yvalue: tel.flowRate, ycolor: Color.blue,
                              zmin: 0.0,   zmax: 2.0,  zlabel: "Press(psi) [0,2] ",   zvalue: tel.pressPSI_mB, zcolor: Color.yellow
                ).padding()
            } else {
                chartRecorder(aspect: 2.0 * 812 / devmbh, hgrid: 6, vgrid: 4,
                              XP: tel.xp, YP: tel.yp, ZP: tel.zp,
                              xrange: 120.0, nlabel: 6,
                              ymin: -500.0, ymax: 500.0, ylabel: "F (ml/min) [-500,500] ", yvalue: tel.flowRate, ycolor: Color.blue,
                              zmin: 0.0,   zmax: 200.0,  zlabel: "P (mB) [0,200] ",   zvalue: tel.pressPSI_mB, zcolor: Color.yellow
                ).padding()
            }
            HStack {
                Button(action: {
                    // user defaults is persistence model for cal factor, send it each time pumping is commanded
                    // to be sure the correct cal factor is being used
                    let ppoE = Double(UserDefaults.standard.integer(forKey: "ppoEmpty")) / 10.0
                    if tele.isSPIpump == false {
                        writeValue(data: String(format: "(CalE: %d)", Int(ppoE*10)))
                        writeValue(data: String(format: "(pMAX: %d)", tele.maxPWM))
                    }
                    writeValue(data: "(Empty)")
                    clearChartRecData()
                }){
                    Text("Empty")
                        .font(.system(size: fsize))
                        .frame(width: 60)
                        .padding(5)
                        .background(Color.yellow)
                        .cornerRadius(30)
                        .foregroundColor(Color.black)
                        .padding(2)
                        //.border(Color.yellow)
                }
                Spacer()
                Button(action: {
                    writeValue(data: "(Off)")
                }){
                    Text("Off")
                        .font(.system(size: fsize))
                        .frame(width: 60)
                        .padding(5)
                        .background(Color.red)
                        .cornerRadius(30)
                        .foregroundColor(Color.primary)
                        .padding(2)
                        //.border(Color.yellow)
                }
                Spacer()
                Button(action: {
                    // user defaults is persistence model for cal factor, send it each time pumping is commanded
                    // to be sure the correct cal factor is being used
                    autoOff = false
                    let ppoF = Double(UserDefaults.standard.integer(forKey: "ppoFill")) / 10.0
                    if tele.isSPIpump == false {
                        writeValue(data: String(format: "(CalF: %d)", Int(ppoF*10)))
                        writeValue(data: String(format: "(pMAX: %d)", tele.maxPWM))
                    }
                    writeValue(data: "(Fill)")
                    clearChartRecData()
                }){
                    Text("Fill")
                        .font(.system(size: fsize))
                        .frame(width: 60)
                        .padding(5)
                        .background(Color.blue)
                        .cornerRadius(30)
                        .foregroundColor(Color.primary)
                        .padding(2)
                        //.border(Color.yellow)
                }
            }.padding(.horizontal)

           

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
                    writeValue(data: "(Clear)")
                    clearChartRecData()
                    // TESTING!!!
                    //setInfoMessage(msg: "This is a test .. CLEAR!")
                }){
                    Text("Clear")
                        .frame(width: 60)
                        .font(.system(size: fsize))
                        .padding(5)
                        .background(Color.purple)
                        .cornerRadius(30)
                        .foregroundColor(Color.primary)
                        .padding()
                        //.border(Color.red)
                }
            }.padding(.horizontal)
            Text(tele.msgStr).foregroundColor(.blue).font(.system(size: 15))
        }//.padding()
    }
}


   



