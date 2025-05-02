import UIKit
import MapboxMaps
import MetalKit

// 누락된 VertexInputIndex 열거형 정의
enum VertexInputIndex: Int {
    case vertices = 0
    case transformation = 1
}

// 누락된 VertexData 구조체 정의
struct VertexData {
    let position: simd_float2
    let color: simd_float4
    
    init(position: simd_float2, color: simd_float4) {
        self.position = position
        self.color = color
    }
}

// 주요 도시 좌표 정의
struct CityCoordinates {
    static let helsinki = CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384)
    static let berlin = CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
    static let kyiv = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
}

// Projection 유틸리티 클래스 정의
class Projection {
    static func project(_ coordinate: CLLocationCoordinate2D, zoomScale: Double) -> CGPoint {
        // 메르카토르 투영 공식 사용
        let x = (coordinate.longitude + 180.0) / 360.0 * zoomScale
        let latRad = coordinate.latitude * .pi / 180.0
        let y = (1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / .pi) / 2.0 * zoomScale
        return CGPoint(x: x, y: y)
    }
}

final class CustomLayerExample: UIViewController, ExampleProtocol {
    private var mapView: MapView!

    var colorArray = [
        simd_float4(1, 0, 0, 0.5),
        simd_float4(0.5, 0, 0, 0.5),
        simd_float4(0, 1, 0, 0.5),
        simd_float4(0, 0.5, 0, 0.5),
        simd_float4(0, 0, 1, 0.5),
        simd_float4(0, 0, 0.5, 0.5),
    ]

    // The CustomLayerExampleCustomLayerHost() should be created and stored outside of MapStyleContent so that it is not recreated with every style update.
    let renderer = CustomLayerExampleCustomLayerHost()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(barButtonTap(_:)))

        let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 58, longitude: 20), zoom: 3)

        mapView = MapView(frame: view.bounds, mapInitOptions: MapInitOptions(cameraOptions: cameraOptions))
        
        // MapBox 스타일 설정
        mapView.mapboxMap.loadStyleURI(.streets) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("스타일 로딩 실패: \(error)")
                return
            }
            
            // CustomLayer 추가 대신 표준 Layer API 사용
            self.addCustomLayers()
        }

        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
    }
    
    private func addCustomLayers() {
        // 삼각형 도시들을 위한 간단한 원형 레이어 추가
        addCircleLayer(for: .helsinki, id: "helsinki-point", color: UIColor(red: 1, green: 0, blue: 0, alpha: 0.5))
        addCircleLayer(for: .berlin, id: "berlin-point", color: UIColor(red: 0, green: 1, blue: 0, alpha: 0.5))
        addCircleLayer(for: .kyiv, id: "kyiv-point", color: UIColor(red: 0, green: 0, blue: 1, alpha: 0.5))
        
        // 세 도시를 잇는 라인 추가
        addLinesBetweenCities()
    }
    
    private func addCircleLayer(for coordinate: CLLocationCoordinate2D, id: String, color: UIColor) {
        // GeoJSON 형식으로 포인트 생성
        let point = Point(coordinate)
        let feature = Feature(geometry: .point(point))
        var source = GeoJSONSource(id: "\(id)-source")
        source.data = .feature(feature)
        
        // 원형 레이어 생성
        var circleLayer = CircleLayer(id: id, source: "\(id)-source")
        circleLayer.circleRadius = .constant(10)
        circleLayer.circleColor = .constant(StyleColor(color))
        circleLayer.circleOpacity = .constant(0.7)
        
        // 소스와 레이어 추가
        do {
            try mapView.mapboxMap.addSource(source)
            try mapView.mapboxMap.addLayer(circleLayer)
        } catch {
            print("레이어 추가 실패: \(error)")
        }
    }
    
    private func addLinesBetweenCities() {
        // 세 도시를 잇는 라인 생성
        let coordinates = [
            CityCoordinates.helsinki,
            CityCoordinates.berlin,
            CityCoordinates.kyiv,
            CityCoordinates.helsinki  // 삼각형 완성을 위해 다시 헬싱키로
        ]
        
        let lineString = LineString(coordinates)
        let feature = Feature(geometry: .lineString(lineString))
        var source = GeoJSONSource(id: "triangle-source")
        source.data = .feature(feature)
        
        // 라인 레이어 생성
        var lineLayer = LineLayer(id: "city-triangle", source: "triangle-source")
        lineLayer.lineWidth = .constant(2)
        lineLayer.lineColor = .constant(StyleColor(.purple))
        lineLayer.lineOpacity = .constant(0.6)
        
        // 소스와 레이어 추가
        do {
            try mapView.mapboxMap.addSource(source)
            try mapView.mapboxMap.addLayer(lineLayer)
        } catch {
            print("삼각형 레이어 추가 실패: \(error)")
        }
    }

    @objc func barButtonTap(_ barButtonItem: UIBarButtonItem) {
        // 색상 업데이트 로직
        colorArray.shuffle()
        
        // 각 도시 포인트 색상 업데이트
        let cities = ["helsinki-point", "berlin-point", "kyiv-point"]
        let colors = [
            UIColor(red: CGFloat(colorArray[0].x), green: CGFloat(colorArray[0].y), blue: CGFloat(colorArray[0].z), alpha: CGFloat(colorArray[0].w)),
            UIColor(red: CGFloat(colorArray[1].x), green: CGFloat(colorArray[1].y), blue: CGFloat(colorArray[1].z), alpha: CGFloat(colorArray[1].w)),
            UIColor(red: CGFloat(colorArray[2].x), green: CGFloat(colorArray[2].y), blue: CGFloat(colorArray[2].z), alpha: CGFloat(colorArray[2].w))
        ]
        
        for (index, city) in cities.enumerated() {
            do {
                try mapView.mapboxMap.updateLayer(withId: city, type: CircleLayer.self) { layer in
                    layer.circleColor = .constant(StyleColor(colors[index]))
                }
            } catch {
                print("\(city) 색상 업데이트 실패: \(error)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         // The below line is used for internal testing purposes only.
        finish()
    }
}

// Metal 커스텀 레이어 호스트는 유지하지만, 실제로는 사용하지 않음
final class CustomLayerExampleCustomLayerHost: NSObject {
    var colors = [
        simd_float4(1, 0, 0, 0.5),
        simd_float4(0, 1, 0, 0.5),
        simd_float4(0, 0, 1, 0.5),
    ]

    var depthStencilState: MTLDepthStencilState!
    var pipelineState: MTLRenderPipelineState!
}

// Metal 셰이더 코드 (참고용으로 유지, 실제로는 사용하지 않음)
/*
#include <metal_stdlib>
using namespace metal;

struct VertexData {
    float2 position;
    float4 color;
};

struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

enum VertexInputIndex {
    VertexInputIndexVertices = 0,
    VertexInputIndexTransformation = 1,
};

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                  constant VertexData *vertices [[buffer(VertexInputIndexVertices)]],
                                  constant float4x4 &transformation [[buffer(VertexInputIndexTransformation)]]) {
    RasterizerData out;
    out.position = transformation * float4(vertices[vertexID].position, 0, 1);
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
    return in.color;
}
*/
