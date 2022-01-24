//
//  EasingFunctionGraphView.swift
//  
//
//  Created by Adam Bell on 8/28/20.
//

#if canImport(SwiftUI)

import Motion
import CoreGraphics
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
struct Graph_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ValueAnimationGraphView_Previews.previews
            EasingFunctionGraphView_Previews.previews
        }
    }

}

#endif
