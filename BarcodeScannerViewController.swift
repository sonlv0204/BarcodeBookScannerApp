//
//  BarcodeScannerViewController.swift
//  BarcodeBookScanner
//
//  Created by CarlJohan on 25/06/2017.
//  Copyright © 2017 Carl-Johan. All rights reserved.
//

import UIKit
import AVFoundation

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var session: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let label = UILabel(frame: CGRect(x: 160, y: 200, width: 200, height: 21))
        
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 1
        label.layer.cornerRadius = 4
        
        
        
        // Create a session object.
        session = AVCaptureSession()
        let metadataOutput = AVCaptureMetadataOutput()
        
        // Set the captureDevice.
        let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        // Create input object.
        let videoInput: AVCaptureDeviceInput?
        do { videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch { print("ERROR: \(error)"); return }
        
        // Add input to the session.
        if session.canAddInput(videoInput!) {
            session.addInput(videoInput!)
        } else {
            scanningNotPossible()
            print(890)
        }
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            let rectOfInterest = CGRect(x: 160.0, y: 200.0, width: 200.0, height: 21.0)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code]
            //metadataOutput.rectOfInterest = rectOfInterest
            
            session.commitConfiguration()
        } else {
            print("Couldn't add output")
        }
        
        
        // Add previewLayer and have it show the video data.
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        view.layer.addSublayer(previewLayer)
        view.addSubview(label)
        view.bringSubview(toFront: label)
        
        // Begin the capture session.
        session.startRunning()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (session?.isRunning == true) {
            session.stopRunning()
        }
    }
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        print(1)
        // Get the first object from the metadataObjects array.
        if let barcodeData = metadataObjects.first {
            // Turn it into machine readable code
            let barcodeReadable = barcodeData as? AVMetadataMachineReadableCodeObject;
            if let readableCode = barcodeReadable {
                // Send the barcode as a string to barcodeDetected()
                barcodeDetected(readableCode.stringValue);
            }
            
            // Vibrate the device to give the user some feedback.
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Avoid a very buzzy device.
            session.stopRunning()
        }
    }
    
    func barcodeDetected(_ code: String) {
        // Let the user know we've found something.
        //let alert = UIAlertController(title: "Found a Barcode!", message: code, preferredStyle: UIAlertControllerStyle.alert)
        //alert.addAction(UIAlertAction(title: "Search", style: UIAlertActionStyle.destructive, handler: { action in
        
        // Remove the spaces.
        //let trimmedCode = code.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let trimmedCode = Int(code.trimmingCharacters(in: NSCharacterSet.whitespaces))
        // EAN or UPC?
        // Check for added "0" at beginning of code.
        
        let trimmedCodeString = "\(trimmedCode)"
        var trimmedCodeNoZero: String
        
        if trimmedCodeString.hasPrefix("0") && trimmedCodeString.characters.count > 1 {
            trimmedCodeNoZero = String(trimmedCodeString.characters.dropFirst())
            // Send the doctored UPC to DataService.searchAPI()
            //DataService.searchAPI(trimmedCodeNoZero)
            print(trimmedCodeNoZero)
        } else {
            print(trimmedCodeString)
            //UdacityClient.sharedInstance.getSessionID(username, password) { (succes, error) in
            GoogleBooksClient.sharedInstance.getBookInformationFromBarcode(trimmedCode!, CHForBookInformation: { (succes, data) in
                print(2222)
            })
            
            // Send the doctored EAN to DataService.searchAPI()
            //DataService.searchAPI(trimmedCodeString)
        }
        
        print("Scan succesfull")
        print("---------------")
        //}))
        
    }
    
    
    
    func scanningNotPossible() {
        // Let the user know that scanning isn't possible with the current device.
        print("Scan not possible")
        let alert = UIAlertController(title: "Can't Scan.", message: "Let's try a device equipped with a camera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        session = nil
    }
    
}

