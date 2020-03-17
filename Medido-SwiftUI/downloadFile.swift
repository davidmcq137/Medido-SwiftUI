//
//  File.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 3/13/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import Foundation

let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
   let destinationFileUrl = documentsUrl.appendingPathComponent("downloadedFile.jpg")
   
   //Create URL to the source file you want to download
   let fileURL = URL(string: "https://s3.amazonaws.com/learn-swift/IMG_0001.JPG")
   
   let sessionConfig = URLSessionConfiguration.default
   let session = URLSession(configuration: sessionConfig)

   let request = URLRequest(url:fileURL!)
   
   let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
       if let tempLocalUrl = tempLocalUrl, error == nil {
           // Success
           if let statusCode = (response as? HTTPURLResponse)?.statusCode {
               print("Successfully downloaded. Status code: \(statusCode)")
           }
           
           do {
               try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
           } catch (let writeError) {
               print("Error creating a file \(destinationFileUrl) : \(writeError)")
           }
           
       } else {
        print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
       }
   }
   task.resume()
   

