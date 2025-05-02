import UIKit
import MapboxMaps

final class ColorThemeMapExample: UIViewController, ExampleProtocol {
    private var mapView: MapView!
    private var useCustomStyle = true
    private var useCustomLayerStyle = true
    private var cancellables = Set<AnyCancelable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 기본 스타일로 시작
        let mapInitOptions = MapInitOptions(styleURI: .streets)
        mapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions)

        view.addSubview(mapView)
        view.backgroundColor = .blue
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // 컬러 테마 대신 커스텀 스타일을 적용
        applyCustomMapStyle()
        addTestLayer()

        // 지도 탭 제스처
        mapView.gestures.onMapTap.observe { [weak self] _ in
            guard let self else { return }

            self.useCustomStyle.toggle()
            if self.useCustomStyle {
                // 커스텀 스타일 적용
                self.applyCustomMapStyle()
            } else {
                // 기본 스타일로 되돌리기
                self.mapView.mapboxMap.loadStyleURI(.streets)
            }
        }
        .store(in: &cancellables)

        // 레이어 탭 제스처
        mapView.gestures.onLayerTap("blue-layer") { [weak self] _, _ in
            guard let self else { return true }

            self.useCustomLayerStyle.toggle()
            self.addTestLayer(useCustomStyle: self.useCustomLayerStyle)
            return true
        }
        .store(in: &cancellables)
    }

    // 커스텀 맵 스타일 적용 함수 (ColorTheme 대신 사용)
    private func applyCustomMapStyle() {
        // 모노크롬 효과를 줄 수 있는 다른 스타일 적용
        // 실제로는 맵박스 스튜디오에서 만든 커스텀 스타일을 적용하는 것이 좋습니다
        
        // 기본 스타일 사용 - 실제로는 모노크롬 스타일이 필요하면 맵박스 스튜디오에서 만들어야 함
        mapView.mapboxMap.loadStyleURI(.dark)
    }

    private func addTestLayer(
        id: String = "blue-layer",
        radius: LocationDistance = 2,
        color: UIColor = .blue,
        coordinate: CLLocationCoordinate2D = .init(latitude: 40, longitude: -104),
        useCustomStyle: Bool = true
    ) {
        let sourceId = "\(id)-source"
        try? mapView.mapboxMap.removeLayer(withId: id)
        try? mapView.mapboxMap.removeLayer(withId: "\(id)-border")
        try? mapView.mapboxMap.removeSource(withId: sourceId)

        // 먼저 소스를 추가
        var source = GeoJSONSource(id: sourceId)
        source.data = .geometry(.polygon(Polygon(center: coordinate, radius: radius * 1000000, vertices: 60)))
        try! mapView.mapboxMap.addSource(source)
        
        // 그 다음 레이어 추가
        var fillLayer = FillLayer(id: id, source: sourceId)
        if useCustomStyle {
            fillLayer.fillColor = .constant(StyleColor(color))
            fillLayer.fillOpacity = .constant(0.4)
        } else {
            fillLayer.fillColor = .constant(StyleColor(.red))
            fillLayer.fillOpacity = .constant(0.4)
        }
        try! mapView.mapboxMap.addLayer(fillLayer)
        
        var borderLayer = LineLayer(id: "\(id)-border", source: sourceId)
        if useCustomStyle {
            // darker 메서드를 직접 구현하는 대신 여기서 직접 계산
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let darkerColor = UIColor(red: max(r - 0.2, 0), green: max(g - 0.2, 0), blue: max(b - 0.2, 0), alpha: a)
            
            borderLayer.lineColor = .constant(StyleColor(darkerColor))
            borderLayer.lineOpacity = .constant(0.4)
            borderLayer.lineWidth = .constant(2)
        } else {
            borderLayer.lineColor = .constant(StyleColor(.systemRed))
            borderLayer.lineOpacity = .constant(0.4)
            borderLayer.lineWidth = .constant(2)
        }
        try! mapView.mapboxMap.addLayer(borderLayer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // The below line is used for internal testing purposes only.
        finish()
    }
}

// SKyBlue와 darker가 이미 다른 곳에서 정의되어 있으므로 제거

// 맵박스 스타일 확장
extension StyleURI {
    // 모노크롬 스타일 URI - 샘플용 (실제 URI는 맵박스에서 확인해야 함)
    static var monochrome: StyleURI {
        // Optional 언래핑
        return StyleURI(rawValue: "mapbox://styles/mapbox/monochrome-dark-v1")!
    }
}
