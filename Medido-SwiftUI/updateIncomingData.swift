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
    @Published var selectedPlaneTankUnits: String = "---"
    @Published var selectedPlaneMaxSpeed: Double = 0
    @Published var selectedPlaneMaxPressure: Double = 0
    @Published var selectedPlaneMaxPressureUnits: String = "---"
    @Published var selectedPlaneID: UUID!
    @Published var BLEConnected = false
    @Published var isMetric: Bool = false
    @Published var xp: [Double] = []
    @Published var yp: [Double] = []
    @Published var zp: [Double] = []
    @Published var wp: [Double] = []
    @Published var msgStr: String = ""
    @Published var sliderSpeed: Int = 0
    @Published var sliderPressure: Int = 0
    @Published var motorCurrent: Double = 0
    @Published var maxPWM: Int = 870 // 1023 * 85%
    @Published var overFlowShutoff:  Bool = false
    @Published var isSPIpump = false
    @Published var OTApercent: Int = 0
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
            tele.wp[i] = 0.0
        }
    }
    tele.xp = []
    tele.yp = []
    tele.zp = []
    tele.wp = []
    tele.xp.append(0.0)
    tele.yp.append(0.0)
    tele.zp.append(0.0)
    tele.wp.append(0.0)
    flowRateLongAvg = 0.0
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
        
        
        if valName == "Text" {
            print("Text: \(valueArray[1])")
            continue
        }
        
        if let vf = Double(valueArray[1]) {
            //print(valName, vf)

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
                        tele.wp.remove(at: 0)
                    }
                    //print("#, appending: \(tele.xp.count), \(vf), \(tele.flowRate), \(tele.pressPSI_mB)/ \(flowRateTailAvg)")
                    tele.xp.append(vf)
                    tele.yp.append(tele.flowRate)
                    tele.zp.append(tele.pressPSI_mB)
                    tele.wp.append(flowRateLongAvg)
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
          
                if tele.selectedPlaneTankCap > 0 {
                    if vfa > tele.selectedPlaneTankCap * 1.10  && tele.selectedPlaneTankCap > 0 { // don't auto off if tank cap is 0 .. and only trip at cap + 10%
                        if autoOffFill == false {
                            let utstr = String(format: "%.0f", tele.selectedPlaneTankCap)
                            if !tele.isMetric {
                                utterance = AVSpeechUtterance(string: "Pump off at " + utstr +  " ounces")
                            } else {
                                utterance = AVSpeechUtterance(string: "Pump off at " + utstr +  " milliliters")
                            }
                            utterance.voice = AVSpeechSynthesisVoice(language: ttsLanguage)
                            utterance.rate = 0.5
                            synth.speak(utterance)
                            if !tele.isMetric {
                                setInfoMessage(msg: String(format: "Pump off at %.1f oz", tele.selectedPlaneTankCap) )
                            } else {
                                setInfoMessage(msg: String(format: "Pump off at %.0f ml", tele.selectedPlaneTankCap) )
                            }
                            setPumpState(state: .Off)
                        }
                        autoOffFill = true
                    }
                }
            case "fRAT":
                if tele.isMetric {
                    tele.flowRate = vf * 29.574
                } else {
                    tele.flowRate = vf
                }
                //print("flowRate \(vf)")
                // now compute average fuel flow -- only start after 10 secs to get stabilized
                if tele.runningTime > 10.0 {
                    if flowRateNumber <= 0 {
                        flowRateNumber = 1
                        flowRateSum = tele.flowRate
                        flowRateAverage = flowRateSum
                        flowRateLowCount = 0
                    } else {
                        flowRateSum = flowRateSum + tele.flowRate
                        flowRateNumber = flowRateNumber + 1
                        flowRateAverage = flowRateSum / Double(flowRateNumber)
                    }
                }
                // if we've been running for 20 seconds (and thus averaging for 10...) and are in reverse (neg flowRate) see if we are emptying the tank .. signified by flow rate dropping below 30% of average
                if tele.runningTime > 20 && PumpState == .Empty && autoOffEmpty == false {
                    if abs(tele.flowRate) < abs(flowRateAverage * 0.30) {
                        print("low count: \(flowRateLowCount): \(tele.flowRate)")
                        flowRateLowCount = flowRateLowCount + 1
                    }
                    if flowRateLowCount > 2 {
                        setInfoMessage(msg: "Pump off ... low flow")
                        setPumpState(state: .Off)
                        autoOffEmpty = true
                        utterance = AVSpeechUtterance(string: "Pump off .. low flow")
                        utterance.voice = AVSpeechSynthesisVoice(language: ttsLanguage)
                        utterance.rate = 0.5
                        synth.speak(utterance)
                    }
                }
                // if we have N points accumulated, compute the average flow for the last N values .. leave in global var flowRateTailAvg
                var longsum: Double = 0.0
                var shortsum: Double = 0.0
                //print("#: \(tele.yp.count)")
                //print("mod: \(tele.yp.count % (flowRateTailSize / 10))")
                if PumpState == .Fill && tele.yp.count > flowRateTailSize { //&& tele.yp.count % (flowRateTailSize / 10) == 0 {
                    for s in tele.yp.suffix(flowRateTailSize) {
                        longsum = longsum + s
                    }
                    flowRateLongAvg = longsum / Double(flowRateTailSize)
                    for s in tele.yp.suffix(20) {
                        shortsum = shortsum + s
                    }
                    flowRateShortAvg = shortsum / 20.0
                    var vsqsum: Double = 0
                    var rms: Double = 0
                    for s in tele.yp.suffix(flowRateTailSize) {
                        vsqsum = vsqsum + (s - flowRateLongAvg) * (s - flowRateLongAvg)
                    }
                    rms = sqrt(vsqsum) / sqrt(Double(flowRateTailSize))
                    
                    //print("#: \(tele.yp.count), avg: \(flowRateLongAvg), rmsV: \(rms), ratio: \(abs(flowRateShortAvg - flowRateLongAvg) / rms), runavg: \(flowRateShortAvg), fill button ct: \(fillButtonPresses)")
                    // note that the ratio of 1.8 was determined empirically...
                    if abs(flowRateShortAvg - flowRateLongAvg) > 1.2 * rms && flowRateShortAvg > 0 {
                        setPumpState(state: .Off)
                        setInfoMessage(msg: "Pump off - Pressure Drop/Overflow")
                        let utstr = String(format: "%.0f", tele.fuelFlow)
                        if !tele.isMetric {
                            utterance = AVSpeechUtterance(string: "Pump off at " + utstr +  " ounces")
                        } else {
                            utterance = AVSpeechUtterance(string: "Pump off at " + utstr +  " milliliters")
                        }
                        utterance.voice = AVSpeechSynthesisVoice(language: ttsLanguage)
                        utterance.rate = 0.5
                        synth.speak(utterance)
                    }
                }
            case "Batt":
                //print("Batt: \(vf)")
                tele.battVolt = vf * 7.504
                let bco = UserDefaults.standard.integer(forKey: "battCutoff")
                //print("Batt: \(tele.battVolt) | \(vf) | \(bco)")
                if bco > 1 && tele.battVolt > 0.0 && (tele.battVolt < (Double(bco) / 10.0) ) {
                    print("Powering off, bco: \(bco)")
                    setInfoMessage(msg: String(format: "Auto power off. Pump Battery at %.1fV", tele.battVolt) )
                    writeValue(data: "(PwrOff)")
                    utterance = AVSpeechUtterance(string: "Auto Power off. Main battery low")
                    utterance.voice = AVSpeechSynthesisVoice(language: ttsLanguage)
                    utterance.rate = 0.5
                    synth.speak(utterance)
                }
                break
            case "pSTP":
                if tele.overFlowShutoff {
                    setInfoMessage(msg: "Pump off: Overflow detected")
                    setPumpState(state: .Off)
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
                writeValue(data: "(Prs: \(tele.sliderPressure))")
                writeValue(data: "(Spd: \(tele.sliderSpeed))")
                print("Case init")
            case "pPWM":
                break
            case "PowerDown":
                print("Medido is powering down")
            case "OTA":
                tele.OTApercent = Int(vf)
            default:
                print("Bad valName: \(valName)")
            }
        }
    } while true
}

func setPumpState (state: RunState) {
    switch state {
    case .Fill :
        writeValue(data: "(Fill)")
    case .Empty :
        writeValue(data: "(Empty)")
    case .Off :
        writeValue(data: "(Off)")
    }
    PumpState = state
}

func writeValue(data: String) {
    writeValueRaw(data: data + "\n")
}

func writeValueRaw(data: String) {
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
