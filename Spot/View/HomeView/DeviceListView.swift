//
//  DeviceListView.swift
//
//
//  Created by Leon Böttger on 09.12.24.
//

import LUI
import SwiftUI

struct DeviceListView: View {
    @StateObject var fcmReceiver = PushReceiver.sharedInstance

    @ObservedObject var eidUploader = UploadPrecomputedPublicKeyIds.sharedInstance
    @ObservedObject var tokenManager = TokenManager.sharedInstance
    @ObservedObject var settings = Settings.sharedInstance

    @State var refreshing = true
    @State var showAddDeviceSheet = false

    var body: some View {
        NavigationSubView(header: "Spot", refreshAction: refresh) {
            if let devicesList = settings.devicesList {
                if devicesList.isEmpty {
                    Spacer()

                    LUIText("No Find My Device compatible trackers were paired with your account. Add new trackers on a Find My Device compatible phone.", centered: true)
                        .padding(.horizontal, 40)
                        .padding(.vertical)

                    ColoredButton(label: "Refresh") {
                        refresh()
                    }

                    Spacer()
                } else {
                    CustomSection {
                        ForEach(devicesList) { device in
                            DeviceListEntryView(device: device)
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()

                    if refreshing {
                        LoadingIndicator()
                            .frame(width: 23)
                    } else {
                        LUIText("Couldn't fetch devices. Check your internet connection.", centered: true)
                            .padding()

                        ColoredButton(label: "Try Again") {
                            refresh()
                        }
                    }

                    Spacer()
                }
                .onAppear {
                    refresh()
                }
            }
        }
        .luiSheet(isPresented: $showAddDeviceSheet, content: {
            AddDeviceView(showAddDeviceSheet: $showAddDeviceSheet, refresh: refresh)
        })
        .toolbar {
            if eidUploader.isUploading {
                ToolbarItem(placement: .topBarLeading) {
                    LoadingIndicator()
                        .frame(width: 22, height: 20)
                        .opacity(0.6)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Device", systemImage: "plus") {
                    if tokenManager.ownerKey == nil {
                        settings.showKeyRecoverySheet = true
                    } else {
                        showAddDeviceSheet = true
                    }
                }
                .labelStyle(.iconOnly)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "gear") {
                    LUISettings.sharedInstance.showSettings = true
                }
                .labelStyle(.iconOnly)
            }
        }
        .animation(.easeInOut, value: refreshing)
    }

    func refresh() {
        refreshing = true

        refreshDeviceList {
            refreshing = false
        }

        do {
            try UploadPrecomputedPublicKeyIds.sharedInstance.checkAndUpload()
        } catch {}
    }
}
