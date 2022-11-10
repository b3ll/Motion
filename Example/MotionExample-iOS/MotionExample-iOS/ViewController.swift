//
//  ViewController.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 12/11/20.
//

import Foundation
import UIKit
import SwiftUI

struct RootView: View {

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: BouncyDemo().navigationTitle("Bouncy Demo")) {
                    Text("Bouncy Demo")
                }
                NavigationLink(destination: DraggableDemo().navigationTitle("Dragging Demo")) {
                    Text("Dragging Demo")
                }
                NavigationLink(destination: ScrollViewDemo().navigationTitle("ScrollView Demo")) {
                    Text("ScrollView Demo")
                }
                NavigationLink(destination: SwiftUIDemoView().navigationTitle("SwiftUI Demo")) {
                    Text("SwiftUI Demo")
                }
            }
            .navigationBarTitle("Motion Demos", displayMode: .large)
        }
    }

}

class ViewController: UIHostingController<RootView> {

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        super.init(rootView: RootView())
    }
    
}

struct RootView_Previews: PreviewProvider {

    static var previews: some View {
        RootView()
    }

}
