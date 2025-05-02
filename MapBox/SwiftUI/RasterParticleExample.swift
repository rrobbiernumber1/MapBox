import SwiftUI
import MapboxMaps

struct RasterParticleExample: View {
    @State var mapStyle = MapStyle.dark
    @State var rasterParticleCount: Double = 2048
    @State var rasterParticleFadeOpacityFactor = 0.8
    @State var resetRateFactor = 0.4
    @State var speedFactor = 0.4

    var body: some View {
        ZStack {
            // 기본 맵 뷰 - 가장 단순한 구현
            VeryBasicMapView(styleURI: mapStyle == .dark ? .dark : .light)
                .ignoresSafeArea()
            
            // UI 컨트롤 오버레이
            VStack {
                Spacer()
                
                // 슬라이더 컨트롤
                VStack(alignment: .center) {
                    SliderSettingView(title: "Particle Count", value: $rasterParticleCount, range: 1...4096, step: 1)
                    SliderSettingView(title: "Opacity Factor", value: $rasterParticleFadeOpacityFactor, range: 0...1, step: 0.01)
                    SliderSettingView(title: "Reset Rate", value: $resetRateFactor, range: 0...1, step: 0.01)
                    SliderSettingView(title: "Speed Factor", value: $speedFactor, range: 0...1, step: 0.01)
                }
                .foregroundColor(.white)
                .padding(.bottom, 40)
                .padding(.horizontal, 16)
            }
            
            // 스타일 선택 버튼
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        mapStyle = mapStyle == .dark ? .light : .dark
                    }) {
                        Image(systemName: mapStyle == .dark ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// 가장 단순한 맵 뷰 구현 - 최소한의 기능으로 시작
struct VeryBasicMapView: UIViewRepresentable {
    var styleURI: StyleURI
    
    func makeUIView(context: Context) -> MapView {
        // 가장 기본적인 맵 초기화
        let options = MapInitOptions(styleURI: styleURI)
        let mapView = MapView(frame: .zero, mapInitOptions: options)
        
        // 디버그 옵션은 SDK 버전 호환성 문제로 일단 제외
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        // 맵 스타일 업데이트만 수행
        if mapView.mapboxMap.styleURI != styleURI {
            mapView.mapboxMap.styleURI = styleURI
        }
    }
}

private struct SliderSettingView: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double

    var body: some View {
        HStack {
            Text("\(title)")
            Slider(value: $value, in: range, step: step) {
            } minimumValueLabel: {
                Text("")
            } maximumValueLabel: {
                Text("\(String(format: "%.2f", value))")
                    .font(.system(size: 12))
            }
        }
    }
}
