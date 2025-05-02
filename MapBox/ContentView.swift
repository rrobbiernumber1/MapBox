//
//  ContentView.swift
//  MapBox
//
//  Created by RRobbie Sun on 4/30/25.
//

import SwiftUI
import MapboxMaps
import UIKit

struct ContentView: View {
    var body: some View {
        VStack {
            ExampleTableViewControllerWrapper()
        }
    }
}

// ExampleTableViewController를 SwiftUI에서 사용하기 위한 래퍼
struct ExampleTableViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let exampleTableViewController = ExampleTableViewController()
        let navigationController = UINavigationController(rootViewController: exampleTableViewController)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // 업데이트 필요 없음
    }
}

// 각 예제 그리드 아이템 뷰
struct ExampleView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(title)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}
