//
//  AnalysisViewController.swift
//  SpirometerApp
//
//  Created by Varun Kumar Viswanth on 1/12/17.
//  Copyright © 2017 Varun Kumar Viswanth. All rights reserved.
//

import Foundation

import AVFoundation

import UIKit

import AudioKit

import Surge

class AnalysisViewController: UIViewController {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var showDataLabel: UILabel!
    
    var player:AKAudioPlayer?
    var plotView:AKView?
    var aFile = "dean-2-30-421.wav"
    var counter = 0
    
    override func didMove(toParentViewController parent: UIViewController?) {
        print("hello")
        if player == nil {
            //setupNodePlayer()
            //getfft()
//            setupAudioPlayer()
//            plotAudio()
            
            do {
                print(aFile)
                let file = try AKAudioFile(readFileName: aFile, baseDir: .documents)

//                let path = Bundle.main.path(forResource: "sine", ofType: "wav")
//                let file = try AKAudioFile(forReading: URL(string: path!)!)

                player = try AKAudioPlayer(file: file)
                
                player?.looping = true
                let variSpeed = AKVariSpeed(player!)
                variSpeed.rate = 0.3
                AudioKit.output = variSpeed
                AudioKit.start()
                player?.play()
                let rect = CGRect(x:0, y:0, width:500, height:200)
                
                let plot = AKNodeFFTPlot.init(player!, frame: rect)
                
                self.view.addSubview(plot)
                //plot.fft(EZAudioFFT(), updatedWithFFTData: UnsafeMutablePointer<Float>(), bufferSize: vDSP_Length())
                //plotAudio()
            } catch {
                print("Failed to load  wav file to AKAudioFile")
            }

            //plotAudio()
            
        } else {
            if (player?.isPlaying)! {
                player?.stop()
                player = nil
                plotView?.removeFromSuperview()
                AudioKit.stop()
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.alpha = 0;
        
        
    }
    
    @IBAction func analyzeButtonPressed(_ sender: Any) {
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1;
        let rawData = getRawDataFromDocuments(filename: aFile)
//        let path = Bundle.main.path(forResource: "breath-gasp-01", ofType: "wav")
//        let rawData = getRawDataFromURL(url: URL(string: path!)!)
//        print("Surge")
//        print(Surge.fft(rawData))
        print(stft(inputData: rawData, windowSize: 22050, overlap: 2))
        
    }
    
    func stft(inputData: [Float], windowSize: Int, overlap: Int) -> [Float] {
        var outputData = [Float]()
        let hop = windowSize / overlap
        let windows = Int(inputData.count - windowSize)
        
        var currentSample = 0;
        while currentSample < windows {
            
            let stop = currentSample + windowSize
            var sample:ArraySlice<Float> = inputData[currentSample ..< stop]
            let newSampleData = sample.enumerated().map({(index, element) in
                let num:Float = 2 * Float.pi * index / inputData.count
                return 0.54 - 0.46 * cos(num)
            })
            outputData.append(contentsOf: fftSlices(sample))
            currentSample += hop
        }
        return outputData
    }
    
    public func hamming(input: Float) -> Float {
        var output = input
        return output
    }
    
    public func fftSlices(_ input: ArraySlice<Float>) -> [Float] {
        var real = [Float](input)
        var imaginary = [Float](repeating: 0.0, count: input.count)
        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imaginary)
        
        let length = vDSP_Length(floor(log2(Float(input.count))))
        let radix = FFTRadix(kFFTRadix2)
        let weights = vDSP_create_fftsetup(length, radix)
        vDSP_fft_zip(weights!, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0.0, count: input.count)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(input.count))
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: input.count)
        vDSP_vsmul(sqrt(magnitudes), 1, [2.0 / Float(input.count)], &normalizedMagnitudes, 1, vDSP_Length(input.count))
        
        vDSP_destroy_fftsetup(weights)
        
        return normalizedMagnitudes
    }
    
    func getRawDataFromDocuments(filename: String) -> [Float] {
        
        var floatArray:[Float] = [Float]()
        
        let urlsInDocumentsDirectory = getDocumentsDirectory()
        
        let filesInDocsDir = urlsInDocumentsDirectory.map{ $0.deletingPathExtension().lastPathComponent }
        
        var results = ""
        var index = 0
        var url:URL? = URL(fileURLWithPath: "")
        for file in filesInDocsDir {
            let fullFile = file + ".wav"
            if fullFile  == filename {
                url = urlsInDocumentsDirectory[index]
            }
            index += 1
        }
        
        floatArray = getRawDataFromURL(url: url!)
        
        
        return floatArray
    }
    
    func getRawDataFromURL(url: URL) ->[Float] {
        var file = AVAudioFile()
        if url.relativeString != "./" {
            print(url.relativeString)
            file = try! AVAudioFile.init(forReading: url)
        } else {
            print("use default url")
            let temp = try! AKAudioFile(readFileName: aFile, baseDir: .documents)
            file = try! AVAudioFile(forReading: temp.url)
        }
        
        print(file.fileFormat.sampleRate)
            
            
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
            
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44100)
        print(file.framePosition)
        try! file.read(into: buf)
        
        // this makes a copy, you might not want that
        print(buf.frameCapacity)
        print(buf.frameLength)
        print("\n" + String(describing: buf))
        print("Error")
        return Array(UnsafeBufferPointer(start: buf.floatChannelData?[0], count:Int(buf.frameLength)))
        //print("floatArray \(floatArray)\n")
            
        return [Float]()
    }
    
    func plotAudio() {
        let frame = CGRect(x:0, y:100, width:440, height:200)
        let plot = AKRollingOutputPlot(frame: frame)
        
        plot.plotType = .rolling
        plot.backgroundColor = AKColor.white
        plot.color = AKColor.green
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.shouldCenterYAxis = true
        
        plotView = AKView(frame:frame)
        plotView?.addSubview(plot)
        self.view.addSubview(plotView!)
    }
    
    func getFft() {
        
    }
    
    
    // This function gets the URL for the documents directory.
    func getDocumentsDirectory() -> [URL] {
        // Get the document directory url
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var results:[URL] = [documentsUrl]
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            //print(directoryContents)
            let wavFiles = directoryContents.filter{ $0.pathExtension == "wav" }
            results = wavFiles
            return results
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return results
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
