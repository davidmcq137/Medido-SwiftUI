//
//  MedidoSettings.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 2/8/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import SwiftUI

struct MedidoSettings: View {
    
    @State private var ppoFill: Double = Double(UserDefaults.standard.integer(forKey: "ppoFill")) / 10.0
    @State private var ppoEmpty: Double = Double(UserDefaults.standard.integer(forKey: "ppoEmpty")) / 10.0
    @State private var battCutoff: Double = Double(UserDefaults.standard.integer(forKey: "battCutoff")) / 10.0

    @EnvironmentObject var tel: Telem

    let ppoMax = 200.0
    let ppoMin = 20.0
    @State private var runTime: Double = 0.0
    @State private var timerRunning: Bool = false

    
    // default battery cutoff 3V per cell * 3 cells = 9V
    
    let defaults = UserDefaults.standard
    
    var body: some View {
        
        VStack (alignment: .leading){
            VStack {
                Toggle(isOn: $tel.isMetric) {
                    Text("Metric Units Displayed\(checkBoolMetric(tgl: tel.isMetric))")
                }.padding()
            }
            VStack {
                Toggle(isOn: $tel.overFlowShutoff) {
                    Text("Overflow Shutoff Enabled\(checkBoolOverflow(tgl: tel.overFlowShutoff))")
                }.padding()
            }
            VStack {
                Toggle(isOn: $tel.isSPIpump) {
                    Text("Is older SPI pump\(checkBoolSPIpump(tgl: tel.isSPIpump))")
                }.padding()
            }
            HStack {
                Stepper(onIncrement: {
                    if self.ppoFill + 0.1 <= self.ppoMax {
                        self.ppoFill = self.ppoFill + 0.1
                        self.defaults.set(Int(self.ppoFill*10 + 0.5), forKey: "ppoFill")
                    }
                }, onDecrement: {
                    if self.ppoFill - 0.1 >= self.ppoMin {
                        self.ppoFill = self.ppoFill - 0.1
                        self.defaults.set(Int(self.ppoFill*10 + 0.5), forKey: "ppoFill")
                    }
                }, label: { Text("Fill cal factor")
                })
                Text(" \(ppoFill, specifier: "%0.1f")")
            }.padding()
            
            HStack {
                Stepper(onIncrement: {
                    if self.ppoEmpty + 0.1 <= self.ppoMax {
                        self.ppoEmpty = self.ppoEmpty + 0.1
                        self.defaults.set(Int(self.ppoEmpty*10 + 0.5), forKey: "ppoEmpty")
                    }
                }, onDecrement: {
                    if self.ppoEmpty - 0.1 >= self.ppoMin {
                        self.ppoEmpty = self.ppoEmpty - 0.1
                        self.defaults.set(Int(self.ppoEmpty*10 + 0.5), forKey: "ppoEmpty")
                    }
                }, label: { Text("Empty cal factor")
                })
                Text(" \(ppoEmpty, specifier: "%0.1f")")
            }.padding()
            
            HStack {
                Stepper(onIncrement: {
                    self.battCutoff = self.battCutoff + 0.1
                    self.defaults.set(Int(self.battCutoff*10), forKey: "battCutoff")
                }, onDecrement: {
                    if self.battCutoff - 0.1 >= 0 {
                        self.battCutoff = self.battCutoff - 0.1
                        self.defaults.set(Int(self.battCutoff*10), forKey: "battCutoff")
                    }
                }, label: { Text("Power Off Voltage")
                })
                Text(" \(battCutoff, specifier: "%0.2f")")
            }.padding()
            
            HStack {
                Stepper(onIncrement: {
                    if tele.maxPWM + 1 <= 1023 {
                        tele.maxPWM = tele.maxPWM + 1
                        self.defaults.set(tele.maxPWM, forKey: "maxPWM")
                    }
                }, onDecrement: {
                    if tele.maxPWM - 1 >= 50 {
                        tele.maxPWM = tele.maxPWM - 1
                        self.defaults.set(tele.maxPWM, forKey: "maxPWM")
                    }
                }, label: { Text("Maximum PWM")
                })
                Text(" \(tele.maxPWM, specifier: "%d")")
            }.padding()
            
            Text("Pump Current (A): \(tele.motorCurrent, specifier: "%.2f")").padding()
            
            Button(action: {
                self.runTime = 0.0
                let interval: Double = 0.2
                if self.timerRunning == false {
                    clearChartRecData()
                    let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                        if self.timerRunning == false {
                            timer.invalidate()
                        } else {
                            if self.runTime > tele.xp.first! + 120.00 {
                                tele.xp.remove(at: 0)
                                tele.yp.remove(at: 0)
                                tele.zp.remove(at: 0)
                            }
                            tele.runningTime = self.runTime
                            let rtmins = floor(self.runTime / 60.0)
                            let rtsecs = self.runTime - rtmins * 60
                            tele.runningTimeString = String(format: "%02.0f:%02.0f", rtmins, rtsecs)
                            tele.xp.append(self.runTime)
                            if tele.isMetric == false {
                                tele.flowRate = 40 * sin(2 * .pi * self.runTime / 60.0)
                            } else {
                                tele.flowRate = 800 * sin(2 * .pi * self.runTime / 60.0)
                            }
                            tele.fuelFlow += tele.flowRate * 0.2 / 60.0
                            tele.yp.append(tele.flowRate)
                            if tele.isMetric == false {
                                tele.pressPSI_mB = 5 + 4 * cos(2 * .pi * self.runTime / 60.0)
                            } else {
                                tele.pressPSI_mB = 400 + 300 * cos(2 * .pi * self.runTime / 60.0)
                            }
                            tele.zp.append(tele.pressPSI_mB)
                            
                            self.runTime += interval
                            //print("Timer fired!")
                            //print("runTime: \(self.runTime)")
                        }
                    }
                    self.timerRunning = true
                } else {
                    self.timerRunning = false
                }
            }){
                Text("Test")
                    .frame(width: 60)
                    .font(.system(size: 20))
                    .padding(5)
                    .background(Color.purple)
                    .cornerRadius(30)
                    .foregroundColor(Color.primary)
                    .padding()
            }
            
        }
    }
}




private func checkBoolMetric(tgl: Bool) -> String {
    //print("tgl is: \(tgl)")
    UserDefaults.standard.set(tgl, forKey: "isMetric")
    return("")

}

private func checkBoolOverflow(tgl: Bool) -> String {
    //print("tgl is: \(tgl)")
    UserDefaults.standard.set(tgl, forKey: "overFlowShutoff")
    return("")
}

private func checkBoolSPIpump(tgl: Bool) -> String {
    //print("tgl is: \(tgl)")
    UserDefaults.standard.set(tgl, forKey: "isSPIpump")
    return("")
}
/*
 
 @State var quantity: Int = 0
 Stepper(onIncrement: {
     self.quantity += 1
 }, onDecrement: {
     self.quantity -= 1
 }, label: { Text("Quantity \(quantity)") })
 */
