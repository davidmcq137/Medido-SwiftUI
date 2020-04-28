//
//  BLELocation.swift
//
//
//  Created by David McQueeney on 1/18/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import Foundation
import SwiftUI
import CoreBluetooth
//import CoreLocation
import Combine
import AVFoundation

var txCharacteristic : CBCharacteristic?
var rxCharacteristic : CBCharacteristic?
var blePeripheral : CBPeripheral?
var characteristicASCIIValue = NSString()
var BLETimer: Timer?
var InputBuffer: String = ""



var RSSIs = [NSNumber]()
var peripherals: [CBPeripheral] = []
var characteristicValue = [CBUUID: NSData]()
var data = NSMutableData()
var writeData: String = ""
var timer = Timer()
var characteristics = [String : CBCharacteristic]()

var horizontalAccuracyGPS: Double?
var synth: AVSpeechSynthesizer!


class BLELocation:  UIResponder, UIApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate { //}, CLLocationManagerDelegate {
    
    var centralManager: CBCentralManager!
    static var blelocation = BLELocation()

    
    private override init() {
        super.init()
        print("super.init")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //@EnvironmentObject var tel: Telem

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {


        blePeripheral = peripheral
        var matchID: Bool = false
        print("have new one: \( peripheral.name ?? "unknown") ")
        print("peripheral.name: \(peripheral.name ?? "unkname"), peripheral.identifier: \(peripheral.identifier)")
        print("peripherals.count: \(peripherals.count)")
        
        if peripherals.count > 0 {
            for i in 0 ..< peripherals.count {
                print("i: \(i), peripheral identifier: \(peripheral.identifier), peripherals[i].identifier: \(peripherals[i].identifier)")
                if peripheral.identifier == peripherals[i].identifier {
                    print("match to: \(peripheral.identifier)")
                    matchID = true
                }
            }
            
            if matchID == true {
                print("Duplicate: \(peripheral)")
                print("returning")
                return
            }
        }
        
        var str: String = "Device: " + (peripheral.name ?? "unknown")
        str = str + " UUID: " + (blePeripheral?.identifier.uuidString ?? "unknown") + " RSSI: \(RSSI)"
        print("str: \(str)")
        
        print("Appending")
        peripherals.append(peripheral)
        tele.BLEperipherals.append(str)
        tele.BLEUUIDs.append(blePeripheral?.identifier.uuidString ?? "unknown")
        print("Count after append: \(peripherals.count)")

        peripheral.delegate = self


        if blePeripheral != nil {
            print("Found new pheripheral devices with services")
            print("Peripheral name: \(peripheral.name ?? "unknown")")
            print("Peripharal identifier: \(peripheral.identifier)")
            print("RSSI: \(RSSI)")
            //print ("Advertisement Data : \(advertisementData)")
        }
        
        let defaults = UserDefaults.standard
        let storedBLEUUID = defaults.object(forKey: "BLEUUID") as? String ?? "unknown"
        if storedBLEUUID == "unknown" {
            tele.BLEUserData = false
        } else {
            tele.BLEUserData = true
        }
        print("stored UUID: \(storedBLEUUID)")

        //
        // check if we have the BTE id of the device we are configured for
        // todo: arrange persistent storage for this value at a later time .. a config option is needed
        //
        // C43BD593-DA12-7816-79D0-8B39B1E0C424
        // 982526B8-658D-D0CB-5280-2049D0BF8305
        // 087F253D-24A7-EF4E-9D4D-09650EC0C673
        //
        if blePeripheral?.identifier.uuidString == storedBLEUUID {
        //if blePeripheral?.identifier.uuidString == "087F253D-24A7-EF4E-9D4D-09650EC0C673" {
            print("YUP! ... Connecting to device \(peripheral.identifier)")
            characteristicASCIIValue = ""
            connectToDevice()
        } else {
            print("NOPE!")
            print("id:\(String(describing: blePeripheral?.identifier.uuidString))")
        }
    }
    
    /*
    let manager = CLLocationManager()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("Found user's location: \(location)")
            print("Lat: \(location.coordinate.latitude)")
            print("Lon: \(location.coordinate.longitude)")
            
            //print("DEBUG: Inserting BDS")
            //iPadLat = 41.339733//location.coordinate.latitude
            //iPadLon = -74.431618//location.coordinate.longitude
            
            //print("DEBUG: Inserting GA Jets")
            //iPadLat = 33.1372    //location.coordinate.latitude
            //iPadLon = -84.611143 //location.coordinate.longitude

            tele.iPadLat = location.coordinate.latitude
            tele.iPadLon = location.coordinate.longitude
            let hAcc = location.horizontalAccuracy
            horizontalAccuracyGPS = hAcc
            let vAcc = location.verticalAccuracy
            print("hacc, vacc:", hAcc, vAcc)
            //tele.xxxlat = iPadLat
            //tele.xxxlon = iPadLon
            if hAcc > 10.0 {
                print("requesting location again")
                self.manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.manager.requestLocation()
                //return
            }
            
            //_ = findField(lat: tele.iPadLat, lon: tele.iPadLon)
            //if activeField.imageIdx >= 0 {
            //    print("We are at a known field!")
            //    print ("shortname: \(String(activeField.shortname))")
            //}
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    */
    
    func MedidoStartup() {
        
        print("In Medido startup")
        print("Screen H x W: \(UIScreen.main.bounds.height) x \(UIScreen.main.bounds.width)")
        let utterance = AVSpeechUtterance(string: "Launching Medido Pump")
        utterance.voice = AVSpeechSynthesisVoice(language: ttsLanguage)
        utterance.rate = 0.5
        synth = AVSpeechSynthesizer()
        print("about to speak utterance")
        synth.speak(utterance)

        // setup code to get gps location .. not used in medido pump
        //manager.delegate = self
        //manager.requestAlwaysAuthorization()
        //manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        //manager.requestLocation()
        
        // observed default for Sandor's flow sensors is 103-106 pulse per oz, set default to 104
        // stored as Int in user defaults, *10 for one decimal place
        let defaultFactor: Int = 104*10
        
        let ppoF = UserDefaults.standard.integer(forKey: "ppoFill")
        print("ppoF is \(ppoF)")
        if ppoF < 1 {
            UserDefaults.standard.set(defaultFactor, forKey: "ppoFill") // mult by 10 for storage as int
        }
        
        let ppoE = UserDefaults.standard.integer(forKey: "ppoEmpty")
        print("ppoE is \(ppoE)")
        if ppoE < 1 {
            UserDefaults.standard.set(defaultFactor, forKey: "ppoEmpty") // mult by 10 for storage as int
        }
        
        let defaultCutoff = 9.0 * 10 // store as Int with one decimal place
        
        let bco = UserDefaults.standard.integer(forKey: "battCutoff")
        print("battCutoff is \(bco)")
        if bco < 1 {
            UserDefaults.standard.set(defaultCutoff, forKey: "battCutoff")
        }
        
        
        print("returning from Medido startup")
        
    }
    
    func startScan() {
        peripherals = []
        tele.BLEperipherals = []
        tele.BLEUUIDs = []
        print("Now Scanning...")
        timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        Timer.scheduledTimer(timeInterval: 17, target: self, selector: #selector(self.cancelScan), userInfo: nil, repeats: false)
    }
    
    /*We also need to stop scanning at some point so we'll also create a function that calls "stopScan"*/
    //@objc func cancelScan() {
    @objc func cancelScan() {
        centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripherals.count)")
        //if peripherals.count > 0 && !BLEConnected { // hopefully user went to BLE devices tab and picked one...
        if !tele.BLEConnected { // hopefully user went to BLE devices tab and picked one...
            print("****** Not connected: RESTARTING SCAN *********")
            startScan()
        }
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     This method is invoked when a call to connect(_:options:) is successful. You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    //-Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        tele.BLEConnected = true
        let BLE_id = blePeripheral!.identifier.uuidString
        print("didconnect")
        print("Peripheral ID: \(BLE_id)")
        print("Peripheral info: \(String(describing: blePeripheral))")
        print("BLEService_UUID: \(BLEService_UUID)")
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        print("Found matching one, stop scanning")
        centralManager?.stopScan()
        
        //Erase data that we might have
        data.length = 0
        
        peripheral.delegate = self
        
        //Only look for services that matches transmit uuid
        peripheral.discoverServices([BLEService_UUID])
        
        updateIncomingData()
        
    }
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     */
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    
    func disconnectAllConnection() {
        centralManager.cancelPeripheralConnection(blePeripheral!)
    }
    
    /*
     Invoked when you discover the characteristics of a specified service.
     This method is invoked when your app calls the discoverCharacteristics(_:for:) method. If the characteristics of the specified service are successfully discovered, you can access them through the service's characteristics property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        //print("***************** did discover characteristics for **************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        //print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //print("******************** did update notification state for ***********************************")
        
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    func refreshAction(_ sender: AnyObject) {
        // was @ibaction func refreshAction
        disconnectFromDevice()
        startScan()
    }
    
    /*
     Invoked when the central manager’s state is updated.
     This is where we kick off the scan if Bluetooth is turned on.
     */
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            print("Bluetooth Enabled")
            startScan()
            
        } else {
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
            
        }
    }
    
    // Getting Values From Characteristic
    
    /*After you've found a characteristic of a service that you are interested in, you can read the characteristic's value by calling the peripheral "readValueForCharacteristic" method within the "didDiscoverCharacteristicsFor service" delegate.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("**************** did update Value for characteristic")
        if characteristic == rxCharacteristic {
            //print("char: \(characteristic), rxChar: \(String(describing: rxCharacteristic))")
            if characteristic.value == nil {
                //print("===============>>>>>>>>>>>>  characteristic.value is nil")
                return
            }
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                characteristicASCIIValue = ASCIIstring
                updateIncomingData()
                
            }
        }
    }
    
    /*
     Invoked when you discover the peripheral’s available services.
     This method is invoked when your app calls the discoverServices(_:) method. If the services of the peripheral are successfully discovered, you can access them through the peripheral’s services property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //print("********** did discover services *********************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
            // bleService = service
        }
        print("Discovered Services: \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("********* did discover descriptors for **********************************************")
        
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        if ((characteristic.descriptors) != nil) {
            
            for x in characteristic.descriptors!{
               let descript = x as CBDescriptor?
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript?.description))")
                print("Rx Value \(String(describing: rxCharacteristic?.value))")
                print("Tx Value \(String(describing: txCharacteristic?.value))")
            }
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        tele.BLEConnected = false
        //NotificationCenter.default.removeObserver(self)
        // no point ot restarting scan here .. need to check periodically in incoming data loop
        print("Restarting Scan")
        startScan()
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        //print("Message sent")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("didWriteValueFor succeeded")
    }
    
    
    //-Terminate all Peripheral Connection
    
    //Peripheral Connections: Connecting, Connected, Disconnected
    
    //-Connection
    func connectToDevice () {
        print("connectToDevice connecting to: \(String(describing: blePeripheral))")
        centralManager?.connect(blePeripheral!, options: nil)
    }
    
    //-Terminate all Peripheral Connection
    /*
     Call this when things either go wrong, or you're done with the connection.
     This cancels any subscriptions if there are any, or straight disconnects if not.
     (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    func disconnectFromDevice () {
        if blePeripheral != nil {
            // We have a connection to the device but we are not subscribed to the Transfer Characteristic for some reason.
            // Therefore, we will just disconnect from the peripheral
            centralManager?.cancelPeripheralConnection(blePeripheral!)
        }
    }
    //-Terminate all Peripheral Connection
    /*
     Call this when things either go wrong, or you're done with the connection.
     This cancels any subscriptions if there are any, or straight disconnects if not.
     (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    
    
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        //print("application new scene session")
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        //print("application discard scene session")
    }
 }



