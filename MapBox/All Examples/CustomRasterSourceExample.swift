import UIKit
import os
import MapboxMaps
import Combine

// 헬싱키 좌표 정의
struct MapCoordinates {
    static let helsinki = CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384)
}

final class CustomRasterSourceExample: UIViewController, ExampleProtocol {
    private var mapView: MapView!
    private var cancelables: Set<AnyCancelable> = []
    private var animationTimer: Timer?
    
    private enum ID {
        static let rasterSource = "raster-source"
        static let rasterLayer = "raster-layer"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MapView(frame: view.bounds, mapInitOptions: .init(cameraOptions: CameraOptions(center: MapCoordinates.helsinki, zoom: 2)))
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)

        mapView.mapboxMap.onStyleLoaded.observeNext { [weak self] _ in
            self?.setupExample()
            // The below line is used for internal testing purposes only.
            self?.finish()
        }
        .store(in: &cancelables)
        
        // 애니메이션 시작 버튼 추가
        let animationButton = UIButton(type: .system)
        animationButton.setTitle("애니메이션 시작/정지", for: .normal)
        animationButton.translatesAutoresizingMaskIntoConstraints = false
        animationButton.addTarget(self, action: #selector(toggleAnimation), for: .touchUpInside)
        view.addSubview(animationButton)
        
        NSLayoutConstraint.activate([
            animationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func toggleAnimation() {
        if animationTimer != nil {
            stopAnimation()
        } else {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateRasterImage()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func setupExample() {
        do {
            // 첫 번째 이미지로 레이어 초기화
            setupRasterLayer(with: rasterImages[0])
        } catch {
            print("[Example/CustomRasterSourceExample] Error: \(error)")
        }
    }
    
    private func setupRasterLayer(with image: UIImage) {
        do {
            // 이미지를 래스터 타일 소스로 사용
            let imageData = image.pngData()!
            
            // 이미 소스가 있으면 제거
            if mapView.mapboxMap.sourceExists(withId: ID.rasterSource) {
                try mapView.mapboxMap.removeLayer(withId: ID.rasterLayer)
                try mapView.mapboxMap.removeSource(withId: ID.rasterSource)
            }
            
            // 이미지 소스 등록
            try mapView.mapboxMap.addImage(image, id: "raster-image")
            
            // GeoJSON 기반의 소스 생성
            var source = RasterSource(id: ID.rasterSource)
            source.tiles = ["asset://RasterSource/wind_\(currentImageIndex)"]
            source.tileSize = 256
            try mapView.mapboxMap.addSource(source)
            
            // 래스터 레이어 추가
            var rasterLayer = RasterLayer(id: ID.rasterLayer, source: ID.rasterSource)
            rasterLayer.rasterOpacity = .constant(0.7)
            
            // 색상 효과 적용
            rasterLayer.rasterColor = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.lineProgress)
                    0
                    "rgba(0.0, 0.0, 0.0, 0.0)"
                    0.3
                    "rgba(7, 238, 251, 0.4)"
                    0.5
                    "rgba(0, 255, 42, 0.5)"
                    0.7
                    "rgba(255, 255, 0, 0.7)"
                    1
                    "rgba(255, 30, 0, 0.9)"
                }
            )
            
            try mapView.mapboxMap.addLayer(rasterLayer)
        } catch {
            print("[Example/CustomRasterSourceExample] Error setting up raster layer: \(error)")
        }
    }
    
    private func updateRasterImage() {
        currentImageIndex = (currentImageIndex + 1) % rasterImages.count
        let nextImage = rasterImages[currentImageIndex]
        
        // 새로운 이미지로 레이어 재설정
        setupRasterLayer(with: nextImage)
    }

    // MARK: Raster Images

    private var currentImageIndex = 0
    private let rasterImages: [UIImage] = [
        UIImage(named: "RasterSource/wind_0")!,
        UIImage(named: "RasterSource/wind_1")!,
        UIImage(named: "RasterSource/wind_2")!,
        UIImage(named: "RasterSource/wind_3")!,
    ]
    
    deinit {
        stopAnimation()
    }
}

// 타일 상태 로깅을 위한 확장(참고용)
/*
extension CanonicalTileID {
    var log: String {
        return "\(z)/\(x)/\(y)"
    }
}

extension CustomRasterSourceTileStatus {
    var log: String {
        switch self {
        case .notNeeded: return "notNeeded"
        case .optional: return "optional"
        case .required: return "required"
        @unknown default: return "unknown"
        }
    }
}
*/
