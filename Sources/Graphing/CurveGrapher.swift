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

struct Graph_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ValueAnimationGraphView_Previews.previews
            EasingFunctionGraphView_Previews.previews
        }
    }

}

#endif
