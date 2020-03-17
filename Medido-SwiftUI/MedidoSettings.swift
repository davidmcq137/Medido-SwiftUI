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
    @State private var wifipwd: String = ""

    
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
            
            //Text("Pump Current (A): \(tele.motorCurrent, specifier: "%.2f")").padding()
            
            
            HStack {
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
                    Text("Demo")
                        .frame(width: 60)
                        .font(.system(size: 20))
                        .padding(5)
                        .background(Color.purple)
                        .cornerRadius(30)
                        .foregroundColor(Color.primary)
                        .padding()
                }
                // empirically observed: strings over 14 chars send to the BLE Friend cause it to fail, presumably because we are not listening to the
                // hw flow control. For now, just chunk things up into 14b or less and put in delays between transmissions
                Button(action: {
                    print("OTA pressed, sending (OTA:1) to writeValue")
                    self.tel.OTApercent = 0
                    writeValue(data: "stop:0")
                    
                    let dt = 0.01
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt) {
                        writeValue(data: "dir:/")
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt*1.0) {
                        writeValue(data: "socket:8080")
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt*2.0) {
                        writeValue(data: "host:10.0.0.48")
                    }//                   12345678901234
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt*3.0) {
                        writeValue(data: "image:MedP.img")
                    }//                   12345678901234
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt*4.0) {
                        writeValue(data: "pwd:\(self.wifipwd)")
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt*5.0) {
                        writeValueRaw(data: "ssid:Mt McQ")
                        //                   12345678901
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt*6.0) {
                        writeValueRaw(data: "ssid:ueeney ")
                    }//                      123456789012
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt*7.0) {
                        writeValue(data:    "ssid:Guest")
                    }//                      123456789012
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dt*8.0) {
                        writeValue(data: "update:0")
                    }
                    
                    
                    //let arr = lfstest()
                    //writeValue(data: "(Opn:0)")
                    //for i in 0 ..< arr.count {
                    //    writeValue(data: arr[i])
                    //    print("writing
                    //        row: \(i)")
                    // }
                    //writeValue(data: arr[0])
                    //print("wrote: \(arr[0])")
                    //writeValue(data: "(Cls:0)")
                }){
                    Text("OTA")
                        .frame(width: 60)
                        .font(.system(size: 20))
                        .padding(5)
                        .background(Color.purple)
                        .cornerRadius(30)
                        .foregroundColor(Color.primary)
                        .padding()
                }
                SecureField("WiFi Pwd", text: self.$wifipwd).textFieldStyle(RoundedBorderTextFieldStyle()).frame(height: 30)
                    .padding()
                    .onAppear{
                        self.tel.OTApercent = 0
                }
                
            }
            Text("OTA status: \(transOTA(pct: tel.OTApercent, conn: tel.BLEConnected))").frame(height: 30).padding()
        }
    }
}

private func transOTA(pct: Int, conn: Bool) -> String {
    switch pct {
    case -1:
        return("No WiFi connection")
    case -2:
        return("Cannot connect host IP")
    case -3:
        return("HTTP GET failed (-3)")
    case -4:
        return("HTTP GET failed (-4)")
    case -5:
        return("Cannot save img file")
    case -6:
        return("Timeout: no WiFi conn")
    case -7:
        return("Timeout: Download")
    case 0:
        if conn == true {
            return("Ready to Update")
        } else {
            return("Pump not connected")
        }
    case 1:
        return("Starting WiFi on pump")
    case 2:
        return("WiFi connected")
    case 3:
        return("Making HTTP GET request")
    case 100:
        return("100% - Restarting pump")
    default:
        return("\(pct)%")
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


