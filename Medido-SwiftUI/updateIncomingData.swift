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
    @Published var pressPSI: Double = 0
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
    @Published var selectedPlaneID: UUID!
    @Published var BLEConnected = false
    @Published var isMetric: Bool = false
}


var icount: Int = 0

func updateIncomingData () {
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
        
        if let vf = Double(valueArray[1]) {
            switch valName {
            case "rTIM":
                tele.runningTime = vf
                let rtmins = floor(vf / 60.0)
                let rtsecs = vf - rtmins * 60
                tele.runningTimeString = String(format: "%02.0f:%02.0f", rtmins, rtsecs)
                //print("runningTime \(vf)")
            case "pPSI":
                if tele.isMetric {
                    tele.pressPSI = vf * 1000 / 14.50
                } else {
                    tele.pressPSI = vf
                }
                //print("pressPSI \(vf)")
            case "rPWM":
                tele.pumpSpeed = 100.0 * vf / 1023.0
            case "fCNT":
                if tele.isMetric {
                    tele.fuelFlow = vf
                } else {
                    tele.fuelFlow = vf * 1.77 / 60
                }
                //print("fuelFlow \(vf)")
                if tele.selectedPlaneTankCap > 0 {
                    if vf > tele.selectedPlaneTankCap {
                        if autoOff == false {
                            let utstr = String(format: "%0.1f", tele.selectedPlaneTankCap)
                            let utterance = AVSpeechUtterance(string: "Auto Shut-off at " + utstr +  " ounces")
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-AU")
                            utterance.rate = 0.5
                            synth.speak(utterance)
                            print("Auto off at \(tele.selectedPlaneTankCap) oz")
                            writeValue(data: "(Off)")
                        }
                        autoOff = true
                    }
                }
            case "fRAT":
                if tele.isMetric {
                    tele.flowRate = vf
                } else {
                    tele.flowRate = vf * 1.77 / 60
                }
                //print("flowRate \(vf)")
            case "Batt":
                //print("Batt: \(vf)")
                tele.battVolt = vf * 7.504
                let bco = UserDefaults.standard.integer(forKey: "battCutoff")
                //print("Batt: \(tele.battVolt) | \(vf) | \(bco)")
                if bco > 1 && tele.battVolt > 0.0 && (tele.battVolt < (Double(bco) / 10.0) ) {
                    print("Powering off, bco: \(bco)")
                    writeValue(data: "(PwrOff)")
                }
                break
            case "Heap":
                //print("heap: \(vf)")
                break
            case "Init":
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
