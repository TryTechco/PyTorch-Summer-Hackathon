//
//  PreviewViewController.swift
//  NBATikTok
//
//  Created by RandyLiu on 20/8/2020.
//  Copyright © 2020 h-tamader-team/RandyLiu. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class PreviewViewController: UIViewController {
    // Status
    private enum ProcessVideoStatus {
        case noVideo
        case recorded
        case uploading
        case uploaded
        case processing
        case processed
    }
    
    // Declare variables
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var statusLabel: UILabel!
    var playerLayer: AVPlayerLayer?
    public var videoURL: URL?
    private var editedVideoURL: URL?
    private var videoProcessStatus: ProcessVideoStatus = .noVideo
    private var spinnerView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change button style
        uploadButton.layer.cornerRadius = 10
        downloadButton.layer.cornerRadius = 10
        
        uploadButton.isHidden = false
        statusLabel.isHidden = true
        downloadButton.isHidden = true

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Play preview video and loop
        DispatchQueue.main.async {
            self.videoProcessStatus = .recorded
            let player = AVPlayer(url: self.videoURL!)
            
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (_) in
                        player.seek(to: CMTime.zero)
                        player.play()
            }
            
            self.playerLayer = AVPlayerLayer(player: player)
            self.playerLayer!.frame = self.previewView.bounds
            self.previewView!.layer.addSublayer(self.playerLayer!)
            player.play()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cleanup(outputFileURL: self.videoURL!)
        if(self.editedVideoURL != nil)
        {
            cleanup(outputFileURL: self.editedVideoURL!)
        }
    }
    
    func cleanup(outputFileURL: URL) {
        let path = outputFileURL.path
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Could not remove file at url: \(outputFileURL)")
            }
        }
    }
    
    let screenSize: CGRect = UIScreen.main.bounds
    let session = URLSession.shared
    
    // Upload video to database
    @IBAction func uploadVideo(_ sender: UIButton) {
        self.videoProcessStatus = .uploading
        
        // Change status style
        self.spinnerView = SpinnerView(frame: CGRect(x: screenSize.width/2 - 50, y: screenSize.height/2 - 50, width: 100, height: 100))
        self.view.addSubview(self.spinnerView!)
        self.uploadButton.isHidden = true
        self.statusLabel.isHidden = false
        self.statusLabel.text = "Uploading"
        self.statusLabel.frame = CGRect(x: screenSize.width/2 - 50, y: screenSize.height/2 - 50, width: 100, height: 100)
        
        self.downloadButton.isHidden = false
        
        // Upload Session
        DispatchQueue.main.async {
            let request = NSURLRequest(url: NSURL(string: "http://example.com")! as URL)

            let uploadTask = self.session.uploadTask(with: request as URLRequest, fromFile: self.videoURL!,
                                                           completionHandler: { (responseData, response, error) in

                                                            // Check on some response headers (if it's HTTP)
                                                            if let httpResponse = response as? HTTPURLResponse {
                                                                switch httpResponse.statusCode {
                                                                case 200..<300:
                                                                    print("Success")
                                                                case 400..<500:
                                                                    print("Request error")
                                                                case 500..<600:
                                                                    print("Server error")
                                                                case let otherCode:
                                                                    print("Other code: \(otherCode)")
                                                                }
                                                            }

                                                            // Do something with the response data
                                                            if let
                                                                responseData = responseData,
                                                                let responseString = String(data: responseData, encoding: String.Encoding.utf8) {
                                                                print("Server Response:")
                                                                print(responseString)
                                                            }

                                                            // Do something with the error
                                                            if let error = error {
                                                                print(error.localizedDescription)
                                                            }
            })

            uploadTask.resume()
        }

        // Get video edit status
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.GetEditStatus), userInfo: nil, repeats: true)
        }
        
    }
    
    var timer = Timer()
    
    struct StatusResponce: Codable {
      let foo: Bool
    }
    
    @objc func GetEditStatus() {
        DispatchQueue.main.async {
            let request = URLRequest(url: NSURL(string: "http://example.com")! as URL)
            let getTask = self.session.dataTask(with: request, completionHandler: { (data, response, error) in
                                                            
                                                            // Check on some response headers (if it's HTTP)
                                                            if let httpResponse = response as? HTTPURLResponse {
                                                                switch httpResponse.statusCode {
                                                                case 200..<300:
                                                                    print("Success")
                                                                case 400..<500:
                                                                    print("Request error")
                                                                case 500..<600:
                                                                    print("Server error")
                                                                case let otherCode:
                                                                    print("Other code: \(otherCode)")
                                                                }
                                                            }
                                                            
                                                            // Do something with the response data
                                                            if let data = data {
                                                               do {
                                                                  let res = try JSONDecoder().decode(StatusResponce.self, from: data)
                                                                if(res.foo)
                                                                {
                                                                    DispatchQueue.main.async {
                                                                        let downloadRequest = URLRequest(url: NSURL(string: "http://example.com")! as URL)
                                                                        let downloadTask = self.session.downloadTask(with: downloadRequest as URLRequest,
                                                                                                                       completionHandler: { (responceURL, response, error) in

                                                                                                                        // Check on some response headers (if it's HTTP)
                                                                                                                        if let httpResponse = response as? HTTPURLResponse {
                                                                                                                            switch httpResponse.statusCode {
                                                                                                                            case 200..<300:
                                                                                                                                print("Success")
                                                                                                                            case 400..<500:
                                                                                                                                print("Request error")
                                                                                                                            case 500..<600:
                                                                                                                                print("Server error")
                                                                                                                            case let otherCode:
                                                                                                                                print("Other code: \(otherCode)")
                                                                                                                            }
                                                                                                                        }

                                                                                                                        // Do something with the response data
                                                                                                                        self.editedVideoURL = responceURL

                                                                                                                        // Do something with the error
                                                                                                                        if let error = error {
                                                                                                                            print(error.localizedDescription)
                                                                                                                        }
                                                                        })

                                                                        downloadTask.resume()
                                                                        
                                                                        //Change status
                                                                        self.videoProcessStatus = .processed
                                                                        self.statusLabel.isHidden = true
                                                                        self.downloadButton.isHidden = false
                                                                        

                                                                        DispatchQueue.main.async {
                                                                            for view in self.view.subviews {
                                                                                if(view is SpinnerView)
                                                                                {
                                                                                    view.removeFromSuperview()
                                                                                }
                                                                            }
                                                                        }
                                                                        
                                                                        self.timer.invalidate()
                                                                    }
                                                                }
                                                               } catch let error {
                                                                  print(error)
                                                               }
                                                            }
                                                            
                                                            // Do something with the error
                                                            if let error = error {
                                                                print(error.localizedDescription)
                                                            }
            })
            
            getTask.resume()
            
        }
    }
    
    @IBAction func DownloadVideo(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges({
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .video, fileURL: self.editedVideoURL!, options: options)
        }, completionHandler: { success, error in
            if !success {
                print("AVCam couldn't save the movie to your photo library: \(String(describing: error))")
            }
            // clean when saved successfully
            self.cleanup(outputFileURL: self.editedVideoURL!)
        }
        )
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
