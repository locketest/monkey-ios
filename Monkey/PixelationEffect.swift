//
//  BlurinessEffect.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/28/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class PixelationEffect: Effect {
    static let effectName = "pixelation"
    let filterContext = CIContext()
    let pixelationFilter = CIFilter(name: "CIPixellate")!
    let scaleFilter = CIFilter(name: "CIAffineTransform")!

    var effectName: String {
        get {
            return PixelationEffect.effectName
        }
    }
    
    let pixelationAmount: Int
    init(pixelationAmount: Int) {
        self.pixelationAmount = pixelationAmount
    }
    required init?(encoded: String) {
        guard let data = encoded.asJSON as? [String:Any] else {
            return nil
        }
        self.pixelationAmount = data["pixelationAmount"] as? Int ?? 0
    }
    var encoded: String {
        return [
            "pixelationAmount":self.pixelationAmount
            ].toJSON
    }
    func process(frame: OTVideoFrame) {
        guard let planes = frame.planes else {
            print("Error: Frame missing planes.")
            return
        }
        guard let format = frame.format else {
            print("Error: Frame missing format.")
            return
        }
        
        let imageWidth = Int(format.imageWidth)
        let imageHeight = Int(format.imageHeight)
        
        let yDataPointer = planes.pointer(at: 0)?.assumingMemoryBound(to: UInt8.self)
        let uDataPointer = planes.pointer(at: 1)?.assumingMemoryBound(to: UInt8.self)
        let vDataPointer = planes.pointer(at: 2)?.assumingMemoryBound(to: UInt8.self)
        
        let yData = UnsafeMutableBufferPointer(start: yDataPointer, count: imageWidth * imageHeight)
        let uData = UnsafeMutableBufferPointer(start: uDataPointer, count: yData.count / 4)
        let vData = UnsafeMutableBufferPointer(start: vDataPointer, count: uData.count)
        
        guard let nvDataPointer = malloc(imageWidth * imageHeight * 3 / 2) else {
            print("Error: Could not allocate memory for conversion to NV12 format.")
            return
        }
        
        memcpy(nvDataPointer, yDataPointer, yData.count) // Copy y Data
        let nvData = UnsafeMutableBufferPointer(start: nvDataPointer.assumingMemoryBound(to: UInt8.self), count: yData.count + uData.count + vData.count)
        
        var uvLocation = yData.count
        for bit in 0..<uData.count {
            nvData[uvLocation] = uData[bit]
            nvData[uvLocation + 1] = vData[bit]
            uvLocation += 2
        }
        if self.pixelationAmount > 0 {
            //let squareWidth = self.pixelationAmount * 2 // Must always be an even number (to make squares).
            let pixelBufferAttributes = [
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ] as CFDictionary
            var pixelBuffer: CVPixelBuffer?
            
            let result = CVPixelBufferCreate(kCFAllocatorDefault,
                                                  imageWidth,
                                                  imageHeight,
                                                  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                                  pixelBufferAttributes,
                                                  &pixelBuffer)
            
            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            
            let yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
            memcpy(yDestPlane, nvDataPointer, yData.count)
            
            let uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)
            memcpy(uvDestPlane, nvDataPointer.advanced(by: yData.count), yData.count / 2)
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            
            
            guard result == kCVReturnSuccess else {
                print("Error: Failed to create pixel buffer.")
                return
            }
            let image = CIImage(cvPixelBuffer: pixelBuffer!, options: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                ])
            pixelationFilter.setValue(image, forKey: kCIInputImageKey)
            
            pixelationFilter.setValue(image.extent.size.width / CGFloat(self.pixelationAmount), forKey: kCIInputScaleKey)
            let translation = CGFloat(self.pixelationAmount) / 2
            let fullPixellatedImage = pixelationFilter.outputImage?.cropping(to: CGRect(x: translation, y: translation, width: CGFloat(imageWidth - self.pixelationAmount), height: CGFloat(imageHeight - self.pixelationAmount)))
            
            scaleFilter.setValue(fullPixellatedImage, forKey: kCIInputImageKey)
            let scale = CGFloat(imageWidth) / CGFloat(imageWidth - self.pixelationAmount)
            
            scaleFilter.setValue(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: -translation, y: -translation), forKey: kCIInputTransformKey)

            self.filterContext.render(scaleFilter.outputImage!, to: pixelBuffer!)

            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

            let finalYPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
            memcpy(yDataPointer, finalYPlane, yData.count)

            let finalUVPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)
            let finalUVData = UnsafeMutableBufferPointer(start: finalUVPlane!.assumingMemoryBound(to: UInt8.self), count: yData.count / 2)
            var finalPlanarLocation = 0
            for bit in stride(from: 0, to: finalUVData.count, by: 2) {
                uData[finalPlanarLocation] = finalUVData[bit]
                vData[finalPlanarLocation] = finalUVData[bit + 1]
                finalPlanarLocation += 1
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        free(nvDataPointer)
    }
}
