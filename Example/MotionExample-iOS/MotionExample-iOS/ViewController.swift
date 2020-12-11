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
                NavigationLink(destination: BouncyView().navigationTitle("Bouncy Demo")) {
                    Text("Bouncy Demo")
                }

                NavigationLink(destination: DraggableView().navigationTitle("Dragging Demo")) {
                    Text("Dragging Demo")
                }
            }
            .navigationBarTitle("Motion Demos", displayMode: .large)
        }
    }

}

class ViewController: UIHostingController<RootView> {

    init() {
        super.init(rootView: RootView())
    }
    
    @objc required dynamic convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }
    
}

struct RootView_Previews: PreviewProvider {

    static var previews: some View {
        RootView()
    }

}
