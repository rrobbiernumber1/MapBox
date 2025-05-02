//
//  View+Extensions.swift
//  MapBox
//
//  Created by RRobbie Sun on 4/30/25.
//

import SwiftUI

extension View {
    func floating() -> some View {
        self
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
    }
    
    func floating<S: Shape>(_ shape: S) -> some View {
        self
            .padding()
            .background(Color.white.opacity(0.8))
            .clipShape(shape)
    }
} 