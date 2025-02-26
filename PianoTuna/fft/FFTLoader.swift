//
//  StutzFFT.swift
//  PianoTuna
//
//  Created by Flavio de Oliveira Stutz on 3/21/18.
//  Copyright © 2018 StutzLab. All rights reserved.
//

import Foundation

/// This is the entrypoint for FFT analysis for input buffer accumulation and other tools over the resulting FFT matrix,
/// like averaging and linear regression for better stability
class FFTLoader {
    
    var buffer: CircularArray<Double>!
    
    var samplesSize: Int!
    var sampleRate: Double!
    var overlapRatio: Double!
    private var processedSamplesCount: Int = 0
    var lastBufferSamples: [Double]!
    
    let forwardFrequency = FrequencyMeasure()
    
    init(sampleRate: Double, samplesSize: Int, overlapRatio: Double = 0) {
        self.sampleRate = sampleRate
        self.samplesSize = samplesSize
        self.overlapRatio = overlapRatio
        self.buffer = CircularArray<Double>(maxSize: self.samplesSize)
        // print("samplesSize \(self.samplesSize) \(samplesSize) \(overlapRatio)")
    }
    
    func addSamples(samples: [Double]) -> TempiFFT! {
        for s in samples {
            self.buffer.append(s)
            self.processedSamplesCount = self.processedSamplesCount + 1
            if (self.buffer.count >= self.samplesSize) && (self.processedSamplesCount >= Int(Double(self.samplesSize)*(1-self.overlapRatio))) {
                self.lastBufferSamples = self.buffer.map({ (element) -> Double in
                    return element
                })
                let fft = TempiFFT(withSize: self.samplesSize, sampleRate: self.sampleRate)
                fft.windowType = TempiFFTWindowType.gaussian
                // print("buffer samples \(self.lastBufferSamples.count)")
                fft.fftForward(self.lastBufferSamples)
                forwardFrequency.tick()
                // self.buffer.removeAll(keepingCapacity: false)
                self.processedSamplesCount = 0
                return fft
            }
        }
        return nil
    }
    
}
