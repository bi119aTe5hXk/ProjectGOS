//
//  ViewController.swift
//  GOSControl
//
//  Created by bi119aTe5hXk on 2020/12/10.
//

import UIKit
import CoreBluetooth
let kBLEService_UUID = "79D33887-FB4D-44FF-81F3-9D6B6259CE83"
let kBLE_Characteristic_UUID_0 = "14660535-154C-485B-B3B7-F3F9CFB84D45"
let kBLE_Characteristic_UUID_1 = "30010C1C-93BF-11D8-8B5B-000A95AF9C6A"

let BLEService_UUID = CBUUID(string: kBLEService_UUID)
let BLE_Characteristic_UUID_0 = CBUUID(string: kBLE_Characteristic_UUID_0)
let BLE_Characteristic_UUID_1 = CBUUID(string: kBLE_Characteristic_UUID_1)

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var connectBTN: UIButton!
    @IBOutlet weak var reloadBTN: UIButton!
    @IBOutlet weak var reStartBTN: UIButton!
    @IBOutlet weak var saveExitBTN: UIButton!
    
    @IBOutlet weak var recodingStatus: UILabel!
    
    @IBOutlet weak var fordwardBTN: UIButton!
    @IBOutlet weak var backwardBTN: UIButton!
    @IBOutlet weak var vpResetBTN: UIButton!
    
//    @IBOutlet weak var previewIV: UIImageView!
//    @IBOutlet weak var previewRefreshBTN: UIButton!
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var characteristic: CBCharacteristic!
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
        switch central.state {
        case CBManagerState.poweredOff:
            print("CoreBluetooth BLE hardware is powered off")
            break
        case CBManagerState.unauthorized:
            print("CoreBluetooth BLE state is unauthorized")
            break

        case CBManagerState.unknown:
            print("CoreBluetooth BLE state is unknown")
            break

        case CBManagerState.poweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready")

            
            break

        case CBManagerState.resetting:
            print("CoreBluetooth BLE hardware is resetting")
            break
        case CBManagerState.unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform")
            break
        @unknown default:
            print("unknow status.")
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        resetUI()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    func resetUI(){
        self.reloadBTN.isEnabled = false
        self.reStartBTN.isEnabled = false
        self.recodingStatus.isEnabled = false
        self.fordwardBTN.isEnabled = false
        self.backwardBTN.isEnabled = false
        self.vpResetBTN.isEnabled = false
        self.saveExitBTN.isEnabled = false
//        self.previewRefreshBTN.isEnabled = false
    }
    func connectToDevice() {
        centralManager.scanForPeripherals(withServices: [BLEService_UUID], options: nil)
        if centralManager.isScanning {
            print("*******************************************************")
            print("Scaning Peripherals...")
        }
    }
    


    // MARK: - Central

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("found peripheral: \(peripheral), advertisementData:\(advertisementData) RSSI:\(String(describing: RSSI))")
        // connect to peripheral
        if let kCBAdvDataLocalName = advertisementData["kCBAdvDataLocalName"] {
            let localName = kCBAdvDataLocalName as! String
            if localName == "ProjectGOS" {
                print("connecting to ProjectGOS")
                centralManager.connect(peripheral, options: nil)
                self.peripheral = peripheral
            }
        }
    }
    
    // Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*******************************************************")
        print("connected! to \(peripheral)")
        
        self.connectBTN.setTitle("Reconnect", for: .normal)
        self.connectBTN.isEnabled = true
        self.reloadBTN.isEnabled = true
        self.reStartBTN.isEnabled = true
        self.recodingStatus.isEnabled = true
        self.fordwardBTN.isEnabled = true
        self.backwardBTN.isEnabled = true
        self.vpResetBTN.isEnabled = true
//        self.previewRefreshBTN.isEnabled = true
        self.saveExitBTN.isEnabled = true
        
        
        centralManager.stopScan()
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect to \(peripheral)")
    }
    
    func isDeviceConnceting() -> Bool {
        if peripheral == nil {
            return false
        }
        return peripheral.state != .disconnected
    }
    
    // Discover Services
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        if let error = error {
            print("error: \(error)")
            return
        }
        self.peripheral = peripheral
        let services = peripheral.services
        print("Found \(services!.count) services! :\(services!) description:")
        
        
        print("*******************************************************")
        for service in services! {
            // discover characteristics
            print("peripheral:\(peripheral)\nancsAuthorized:\(peripheral.ancsAuthorized)\ncanSendWriteWithoutResponse:\(peripheral.canSendWriteWithoutResponse)")
            
            peripheral.discoverCharacteristics([BLE_Characteristic_UUID_0,BLE_Characteristic_UUID_1], for: service)
            
        }
        print("*******************************************************")
    }
    // Discover Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("error: \(error)")
            return
        }
        self.peripheral = service.peripheral
        self.peripheral.delegate = self
        let characteristics = service.characteristics
        print("didDiscover \(characteristics!.count) characteristics! : \(characteristics!)")

        print("*******************************************************")
        for characteristic in characteristics! {
            var out = ""
            if characteristic.value != nil {
                out = Data(characteristic.value!).hexEncodedString()
            }
            print("characteristic.UUID: \(characteristic.uuid) \nvalue: \(out) \nnotifying: \(characteristic.isNotifying) \ndescriptors: \(String(describing: characteristic.descriptors))\nproperties:\(characteristic.properties.rawValue)")

            
            if characteristic.uuid ==  BLE_Characteristic_UUID_0{
                self.characteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            peripheral.readValue(for: characteristic)
        }
        print("*******************************************************")
    }
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("didModifyServices invalidatedServices:\(invalidatedServices)")
        self.peripheral = nil
        resetUI()
    }
    // Update Value
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            print("didUpdateValueFordescriptor Failed with error: \(error)")
            return
        }
        // let out = String(data: characteristic.value!, encoding: .utf8)
        print("didUpdateValueFordescriptor Succeeded: descriptor: \(descriptor)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        if let error = error {
            print("UpdateValueForCharacteristic Failed with error: \(error)")
            print("*******************************************************")
            return
        }
        // let string = String(data: data, encoding: .utf8) //
        //            self.peripheral = peripheral
        //            self.characteristic = characteristic
        //            peripheral.setNotifyValue(true, for: characteristic)
        let out = String(data: characteristic.value!, encoding: .utf8)
        print("didUpdateValueForCharacteristic Successed: service.uuid: \(characteristic.service.uuid)\n characteristic.uuid: \(characteristic.uuid)\n descriptors:\(String(describing: characteristic.descriptors))\nvalue:\(String(describing: out!))")
        print("*******************************************************")
        
        showStatus(msg: out!)
    }
    
    // Update Notification State
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("didUpdateNotificationStateForcharacteristic failed...error: \(error)")
        } else {
            print("didUpdateNotificationStateForcharacteristic success! isNotifying: \(characteristic.isNotifying)")

            print("didUpdateNotificationStateForcharacteristic characteristic.descriptors.count: \(String(describing: characteristic.descriptors))")
        }
    }
    
    
    
    //didWriteValueFor
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if (error != nil) {
            print(error?.localizedDescription as Any)
            return
        }
        print("didWriteValueForDescriptor:\(descriptor)")
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print(error?.localizedDescription as Any)
            return
        }
        print("didWriteValueForCharacteristic:\(characteristic)")
    }
    
    func sentCommandToDevice(hex: String) {
        if isDeviceConnceting() {
            print("sending: \(hex) to \(peripheral):\(characteristic)")
            peripheral.writeValue(
                Data(hex: hex),
                for: self.characteristic,
                type: .withResponse)
            
            
        } else {
            connectToDevice()
            // self.sentCommandToDevice(hex: hex)
        }
    }
    
    
    func showStatus(msg:String)  {
        let msgArr = msg.components(separatedBy: ".")
        switch msgArr[0] {
        case "WELCOM":
            self.recodingStatus.text = "Device connected"
            break
        case "VD":
            self.recodingStatus.text = "Video \(msgArr[1])"
            break
//        case "AI":
//            self.recodingStatus.text = "Fond \(msgArr[1])"
//            break
//        case "PIC":
//            //self.recodingStatus.text = "ERROR:\(msgArr[1])"
//            let img = msgArr[1].toImage()
//            self.previewIV.image = img
//            break
        case "ERR":
            self.recodingStatus.text = "ERROR:\(msgArr[1])"
            break
            
            
        default:
            self.recodingStatus.text = "Stand by"
        }
        //self.peripheral.readValue(for: self.characteristic) //loop
    }
    
    @IBAction func connectBTNP(_ sender: Any) {
        self.peripheral = nil
        connectToDevice()
        
    }
    @IBAction func reloadBTNP(_ sender: Any) {
        self.peripheral.readValue(for: self.characteristic)
        
    }
    @IBAction func reStartBTNP(_ sender: Any) {
        sentCommandToDevice(hex: "0000ca")
    }
    
    @IBAction func fordwardBTNP(_ sender: Any) {
        sentCommandToDevice(hex: "0000fa")
    }
    @IBAction func backwardBTNP(_ sender: Any) {
        sentCommandToDevice(hex: "0000ba")
    }
    @IBAction func vpResetBTNP(_ sender: Any) {
        sentCommandToDevice(hex: "0000cb")
    }
//    @IBAction func previewRefreshBTNP(_ sender: Any) {
//        sentCommandToDevice(hex: "0000cd")
//        self.peripheral.readValue(for: self.characteristic)
//
//    }
    @IBAction func saveExitBTNP(_ sender: Any) {
        sentCommandToDevice(hex: "00001e")
    }
}

extension UnicodeScalar {
    var hexNibble: UInt8 {
        let value = self.value
        if 48 <= value && value <= 57 {
            return UInt8(value - 48)
        } else if 65 <= value && value <= 70 {
            return UInt8(value - 55)
        } else if 97 <= value && value <= 102 {
            return UInt8(value - 87)
        }
        fatalError("\(self) not a legal hex nibble")
    }
}

extension Data {
    init(hex: String) {
        let scalars = hex.unicodeScalars
        var bytes = Array<UInt8>(repeating: 0, count: (scalars.count + 1) >> 1)
        for (index, scalar) in scalars.enumerated() {
            var nibble = scalar.hexNibble
            if index & 1 == 0 {
                nibble <<= 4
            }
            bytes[index >> 1] |= nibble
        }
        self = Data(_: bytes)
    }

    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

//extension String {
//    func toImage() -> UIImage? {
//        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters){
//            return UIImage(data: data)
//        }
//        return nil
//    }
//}
