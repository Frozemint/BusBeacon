//
//  ViewController.swift
//  BusBeacon2
//
//  Created by Nami on 2018-11-25.
//  Copyright © 2018 Nami. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, XMLParserDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var overrideBusStopID: UITextField!
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var auxTextLabel: UILabel!
    var currentParsingElement: String!
    var arrivals = [String]()
    var error: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auxTextLabel.text = ""
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func searchBusID(_ sender: Any) {
        mainTextLabel.text = "Getting results..."
        getTransLinkData(stopID: overrideBusStopID.text)
    }

    func updateUI(){
        mainTextLabel.text = "Stop ID: \(overrideBusStopID.text!)"
        auxTextLabel.text = "Buses in: \(arrivals.joined(separator: ", ")) mins"
    }
    
    func getTransLinkData(stopID: String?){
        error = false
        arrivals.removeAll()
        let endpoint = NSURL(string: "https://api.translink.ca/rttiapi/v1/stops/\(stopID!)/estimates?apikey=\(apiKey)")
        var urlRequest = URLRequest(url: endpoint! as URL)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/XML", forHTTPHeaderField: "content-Type:")
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data else {
                print("request failed: \(error!)")
                return
            }
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }
        task.resume()
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let foundedChar = string.trimmingCharacters(in:NSCharacterSet.whitespacesAndNewlines)
        if (!foundedChar.isEmpty) {
            if (currentParsingElement == "Message"){
                //for a bad request, TransLink returns an XML file with an element called Message
                //containing the error message.
                //If it is present, we print the error and abort parsing
                print("ERROR: \(foundedChar)")
                error = true
                DispatchQueue.main.async {
                    self.mainTextLabel.text = "Error while searching:"
                    self.auxTextLabel.text = "\(foundedChar)"
                }
                return
            } else if (currentParsingElement == "StopNo"){
//                if (!busStopID.contains(foundedChar)){
//                    busStopID.append(foundedChar)
//                }
            } else if (currentParsingElement == "ExpectedCountdown"){
                if (Int(foundedChar)! >= 0){
                    arrivals.append(foundedChar)
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        //while parsing, update currentParsingElement so we can keep track of parsing progress.
        currentParsingElement = elementName
    }
    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async {
            // this is ran upon reaching the end of the XML file
            // we print the result
            print("Finished")
            if (self.error != true){
//                print(self.busStopID)
                print("Finished")
                print(self.arrivals)
                self.updateUI()
            }
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("parseErrorOccurred: \(parseError)")
    }
}


