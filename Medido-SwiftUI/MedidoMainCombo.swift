
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
    
    let devmbh = UIScreen.main.bounds.height
    let devmbw = UIScreen.main.bounds.width
    
    @State private var sMaxPress: Double = 0.0
    @State private var sMaxSpeed: Double = 0.0
    
    @EnvironmentObject var tel: Telem
    
    var fsize: CGFloat = 22
    
    @State private var fRIoz: Int = 0
    let flowRangeStringsOz: [String] = ["[-64,64]", "[-32,32]", "[-16,16]", "[-8,8]"]
    let flowRangeMinOz: [Double] = [-64, -32, -16, -8]
    let flowRangeMaxOz: [Double] = [64, 32, 16, 8]
    
    @State private var fRIml: Int = 0
    let flowRangeStringsml: [String] = ["[-1600,1600]", "[-800,800]", "[-400,400]"]
    let flowRangeMinml: [Double] = [-1600, -800, -400]
    let flowRangeMaxml: [Double] = [1600, 800, 400]
    
    @State private var pRIpsi: Int = 0
    let pressRangeStringsPSI: [String] = ["[0-10]", "[0-5]", "[0-2]" ]
    let pressRangeMinPSI: [Double] = [0,0,0]
    let pressRangeMaxPSI: [Double] = [10,5,2]
    
    @State private var pRImbar: Int = 0
    let pressRangeStringsmbar: [String] = ["[0-800]", "[0-400]", "[0-200]" ]
    let pressRangeMinmbar: [Double] = [0,0,0]
    let pressRangeMaxmbar: [Double] = [800, 400, 200]
    
    @State private var avgVisible: Bool = false
    @State private var fillText: String = "Fill"
    
    
    @GestureState var draggedBy = CGSize.zero
    @GestureState var draggedPressBy = CGSize.zero
    @GestureState var draggedSpeedBy = CGSize.zero

    var drag: some Gesture {
        DragGesture(minimumDistance: 10)
            .updating($draggedBy) { value, state, transaction in
                state = value.translation
        }
        .onEnded { arg in
            if arg.location.x <= self.devmbw/2 {
                if arg.location.y - arg.startLocation.y <= 0 {
                    if self.tel.isMetric == false {
                        if self.fRIoz + 1 < self.flowRangeStringsOz.count {
                            self.fRIoz += 1
                        }
                    } else {
                        if self.fRIml + 1 < self.flowRangeStringsml.count {
                            self.fRIml += 1
                        }
                    }
                } else {
                    if self.tel.isMetric == false {
                        if self.fRIoz - 1 >= 0 {
                            self.fRIoz -= 1
                        }
                    } else {
                        if self.fRIml - 1 >= 0 {
                            self.fRIml -= 1
                        }
                    }
                }
            } else {
                if arg.location.y - arg.startLocation.y <= 0 {
                    if self.tel.isMetric == false {
                        if self.pRIpsi + 1 < self.pressRangeStringsPSI.count {
                            self.pRIpsi += 1
                        }
                    } else {
                        if self.pRImbar + 1 < self.pressRangeStringsmbar.count {
                            self.pRImbar += 1
                        }
                    }
                } else {
                    if self.tel.isMetric == false {
                        if self.pRIpsi - 1 >= 0 {
                            self.pRIpsi -= 1
                        }
                    } else {
                        if self.pRImbar - 1 >= 0 {
                            self.pRImbar -= 1
                        }
                    }
                }
            }
        }
    }
    
    var dragPress: some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($draggedPressBy) { value, state, transaction in
                state = value.translation
        }
        .onEnded { arg in
            let xdist = arg.location.x - arg.startLocation.x
            let ydist = arg.startLocation.y - arg.location.y
            let scale: CGFloat = 50.0
            //print("x dist: \(arg.location.x - arg.startLocation.x)")
            //print("y dist: \(arg.startLocation.y - arg.location.y)")
            var dist: CGFloat
            if abs(xdist) >= abs(ydist) {
                dist = xdist
            } else {
                dist = ydist
            }
            
            self.tel.sliderPressure = self.tel.sliderPressure + Int (10.0 * dist / scale)
            if self.tel.isMetric == false {
                if self.tel.sliderPressure > 100 { //  10.0 psi
                    self.tel.sliderPressure = 100
                }
            } else {
                if self.tel.sliderPressure > 116 {// 0.8 bar
                    self.tel.sliderPressure = 116
                }
            }
            if self.tel.sliderPressure < 0 {
                self.tel.sliderPressure = 0
            }
            writeValue(data: "(Prs: \(self.tel.sliderPressure))")
        } //
    }
    
    var dragSpeed : some Gesture {
        DragGesture(minimumDistance: 5)
            .updating($draggedSpeedBy) { value, state, transaction in
                state = value.translation
        }
        .onEnded { arg in
            let xdist = arg.location.x - arg.startLocation.x
            let ydist = arg.startLocation.y - arg.location.y
            let scale: CGFloat = 20.0
            //print("x dist: \(arg.location.x - arg.startLocation.x)")
            //print("y dist: \(arg.startLocation.y - arg.location.y)")
            var dist: CGFloat
            if abs(xdist) >= abs(ydist) {
                dist = xdist
            } else {
                dist = ydist
            }
            self.tel.sliderSpeed = self.tel.sliderSpeed + Int (dist / scale)
            if self.tel.sliderSpeed > 100 { //  10.0 psi
                self.tel.sliderSpeed = 100
            }
            if self.tel.sliderSpeed < 0 {
                self.tel.sliderSpeed = 0
            }
            writeValue(data: "(Spd: \(self.tel.sliderSpeed))")
        } //
    }

    var body: some View {
        VStack {
            Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.0f")  \(tel.selectedPlaneTankUnits))").fontWeight(.semibold).font(.system(size: 20))
            ZStack {
                HStack {
                    VStack {
                        if tel.isMetric == false {
                            Gauge(value: self.tel.flowRate, fmtstr: "%.0f", title: "Flow Rate", units: "oz/min", labels: [-45, -30, -15, 0, 15, 30, 45], minValue: -45, maxValue: 45, showBug: true, bugValue: flowRateLongAvg).foregroundColor(.blue).gesture(dragSpeed)//.animation(.default)//.border(Color.yellow)
                        } else {
                            Gauge(value: self.tel.flowRate / 1000, fmtstr: "%.1f", title: "Flow Rate", units: "l/min", labels: [-1.6, -0.8, 0, 0.8, 1.6], minValue: -1.6, maxValue: 1.6, showBug: true, bugValue: flowRateLongAvg).foregroundColor(.blue).gesture(dragSpeed)//.animation(.default)//.border(Color.yellow)
                        }
                    }
                    VStack {
                        if tel.isMetric == false {
                            Gauge(value: self.tel.pressPSI_mB, fmtstr: "%.0f", title: "Pressure", units: "psi", labels: [0, 2, 4, 6, 8, 10], minValue: 0.0, maxValue: 10.0, showBug: true, bugValue: Double(tel.sliderPressure) / 10.0).foregroundColor(.yellow).gesture(dragPress)//.animation(.default)//.border(Color.yellow)
                        } else {
                            Gauge(value: self.tel.pressPSI_mB/1000.0, fmtstr: "%.1f", title: "Pressure", units: "Bar", labels: [0.0, 0.2, 0.4, 0.6, 0.8], minValue: 0.0, maxValue: 0.8, showBug: true, bugValue: Double(tel.sliderPressure) / (10 * 14.5)).foregroundColor(.yellow).gesture(dragPress)//.animation(.default) //.border(Color.yellow)
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
                Text("Total Fuel Flow (oz) \(tele.fuelFlow, specifier: "%3.1f")").font(Font.system(size: 25).monospacedDigit())
            } else {
                //Text("\(tel.selectedPlaneName) (\(tel.selectedPlaneTankCap, specifier: "%.0f") ml)").font(.system(size: 20))
                Text("Total Fuel Flow (ml) \(tele.fuelFlow, specifier: "%4.0f")").font(Font.system(size: 25).monospacedDigit())
            }
            
            if tel.isMetric == false {
                Text("Flow Rate (oz/min) \(tele.flowRate, specifier: "%3.1f")").font(Font.system(size: 20).monospacedDigit())
            } else {
                Text("Flow Rate (ml/min) \(tele.flowRate, specifier: "%4.0f")").font(Font.system(size: 20).monospacedDigit())
            }
            
            Spacer()
            
            if !tel.isMetric {
                chartRecorder(aspect: 2.0 * 812 / devmbh, hgrid: 6, vgrid: 4, //812 is height of 11pro .. scale from there
                    XP: tel.xp, YP: tel.yp, ZP: tel.zp, WP: tel.wp,
                    xrange: 120.0, nlabel: 6, //flowRangeStrings[flowRangeIndex]
                    ymin: flowRangeMinOz[fRIoz], ymax: flowRangeMaxOz[fRIoz],
                    ylabel: "Flow (oz/min): " + flowRangeStringsOz[fRIoz], yvalue: tel.flowRate, ycolor: Color.blue,
                    zmin: pressRangeMinPSI[pRIpsi],   zmax: pressRangeMaxPSI[pRIpsi],  zlabel: "Press(psi): " + pressRangeStringsPSI[pRIpsi],
                    zvalue: tel.pressPSI_mB, zcolor: Color.yellow,
                    wmin: flowRangeMinOz[fRIoz], wmax: flowRangeMaxOz[fRIoz], wcolor: Color.pink, wshow: avgVisible
                ).gesture(drag).padding()
            } else {
                chartRecorder(aspect: 2.0 * 812 / devmbh, hgrid: 6, vgrid: 4,
                              XP: tel.xp, YP: tel.yp, ZP: tel.zp, WP: tel.wp,
                              xrange: 120.0, nlabel: 6,
                              ymin: flowRangeMinml[fRIml], ymax: flowRangeMaxml[fRIml], ylabel: "F (ml/min): " + flowRangeStringsml[fRIml],
                              yvalue: tel.flowRate, ycolor: Color.blue,
                              zmin: pressRangeMinmbar[pRImbar], zmax: pressRangeMaxmbar[pRImbar], zlabel: "P (mBar): " + pressRangeStringsmbar[pRImbar],
                              zvalue: tel.pressPSI_mB, zcolor: Color.yellow,
                              wmin: flowRangeMinOz[fRIml], wmax: flowRangeMaxOz[fRIml], wcolor: Color.pink, wshow: avgVisible
                ).gesture(drag).padding()
            }
            HStack {
                Button(action: {
                    // user defaults is persistence model for cal factor, send it each time pumping is commanded
                    // to be sure the correct cal factor is being used
                    autoOffEmpty = false
                    fillButtonPresses = 0
                    self.avgVisible = false
                    self.fillText = "Fill"
                    flowRateNumber = 0
                    flowRateSum = 0.0 // these three statements arm to auto off detector
                    let ppoE = Double(UserDefaults.standard.integer(forKey: "ppoEmpty")) / 10.0
                    if tele.isSPIpump == false {
                        writeValue(data: String(format: "(CalE: %d)", Int(ppoE*10)))
                        writeValue(data: String(format: "(pMAX: %d)", tele.maxPWM))
                        writeValue(data: String(format: "(Prs: %d)", tele.sliderPressure))
                        writeValue(data: String(format: "(Spd: %d)", tele.sliderSpeed))
                    }
                    setPumpState(state: .Empty)
                    clearChartRecData()
                }){
                    Text("Empty")
                        .font(.system(size: fsize))
                        .frame(width: 65)
                        .padding(5)
                        .background(Color.yellow)
                        .cornerRadius(30)
                        .foregroundColor(Color.black)
                        .padding(2)
                        //.border(Color.yellow)
                }
                Spacer()
                Button(action: {
                    fillButtonPresses = 0
                    self.avgVisible = false
                    self.fillText = "Fill"
                    setPumpState(state: .Off)
                }){
                    Text("Off")
                        .font(.system(size: fsize))
                        .frame(width: 65)
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
                    autoOffFill = false
                    fillButtonPresses = fillButtonPresses + 1
                    //print("fbp: \(fillButtonPresses), mod: \(fillButtonPresses % 2)")
                    if fillButtonPresses == 1 {
                        let ppoF = Double(UserDefaults.standard.integer(forKey: "ppoFill")) / 10.0
                        if tele.isSPIpump == false {
                            writeValue(data: String(format: "(CalF: %d)", Int(ppoF*10)))
                            writeValue(data: String(format: "(pMAX: %d)", tele.maxPWM))
                            writeValue(data: String(format: "(Prs: %d)", tele.sliderPressure))
                            writeValue(data: String(format: "(Spd: %d)", tele.sliderSpeed))
                        }
                        setPumpState(state: .Fill)
                        clearChartRecData()
                    } else {
                        self.avgVisible.toggle()
                        self.fillText = "Auto"
                    }
                }){
                    Text(fillText)
                        .font(.system(size: fsize))
                        .frame(width: 65)
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
                    Text("Pump Speed (%): \(Int(tele.pumpSpeed), specifier: "%d")").font(Font.system(size: 18).monospacedDigit())
                    //Spacer()
                    Text("Running Time: " + (tele.runningTimeString)).font(Font.system(size: 18).monospacedDigit())
                    Text("Pump battery (V): \(tele.battVolt, specifier: "%.2f")").font(Font.system(size: 18).monospacedDigit())

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


   



