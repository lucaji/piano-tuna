//
//  SpectralViewController.swift
//  TempiHarness
//
//  Created by John Scalo on 1/7/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit
import AVFoundation

class SpectralViewController: UIViewController {
    
    var audioInput: TempiAudioInput!
    var fftSpectrumView: FFTSpectrumView!
    var spectrumView1: HistogramView!
    var spectrumView2: HistogramView!
    var fftLoader: FFTLoader!
    
    var beatingDetector: BeatingDetector!
    var beatingDetectorDebug1: Array<Double>!
    var beatingDetectorDebug2: Array<Double>!
    var beatingPeaks: [(frequency:Double, magnitude: Double)]!
    
    let uiFps = FrequencyMeasure()

    // PARAMETERS
    // best frequency measurements precision direct fft: 44100@8192samples (5Hz FFT)
    // best frequency measurements precision 0.03Hz wavelets: 16000@2048
    let fftSampleRate: Double = 16000.0 // Limit bandwidth to 8kHz as Piano's highest note is just over 4kHz
    let fftSize: Int = 2048 // 2048 equals to 7.8125Hz/bin
    let fftOverlapRatio: Double = 0.0
    
    var drawTimedBoolean = TimedBoolean(time: 1000/5)
    var noteSession = NoteSession()
    
    var waveletSearches: Array<(frequency: Double, level: Double, measuredFrequency: Double, debug: [Double])>!
    var beatingsFFT: TempiFFT!
    var searchAvg = MovingAverage(numberOfSamples: 12)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //draw fft spectrum
        self.fftSpectrumView = FFTSpectrumView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/3-20))
        self.fftSpectrumView.backgroundColor = UIColor.black
        self.fftSpectrumView.title = "Raw spectrum"
        // self.fftSpectrumView.zoomMinDB =
        // self.fftSpectrumView.zoomMaxDB =
        self.fftSpectrumView.zoomFromFrequency = 0
        self.fftSpectrumView.zoomToFrequency = 2000
        
        //draw spectrum view 1
        self.spectrumView1 = HistogramView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/3-20))
        self.spectrumView1.backgroundColor = UIColor.black
        self.spectrumView1.barColor = UIColor.red.cgColor
        // self.spectrumView1.minX = 0
        // self.spectrumView1.maxX = 512
        // self.spectrumView1.minY = 0.0
        // self.spectrumView1.maxY = 50
        
        //draw hps spectrum
        self.spectrumView2 = HistogramView(frame: CGRect(x:0,y:0,width:self.view.bounds.width,height:self.view.bounds.height/3-20))
        self.spectrumView2.backgroundColor = UIColor.black
        self.spectrumView2.barColor = UIColor.red.cgColor
        self.spectrumView2.minX = 0
        // self.spectrumView2.maxX = 512
        self.spectrumView2.minY = 0.0
        // self.spectrumView2.maxY = 30
        
        //prepare main vertical layout
        let verticalLayout = VerticalLayoutView(width:view.bounds.width)
        verticalLayout.addSubview(fftSpectrumView)
        verticalLayout.addSubview(spectrumView1)
        verticalLayout.addSubview(spectrumView2)
        self.view.addSubview(verticalLayout)
        
        //initialize sound analysis
        self.drawTimedBoolean.reset()
        
        self.fftLoader = FFTLoader(sampleRate: self.fftSampleRate, samplesSize: fftSize, overlapRatio: fftOverlapRatio)
        self.beatingDetector = BeatingDetector(baseFrequency: 440.0, signalSampleRate: self.fftSampleRate, fftSize: 256)
        
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
            let signalSamples = samples.map({ (element) -> Double in
                return Double(element)
            })
            
            let fft = self.fftLoader.addSamples(samples: signalSamples)
            if fft != nil {
                
                // NOTE SESSION
                self.noteSession.step(fft: fft!)

                // WAVELET FREQUENCY SEARCH
                self.waveletSearches = Array<(frequency: Double, level: Double, measuredFrequency: Double, debug: [Double])>()
                var s = WaveletUtils.frequencyMatchLevel(signal: self.fftLoader.lastBufferSamples, sampleRate: self.fftSampleRate, frequency: 440.0)
                if s != nil {
                    self.waveletSearches.append(s!)
                }
                s = WaveletUtils.frequencyMatchLevel(signal: self.fftLoader.lastBufferSamples, sampleRate: self.fftSampleRate, frequency: 442.0)
                if s != nil {
                    self.waveletSearches.append(s!)
                }
                s = WaveletUtils.frequencyMatchLevel(signal: self.fftLoader.lastBufferSamples, sampleRate: self.fftSampleRate, frequency: 444.0)
                if s != nil {
                    self.waveletSearches.append(s!)
                }
                if self.waveletSearches.count>0 {
                    self.searchAvg.addSample(value: self.waveletSearches[0].measuredFrequency)
                }
            }
            
            // FREQUENCY BEATINGS DETECTION
            if self.fftLoader.lastBufferSamples != nil {
                // self.beatingsResult = WaveletUtils.beatFrequenciesDetection(baseFrequency: 440.0, signal: self.fftLoader.lastBufferSamples, sampleRate: self.fftSampleRate)
                let br = self.beatingDetector.addSamples(samples: signalSamples)
                if br != nil {
                    self.beatingsFFT = br
                }
                
                // DEBUGGING ONLY
                // if self.beatingDetector.lastConvoluted != nil {
                //     self.beatingDetectorDebug1 = self.beatingDetector.lastConvoluted.map({ (elem) -> Double in
                //     return elem })
                // }
                self.beatingDetectorDebug1 = self.beatingDetector.fftLoader.buffer.map({ (elem) -> Double in
                    return elem
                })
                // if self.beatingDetector.lastPeaks != nil {
                //      self.beatingDetectorDebug2 = self.beatingDetector.lastPeaks.map({ (elem) -> Double in
                //      return elem })
                // }
                if self.beatingsFFT != nil {
                    self.beatingDetectorDebug2 = self.beatingsFFT.spectrum()
                    self.beatingDetectorDebug2[0] = 0

                    self.beatingPeaks = MathUtils.calculateFrequencyPeaks(spectrum: self.beatingsFFT.spectrum()!, binWidth: self.beatingsFFT.bandwidth)
                    self.beatingPeaks.sort(by: { (elem1, elem2) -> Bool in
                        return elem1.magnitude<elem2.magnitude
                    })
                }
            }
            if self.drawTimedBoolean.checkTrue() {
                self.updateUI(noteSession: self.noteSession)
            }
        }
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback,
                                     sampleRate: Float(fftSampleRate),
                                     numberOfChannels: 1)
        audioInput.startRecording()
    }

    
    func updateUI(noteSession: NoteSession) {
        // Dispatch to main thread
        DispatchQueue.main.async {
            self.uiFps.tick()
            var labelFrequencies = Array<(text: String, frequency: Double, y: Float)>()
            var annotations = Array<(text: String, x: Float, y: Float)>()
            annotations.append((text: "Phase \(noteSession.phase)", x: 100, y: 10))
            annotations.append((text: "UI \(Int(self.uiFps.getFrequency()))Hz   FFT \(Int(self.fftLoader.forwardFrequency.getFrequency()))Hz", x: 400, y: 25))
            if noteSession.overallMagnitude.getAverage() != nil {
                annotations.append((text: "Level \(String(format:"%.3f",noteSession.overallMagnitude.getAverage()))", x: 100, y: 25))
            }
            if noteSession.detectedNote != nil {
                annotations.append((text: "Fundamental \(noteSession.detectedNote.name)Hz - [\(noteSession.detectedNote.name) \(noteSession.detectedNote.noteNumber) \(noteSession.detectedNote.noteFrequency)Hz]", x: 100, y: 40))
            }
            if noteSession.zoomedTonalPeaks != nil {
                annotations.append((text: "Current frequencies \(String(describing: noteSession.zoomedTonalPeaks))", x: 100, y: 55))
                var c = 0
                for peak in noteSession.zoomedTonalPeaks {
                    labelFrequencies.append((text: "^", frequency: peak.frequency, y: 20))
                    let note = NoteIntervalCalculator.frequencyToNoteEqualTemperament(peak.frequency)
                    annotations.append((text: "\(note.name) \(noteSession.detectedNote.noteNumber) \(String(format:"%.2f",note.cents))c \(String(format:"%.2f",peak.frequency))Hz (\(noteSession.detectedNote.noteFrequency))Hz", x: 100, y: 70 + Float(c)))
                    c = c + 15
                    if c>30 {
                        break
                    }
                }
            }
            self.fftSpectrumView.annotations = annotations
            self.fftSpectrumView.annotationsFrequency = labelFrequencies
            
            // print("zoomFrequencyFrom \(noteSession.zoomFrequencyFrom) zoomFrequencyTo \(noteSession.zoomFrequencyTo)")
            
            self.fftSpectrumView.zoomFromFrequency = noteSession.zoomFrequencyFrom
            self.fftSpectrumView.zoomToFrequency = noteSession.zoomFrequencyTo
            
            self.spectrumView1.annotations = Array<(text:String, x:Float, y:Float)>()
            self.spectrumView2.annotations = Array<(text:String, x:Float, y:Float)>()

            if noteSession.zoomedTonalPeaks != nil && noteSession.zoomedTonalPeaks!.count>0 {
                let peak = noteSession.zoomedTonalPeaks[0]
                let note = NoteIntervalCalculator.frequencyToNoteEqualTemperament(peak.frequency)
                // print("detection=\(note.name) \(String(format: "%.1f", note.cents))¢ \(peak.frequency)Hz")
                self.spectrumView2.annotations.append((text:"\(note.name) \(String(format: "%.1f", note.cents))¢", x:100, y:10))
    
                let harmonics = Inharmonicity.calculateInharmonicity(fft: noteSession.fft, fundamentalFrequency: peak.frequency)
                for i in 0..<harmonics.count {
                    let harm = harmonics[i]
                    if harm.measuredFrequency>0 {
                        self.spectrumView2.annotations.append((text:"\(harm.number): \(harm.idealFrequency) (\(harm.measuredFrequency)) \(String(format:"%.2f", harm.inharmonicityIndex*100))%", x: 300, y: Float(20+(i*20))))
                    }
                }
            }
            self.fftSpectrumView.fft = noteSession.fft

            var c = 0
            if self.waveletSearches != nil {
                let avgFreq = self.searchAvg.getAverage()
                
                let wss = self.waveletSearches.sorted(by: { (elem1, elem2) -> Bool in
                    return abs(elem1.level) > abs(elem2.level)
                })
                // for ws in wss {
                //     self.spectrumView2.annotations.append((text:"\(String(format:"%.3f",ws.frequency))Hz=> \(String(format:"%.4f", ws.level)) \(String(format:"%.3f", ws.measuredFrequency)) err=\((avgFreq != nil ? "\(avgFreq!-ws.frequency)" : "-"))Hz", x:100, y:60+Float(c)))
                //      if c == 0 {
                //           self.spectrumView2.data = ws.debug
                //      }
                //      c += 15
                // }
                if avgFreq != nil {
                    self.spectrumView2.annotations.append((text:"\(String(format:"%.4f",avgFreq!))Hz", x:100, y:60+Float(c)))
                    c += 15
                    
                    if self.beatingsFFT != nil {
                        self.spectrumView1.data = self.beatingDetectorDebug1
                        self.spectrumView2.data = self.beatingDetectorDebug2
                        // self.spectrumView2.data = self.beatingsFFT.magnitudes

                        self.spectrumView2.annotations.append((text: "#", x: 250, y: 30))
                        self.spectrumView2.annotations.append((text: "\(String(format:"%.2f", avgFreq!))Hz", x: 140, y: 45))

                        if self.beatingPeaks != nil {
                            var i = 1
                            for peak in self.beatingPeaks {
                                self.spectrumView2.annotations.append((text: ">> \(String(format:"%.2f", avgFreq! + peak.frequency))Hz", x: 100, y: 60 + Float(c)))
                                self.spectrumView2.annotations.append((text: "\(i)", x: 250.0 + Float(peak.frequency*5), y: 30))
                                self.spectrumView2.annotations.append((text: "\(i)", x: 250.0 - Float(peak.frequency*5), y: 30))
                                c = c + 15
                                i += 1
                                if i>2 {
                                    break
                                }
                            }
                        }
                        
                    }

                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        NSLog("*** didReceiveMemoryWarning!")
        super.didReceiveMemoryWarning()
    }
}

