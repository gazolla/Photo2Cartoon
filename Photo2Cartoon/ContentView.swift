//
//  ContentView.swift
//  Photo2Cartoon
//
//  Created by sebastiao Gazolla Costa Junior on 06/09/22.
//

import SwiftUI
import CoreML
import VideoToolbox

func testModel(buffer:CVImageBuffer)->animegan2face_paint_512_v2Output?{
    do{
        let config = MLModelConfiguration()
        let model = try animegan2face_paint_512_v2(configuration: config)
        let prediction = try model.prediction(input: buffer)
        return prediction
    } catch {
        
    }
    return nil
}

func pixelBufferFromImage(image: UIImage) -> CVPixelBuffer {
    let ciimage = CIImage(image: image)
    
    let scale:CGFloat = 512 / (ciimage?.extent.size.width)!
    print("scale \(scale)")
    
    
    let ciimageMini = ciimage!.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    //let cgimage = convertCIImageToCGImage(inputImage: ciimage!)
    let tmpcontext = CIContext(options: nil)
    let cgimage =  tmpcontext.createCGImage(ciimageMini, from: ciimageMini.extent)
    
    let cfnumPointer = UnsafeMutablePointer<UnsafeRawPointer>.allocate(capacity: 1)
    let cfnum = CFNumberCreate(kCFAllocatorDefault, .intType, cfnumPointer)
    let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey, kCVPixelBufferBytesPerRowAlignmentKey]
    let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, cfnum!]
    let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
    let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
    keysPointer.initialize(to: keys)
    valuesPointer.initialize(to: values)
    
    let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
    
    let width = cgimage!.width
    let height = cgimage!.height
    print("width \(width)  height:  \(height)")
    var pxbuffer: CVPixelBuffer?
    // if pxbuffer = nil, you will get status = -6661
    var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                     kCVPixelFormatType_32BGRA, options, &pxbuffer)
    status = CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
    
    let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer!);
    
    
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer!)
    let context = CGContext(data: bufferAddress,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: bytesperrow,
                            space: rgbColorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue);
    context?.concatenate(CGAffineTransform(rotationAngle: 0))
    context?.concatenate(__CGAffineTransformMake( 1, 0, 0, -1, 0, CGFloat(height) )) //Flip Vertical
    //        context?.concatenate(__CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGFloat(width), 0.0)) //Flip Horizontal
    
    
    context?.draw(cgimage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)));
    status = CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
    return pxbuffer!;
    
}



struct ContentView: View {
    @State private var isShowingImgPicker = false
    @State private var img = UIImage(named: "avatar")!
    @State private var resultImg:UIImage?
    var body: some View {
        VStack{
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .padding()
                .onTapGesture { isShowingImgPicker.toggle()}
            Spacer()
            Image(uiImage: resultImg ?? img)
                .resizable()
                .scaledToFit()
                .rotationEffect(Angle(degrees: 180))
                .padding()
        }
        .navigationTitle("Get Image")
        .sheet(isPresented: $isShowingImgPicker) {
            ImagePicker(image: $img)
        }
        .onChange(of: img) { newValue in
            
            let buffer = pixelBufferFromImage(image: newValue)
            if let draw = testModel(buffer: buffer) {
                resultImg = UIImage(pixelBuffer:draw.activation_out)
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        guard let cgImage = cgImage else {
            return nil
        }
        
        self.init(cgImage: cgImage)
    }
   
}
