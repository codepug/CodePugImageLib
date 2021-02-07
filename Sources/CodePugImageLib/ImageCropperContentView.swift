//
//  ImageCropperContentView.swift
//  SwiftUI Image Cropper by CodePug
//
//  Created by CodePug.com on 2/6/21.
//

import SwiftUI

struct ImageCropperContentView: View {
    let myColor = Color(UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.7))

    @State var image: UIImage = UIImage(named: "pug-food")!

    @State private var position = CGSize.zero
    @GestureState private var positionDelta = CGSize.zero

    @State private var scale: CGFloat = 1.0
    @State private var scaleDelta: CGFloat = 1.0
    @State private var scalePositionDelta = CGSize.zero
    @State private var screenSize = CGSize.zero
    var maxScale = 20 // TODO - Add support
    var minScale = 0.11 // TODO - Add support

    // Needs scale, image size,
    func restrictChangeInWidth(currentOffset: CGSize, translation: CGSize, newScale: CGFloat) -> CGFloat {
        return restrictChange(currentOffset: currentOffset.width,
                              translation: translation.width,
                              adjustedPosition: self.scalePositionDelta.width,
                              screenSizeLength: screenSize.width,
                              imageLength: image.size.width,
                              newScale: newScale)
    }

    // updating get current change of position, end: get to where current position is
    func restrictChangeInHeight(currentOffset: CGSize, translation: CGSize, newScale: CGFloat) -> CGFloat {
        return restrictChange(currentOffset: currentOffset.height,
                              translation: translation.height,
                              adjustedPosition: self.scalePositionDelta.height,
                              screenSizeLength: screenSize.height,
                              imageLength: image.size.height,
                              newScale: newScale)
    }

    func restrictChange(currentOffset: CGFloat, translation: CGFloat, adjustedPosition: CGFloat, screenSizeLength: CGFloat, imageLength: CGFloat, newScale: CGFloat) -> CGFloat {
        let imageSize = (imageLength * pow(scale * newScale, 1))
        let halfBox = boxSize / 2
        let halfHeight = screenSizeLength / 2

        let currentPosition = currentOffset + translation - adjustedPosition
        if currentPosition > halfHeight - halfBox {
            return halfHeight - halfBox - currentOffset
        } else if currentPosition < halfHeight + halfBox - imageSize {
            return halfHeight + halfBox - imageSize - currentOffset
        }
        return translation
    }

    var body: some View {
        let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
              .makeConnectable()
              .autoconnect()
        
        let gestureDrag = DragGesture()
            .updating($positionDelta, body: { (value, state, transaction) in
                state.height = restrictChangeInHeight(currentOffset: self.position, translation: value.translation, newScale: scaleDelta)
                state.width = restrictChangeInWidth(currentOffset: self.position, translation: value.translation, newScale: scaleDelta)
            })
            .onEnded({ (value) in
                self.position.height += restrictChangeInHeight(currentOffset: self.position, translation: value.translation, newScale: scaleDelta)
                self.position.width += restrictChangeInWidth(currentOffset: self.position, translation: value.translation, newScale: scaleDelta)
            }) // On end - onend

        let magnifyGesture = MagnificationGesture()
            .onChanged({ (value1) in // Todo handle rortation!
                scaleDelta = value1
                let box = boxSize
                let newHeight1 = image.size.height * scaleDelta * scale
      
                // Ensure not smaller than available height
                if newHeight1 < box { // Image can never be smaller than the box
                    scaleDelta = (box / ((scale ) * image.size.height))
                }

                // Ensure not smaller than available width
                let newWidth1 = image.size.width * scaleDelta * scale
                if newWidth1 < box {
                    scaleDelta = (box / ((scale ) * image.size.height))
                }
                
                // Expand from center of image
                let height = image.size.height * scale
                let newHeight = image.size.height * scaleDelta * scale
                let width = image.size.width * scale
                let newWidth = image.size.width * scaleDelta * scale
                self.scalePositionDelta.width = ((newWidth - width) / 2)
                self.scalePositionDelta.height = ((newHeight - height) / 2)
  
                let leftBox:CGFloat = screenSize.width / 2 - box / 2
                let leftSideOfImage =  self.position.width - self.scalePositionDelta.width
                if (leftSideOfImage > leftBox) {
                    self.scalePositionDelta.width = leftBox - self.position.width
                     print("#LEFT######################")
                }

                let rightBox = screenSize.width / 2 + box / 2
                let rightSideOfImage =  self.position.width - self.scalePositionDelta.width + newWidth
                if (rightSideOfImage < rightBox) {
                    self.scalePositionDelta.width =  self.position.width - (rightBox - newWidth)
                     print("*RIGHT**********************")
                }
               
                let topBox:CGFloat = screenSize.height / 2 - box / 2
                let topSideOfImage =  self.position.height - self.scalePositionDelta.height
                if (topSideOfImage > topBox) {
                    self.scalePositionDelta.height = self.position.height - topBox
                    print("-TOP---------------------- \(topBox) == \(self.position.height - scalePositionDelta.height )")
                }

                let bottomBox = screenSize.height / 2 + box / 2
                let bottomSideOfImage =  self.position.height - self.scalePositionDelta.height + newHeight
                if (bottomSideOfImage < bottomBox) {
                    self.scalePositionDelta.height =  self.position.height - (bottomBox - newHeight)
                     print("+BOTTOM+++++++++++++++++++++++\(bottomBox - newHeight) == \(self.position.height - scalePositionDelta.height )")
                }
                print("Adjusted is: \(scalePositionDelta) \(position) \(positionDelta)")
            })
            .onEnded { (_) in
                print("Scale: \(scale) scale1: \(scaleDelta) value:\(scaleDelta)")
                scale = scaleDelta * scale
                scaleDelta = 1

                self.position.width -= self.scalePositionDelta.width
                self.position.height -= self.scalePositionDelta.height
                self.scalePositionDelta = CGSize.zero
            }
        return
            GeometryReader { geo in
                ZStack() {
                    Rectangle().foregroundColor(.black).ignoresSafeArea()

                    GeometryReader { geo in
                        Image("pug-food")
                            .resizable()
                            .frame(width: image.size.width * scale * scaleDelta, height: image.size.height * scale * scaleDelta)
                            .border(Color.red)
                            .offset(x: position.width + positionDelta.width - self.scalePositionDelta.width, y: position.height + positionDelta.height - self.scalePositionDelta.height)
                            .gesture(gestureDrag)
                            .gesture(magnifyGesture)
                            .onReceive(orientationChanged) { _ in // Reposition within boundaries
                                
                                guard let scene = UIApplication.shared.windows.first?.windowScene else { return }
                                                 let isPortrait = scene.interfaceOrientation.isPortrait
                                
                                let minPt = min(geo.size.width, geo.size.height)
                                let maxPt = max(geo.size.width, geo.size.height)
                                screenSize.height = isPortrait ? maxPt : minPt
                                screenSize.width = isPortrait ? minPt : maxPt

                                self.position.height += restrictChangeInHeight(currentOffset: self.position, translation: positionDelta, newScale: scaleDelta)
                                self.position.width += restrictChangeInWidth(currentOffset: self.position, translation: positionDelta, newScale: scaleDelta)
                            }
                            .onAppear() { // Center
                                screenSize = geo.size
                                position.width = (geo.size.width -  image.size.width) / 2
                                position.height = (geo.size.height -  image.size.height) / 2
                            }
                    }

                    Rectangle()
                        .stroke(Color.gray)
                        .frame(width: max(0, boxSize), height: max(0, boxSize))

                    Rectangle()
                        .fill(myColor)
                        .clipShape(ShapeWithHole(width: boxSize, height: boxSize))    // clips or masks the view
                        .contentShape(ShapeWithHole(width: boxSize, height: boxSize)) // needed for hit-testing

                    VStack() {
                        Spacer()
                        HStack() {
                            Button("Cancel") {

                            }
                            .padding(32)
                            .foregroundColor(Color.gray)
                            Spacer()
                            Button("Apply") {
                                let imageSize = image.size.height * scaleDelta * scale
                                let halfHeight = screenSize.height / 2

                                self.scalePositionDelta.height = 0
                                self.position.height = halfHeight + (boxSize / 2) - imageSize
                                print("done")
                            }

                            .padding(32)
                            .foregroundColor(Color.white)
                        }
                    }
                }.ignoresSafeArea()  // End ZStack
            } // End geometryReader
    } // End function
    
    var boxSize: CGFloat {
        return min(screenSize.width - 32, screenSize.height - 32);
    }
} // End struct

struct ShapeWithHole: Shape {
    var width: CGFloat
    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect)
        let holeRect = CGRect(x: rect.width/2 - (width / 2),
                           y: rect.height/2 - (height / 2), width: width, height: height)
        let cgPath = Rectangle().path(in: holeRect).cgPath
        let reversedCGPath = UIBezierPath(cgPath: cgPath)
            .reversing()
            .cgPath
        path.addPath(Path(reversedCGPath))
        return path
    }
}

