//
//  FirebaseRegister.swift
//  Spot
//
//  Created by Leon Böttger on 10.12.24.
//

import LUI
import SwiftUI

struct FirebaseRegisterView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var finished = false

    var body: some View {
        PermissionView(title: "Setup", symbol: "icloud", subtitle: "Preparing your account... Please wait and make sure that you have internet access.", continueLabel: "", canSkip: false, animateMockup: true) {
            IntroductionDoneView()
        } nextViewSkip: {
            IntroductionDoneView()
        } frontMockup: {
            AppMockupFrontView()
        } backMockup: {
            SymbolMockupView(symbol: "globe")
        }
        .onAppear {
            PushReceiver.sharedInstance.registerForLogin {
                runAfter(seconds: 0.5) {
                    finished = true
                }
            }
        }
        .modifier(LinkTo(content: { GoogleEmailView() }, isActive: $finished))
    }
}
