//
//  ContentView.swift
//  Usage Notch
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NotchBarView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
    }
}
