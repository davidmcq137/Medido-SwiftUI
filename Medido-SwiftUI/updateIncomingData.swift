//
//  updateIncomingData.swift
//  BLETest
//
//  Created by David Mcqueeney on 1/17/20.
//  Copyright © 2020 David Mcqueeney. All rights reserved.
//

import SwiftUI
import Combine
import CoreBluetooth
import AVFoundation

class Telem: ObservableObject {
    @Published var runningTime: Double = 0
    @Published var runningTimeString: String = "---"
    @Published var pressPSI_mB: Double = 0
    @Published var pumpSpeed: Double = 0
    @Published var fuelFlow: Double = 0
    @Published var flowRate: Double = 0
    @Published var battVolt: Double = 0
    @Published var BLERSSIs: [Int] = []
    @Published var BLEperipherals: [String] = []
    @Published var BLEUUIDs: [String] = []
    @Published var BLEUserData: Bool = true
    @Published var iPadLat: Double = 0
    @Published var iPadLon: Double = 0
    @Published var selectedPlaneName: String = ""
    @Published var selectedPlaneTankCap: Double = 0
    @Published var selectedPlaneMaxSpeed: Double = 0
    @Published var selectedPlaneMaxPressure: Double = 0
    @Published var selectedPlaneID: UUID!
    @Published var BLEConnected = false
    @Published var isMetric: Bool = false
    @Published var xp: [Double] = []
    @Published var yp: [Double] = []
    @Published var zp: [Double] = []
    @Published var msgStr: String = ""
    @Published var sliderSpeed: Int = 0
    @Published var sliderPressure: Int = 0
    @Published var motorCurrent: Double = 0
    @Published var maxPWM: Int = 870 // 1023 * 85%
    @Published var overFlowShutoff:  Bool = false
    @Published var isSPIpump = false
}


var icount: Int = 0

func setInfoMessage(msg: String) {
    tele.msgStr = msg
    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
        //tele.msgStr = "🛩"
        tele.msgStr = ""
    }
}

func clearChartRecData () {
    if tele.xp.count > 0 {
        for i in 0 ..< tele.xp.count {
            tele.xp[i] = 0.0
            tele.yp[i] = 0.0
            tele.zp[i] = 0.0
        }
    }
    tele.xp = []
    tele.yp = []
    tele.zp = []
    tele.xp.append(0.0)
    tele.yp.append(0.0)
    tele.zp.append(0.0)
}

func updateIncomingData () {
    
    var vfa: Double = 0
    var utterance: AVSpeechUtterance!
    
    //print("Incoming data")
    ////NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Notify"), object: nil , queue: nil){
    ////notification in
    //print("cav \(characteristicASCIIValue)")
    //InputBuffer = InputBuffer + (characteristicASCIIValue as String) as String
    InputBuffer = InputBuffer.trimmingCharacters(in: .whitespacesAndNewlines) + (characteristicASCIIValue as String).trimmingCharacters(in: .whitespacesAndNewlines)
    //print("**SS**\(InputBuffer)**EE**")
    //print("next cav \( (characteristicASCIIValue as String).trimmingCharacters(in: .whitespacesAndNewlines))")
    //print("next InputBuffer \(InputBuffer)")
    let openIndex = InputBuffer.firstIndex(of: "(")
    let closeIndex = InputBuffer.firstIndex(of: ")")
    if openIndex == nil || closeIndex == nil {
        //print("RETURN FOR MORE DATA BEGIN")
        return
    }
    repeat {
        let openIndex = InputBuffer.firstIndex(of: "(")
        let closeIndex = InputBuffer.firstIndex(of: ")")
        if openIndex == nil || closeIndex == nil {
            //print("RETURN FOR MORE DATA REPEAT")
            return
        }
        if openIndex! > closeIndex! {
            print("OI > CI! \(InputBuffer)")
            InputBuffer.removeSubrange(InputBuffer.startIndex ..< openIndex!)
            //print("post remove: \(InputBuffer)")
            continue
        }
        
        var enclosedString = InputBuffer[openIndex! ..< closeIndex!]
        //print("enclosedString1:\(enclosedString)")
        //print("before InputBuffer:\(InputBuffer)")
        InputBuffer.removeSubrange(openIndex! ... closeIndex!)
        enclosedString.remove(at: openIndex!)
        //print("enclosedString2:\(enclosedString)")
        //print("new InputBuffer:\(InputBuffer)")
        
        let colonIndex = enclosedString.firstIndex(of: ":")
        if colonIndex == nil {
            continue
        }
        let valueArray = enclosedString.components(separatedBy: ":")
        if valueArray.count < 2 {
            print("bad valueArray: \(enclosedString)" )
            print("InputBuffer: \(InputBuffer)")
            return
        }
        let valName = valueArray[0]
        
        //print(valName, valValue)
        
        if valName == "Text" {
            print("Text: \(valueArray[1])")
            continue
        }
        
        if let vf = Double(valueArray[1]) {
            switch valName {
            case "rTIM":
                
                // Note: Much of this code is replicated in MedidoSettings.swift to implement the test function .. should create a function to reuse ...
                
                let rtmins = floor(vf / 60.0)
                let rtsecs = vf - rtmins * 60
                tele.runningTimeString = String(format: "%02.0f:%02.0f", rtmins, rtsecs)
                
                if vf != tele.runningTime { // don't add points to chart recorder data unless we're running
//                    if tele.xp.count >= 120 { // has to be equal to xrange .. go fix this properly...
                    if vf > tele.xp.first! + 120.00 { // full scale on x (time) axis is 120 secs = 2:00 ... should parameterize!
                        tele.xp.remove(at: 0)
                        tele.yp.remove(at: 0)
                        tele.zp.remove(at: 0)
                    }
                    //print("#, apppending: \(tele.xp.count), \(vf), \(tele.flowRate), \(tele.pressPSI_mB)")
                    tele.xp.append(vf)
                    tele.yp.append(tele.flowRate)
                    tele.zp.append(tele.pressPSI_mB)
                    tele.runningTime = vf
                }

                //print("runningTime \(vf)")
            case "pPSI":
                if tele.isMetric {
                    tele.pressPSI_mB = (vf / 14.503) * 1000.0 // metric: store as mBar
                } else {
                    tele.pressPSI_mB = vf
                }
                //print("pressPSI \(vf)")
            case "rPWM":
                tele.pumpSpeed = 100.0 * vf / Double(tele.maxPWM)
            case "fCNT":
                if tele.isMetric {
                    vfa = vf * 29.574       // metric: store as ml
                    tele.fuelFlow = vfa     // fall thru to autoshutoff with vf in ml
                } else {
                    tele.fuelFlow = vf
                    vfa = vf
                }
                //print("fuelFlow \(vf)")
                if tele.selectedPlaneTankCap > 0 {
                    if vfa > tele.selectedPlaneTankCap  && tele.selectedPlaneTankCap > 0 { // don't auto off if tank cap is 0 ..
                        if autoOff == false {
                            let utstr = String(format: "%.0f", tele.selectedPlaneTankCap)
                            if !tele.isMetric {
                                utterance = AVSpeechUtterance(string: "Pump off at " + utstr +  " ounces")
                            } else {
                                utterance = AVSpeechUtterance(string: "Pump off at " + utstr +  " milliliters")
                            }
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
                            utterance.rate = 0.5
                            synth.speak(utterance)
                            if !tele.isMetric {
                                setInfoMessage(msg: String(format: "Pump off at %.1f oz", tele.selectedPlaneTankCap) )
                            } else {
                                setInfoMessage(msg: String(format: "Pump off at %.0f ml", tele.selectedPlaneTankCap) )
                            }
                            writeValue(data: "(Off)")
                        }
                        autoOff = true
                    }
                }
            case "fRAT":
                if tele.isMetric {
                    tele.flowRate = vf * 29.574
                } else {
                    tele.flowRate = vf
                }
                //print("flowRate \(vf)")
            case "Batt":
                //print("Batt: \(vf)")
                tele.battVolt = vf * 7.504
                let bco = UserDefaults.standard.integer(forKey: "battCutoff")
                //print("Batt: \(tele.battVolt) | \(vf) | \(bco)")
                if bco > 1 && tele.battVolt > 0.0 && (tele.battVolt < (Double(bco) / 10.0) ) {
                    print("Powering off, bco: \(bco)")
                    setInfoMessage(msg: String(format: "Auto power off. Pump Battery at %.1fV", tele.battVolt) )
                    writeValue(data: "(PwrOff)")
                }
                break
            case "pSTP":
                if tele.overFlowShutoff {
                    setInfoMessage(msg: "Pump off: Overflow detected")
                    writeValue(data: "(Off)")
                }
            case "fDEL":
                //if vf != 0.0 {
                //    print("fDEL: \(vf)")
                //}
                break
            case "fDET":
                //if vf != 0.0 {
                //    print("fDET: \(vf)")
                //}
                break
            case "cBAD":
                //if vf != 0.0 {
                    //print("cBAD: \(vf)")
                //}
                break
            case "Curr":
                //print("vf/100, curr: \(vf / 100), \( (vf / 100) / 0.030)")
                tele.motorCurrent = (vf / 100) / 0.030 // per Pololu 18V17 manual: current = 20mV/A. voltage sent with offset subtr and x100. observed factor closer to 30mV/A
            case "Heap":
                //print("heap: \(vf)")
                break
            case "Init":
                writeValue(data: "(Prs: \(tele.sliderPressure)")
                writeValue(data: "(Spd: \(tele.sliderSpeed)")
                print("Case init")
            case "pPWM":
                break
            case "PowerDown":
                print("Medido is powering down")
            default:
                print("Bad valName: \(valName)")
            }
        }
    } while true
}

func writeValue(data: String) {
    //print("in wV string: \(data)")
    print("writeValue: \(data)")
    let txdata = data + "\n"
    let valueString = (txdata as NSString).data(using: String.Encoding.utf8.rawValue)
    //change the "data" to valueString
    if let blePeripheral = blePeripheral{
        if let txCharacteristic = txCharacteristic {
            blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
}

func writeCharacteristic(val: Int8){
    var val = val
    let ns = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
    blePeripheral!.writeValue(ns as Data, for: txCharacteristic!, type: CBCharacteristicWriteType.withResponse)
}
