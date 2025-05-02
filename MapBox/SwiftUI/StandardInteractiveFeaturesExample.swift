import SwiftUI
import MapboxMaps

// 필요한 기능 타입 정의
struct StandardPoiFeature: Identifiable {
    var id: String
    var coordinate: CLLocationCoordinate2D
    var name: String?
    var group: String?
    var `class`: String?
    var maki: String?
    var transitMode: String?
    var transitStopType: String?
    var transitNetwork: String?
    var airportRef: String?
    
    init(id: String, coordinate: CLLocationCoordinate2D, properties: [String: Any]) {
        self.id = id
        self.coordinate = coordinate
        self.name = properties["name"] as? String
        self.group = properties["group"] as? String
        self.class = properties["class"] as? String
        self.maki = properties["maki"] as? String
        self.transitMode = properties["transit_mode"] as? String
        self.transitStopType = properties["transit_stop_type"] as? String
        self.transitNetwork = properties["transit_network"] as? String
        self.airportRef = properties["airport_ref"] as? String
    }
}

struct StandardBuildingsFeature: Identifiable {
    var id: String
    var coordinate: CLLocationCoordinate2D
    var height: Double?
    
    init(id: String, coordinate: CLLocationCoordinate2D, properties: [String: Any]) {
        self.id = id
        self.coordinate = coordinate
        self.height = properties["height"] as? Double
    }
}

struct StandardPlaceLabelsFeature: Identifiable {
    var id: String
    var coordinate: CLLocationCoordinate2D
    var name: String?
    var `class`: String?
    
    init(id: String, coordinate: CLLocationCoordinate2D, properties: [String: Any]) {
        self.id = id
        self.coordinate = coordinate
        self.name = properties["name"] as? String
        self.class = properties["class"] as? String
    }
}

// 더미 특성 상태
struct FeatureStateOptions {
    var hide: Bool = false
    var select: Bool = false
}

struct StandardInteractiveFeaturesExample: View {
    @State var selectedPoi: StandardPoiFeature?
    @State var selectedBuildings = [StandardBuildingsFeature]()
    @State var selectedPlace: StandardPlaceLabelsFeature?
    @State var lightPreset = StandardLightPreset.day
    @State var theme = StandardTheme.default
    @State var buildingSelectColor = StyleColor("hsl(214, 94%, 59%)") // default color
    
    // 맵 롱프레스 감지용 제스처 상태
    @GestureState private var longPressGesture = false

    // 더미 데이터
    private let dummyPois: [StandardPoiFeature] = [
        StandardPoiFeature(
            id: "poi1",
            coordinate: CLLocationCoordinate2D(latitude: 60.1718, longitude: 24.9453),
            properties: ["name": "Helsinki Central", "class": "railway", "maki": "rail"]
        ),
        StandardPoiFeature(
            id: "poi2",
            coordinate: CLLocationCoordinate2D(latitude: 60.1720, longitude: 24.9460),
            properties: ["name": "Restaurant", "class": "food", "maki": "restaurant"]
        )
    ]
    
    private let dummyBuildings: [StandardBuildingsFeature] = [
        StandardBuildingsFeature(
            id: "building1",
            coordinate: CLLocationCoordinate2D(latitude: 60.1715, longitude: 24.9450),
            properties: ["height": 25.0]
        ),
        StandardBuildingsFeature(
            id: "building2",
            coordinate: CLLocationCoordinate2D(latitude: 60.1722, longitude: 24.9465),
            properties: ["height": 40.0]
        )
    ]
    
    private let dummyPlaces: [StandardPlaceLabelsFeature] = [
        StandardPlaceLabelsFeature(
            id: "place1",
            coordinate: CLLocationCoordinate2D(latitude: 60.1718, longitude: 24.9453),
            properties: ["name": "Helsinki", "class": "city"]
        )
    ]

    private struct PropView: View {
        var key: String
        var prop: String?
        var body: some View {
            if let prop {
                Text("\(key): \(prop)")
            }
        }
    }

    var body: some View {
        let cameraCenter = CLLocationCoordinate2D(latitude: 60.1718, longitude: 24.9453)
        ZStack {
            Map(initialViewport: .camera(center: cameraCenter, zoom: 16.35, bearing: 49.92, pitch: 40)) {
                // POI 주석 표시
                PointAnnotationGroup(dummyPois) { poi in
                    PointAnnotation(coordinate: poi.coordinate)
                        .image(.init(image: UIImage(systemName: "mappin.circle.fill")!, name: "poi-\(poi.id)"))
                        .iconAnchor(.bottom)
                        .iconSize(1.2)
                        .iconOpacity(selectedPoi?.id == poi.id ? 0.5 : 1.0)
                        .onTapGesture { _ in
                            selectedPoi = poi
                            return true
                        }
                }
                
                // 건물 주석 표시
                PolygonAnnotationGroup(dummyBuildings) { building in
                    // 건물을 단순화된 사각형으로 표현
                    let coordinate = building.coordinate
                    let delta = 0.0005  // 약 50미터 크기의 사각형
                    let polygon = Polygon([
                        [
                            CLLocationCoordinate2D(latitude: coordinate.latitude - delta, longitude: coordinate.longitude - delta),
                            CLLocationCoordinate2D(latitude: coordinate.latitude + delta, longitude: coordinate.longitude - delta),
                            CLLocationCoordinate2D(latitude: coordinate.latitude + delta, longitude: coordinate.longitude + delta),
                            CLLocationCoordinate2D(latitude: coordinate.latitude - delta, longitude: coordinate.longitude + delta)
                        ]
                    ])
                    
                    return PolygonAnnotation(polygon: polygon)
                        .fillColor(selectedBuildings.contains(where: { $0.id == building.id }) ? buildingSelectColor : StyleColor(.gray))
                        .fillOpacity(0.7)
                        .onTapGesture { _ in
                            selectedBuildings.append(building)
                            return true
                        }
                }
                
                // 장소 라벨 주석 표시
                PointAnnotationGroup(dummyPlaces) { place in
                    PointAnnotation(coordinate: place.coordinate)
                        .image(.init(image: UIImage(systemName: "mappin.circle")!, name: "place-\(place.id)"))
                        .iconAnchor(.bottom)
                        .iconSize(1.5)
                        .iconColor(selectedPlace?.id == place.id ? .red : .black)
                        .onTapGesture { _ in
                            selectedPlace = place
                            return true
                        }
                }
                
                // 선택된 POI에 대한 인포 뷰
                if let selectedPoi {
                    MapViewAnnotation(coordinate: selectedPoi.coordinate) {
                        CustomPinView(text: selectedPoi.name ?? "", type: selectedPoi.class)
                            .id(selectedPoi.id)
                    }
                    .allowZElevate(true)
                    .variableAnchors([
                        ViewAnnotationAnchorConfig(anchor: .top, offsetX: 0, offsetY: 50)
                    ])
                }
            }
            // mapStyle 적용 - 실험적 스타일 대신 표준 스타일 사용
            .mapStyle(MapStyle.standard(
                theme: theme,
                lightPreset: lightPreset,
                showPointOfInterestLabels: true,
                showTransitLabels: true,
                showPlaceLabels: true,
                showRoadLabels: true))
            .ignoresSafeArea()
            
            // 롱프레스 제스처 추가 - 맵을 직접 수정자로 사용할 수 없으므로 ZStack 위에 투명 오버레이로 추가
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .updating($longPressGesture) { value, state, _ in
                            state = true
                        }
                        .onEnded { _ in
                            // 맵을 길게 눌렀을 때 모든 선택 초기화
                            selectedBuildings = []
                            selectedPoi = nil
                            selectedPlace = nil
                        }
                )
        }
        
        // Debug 패널
        .overlay(alignment: .bottom) {
            VStack(alignment: .leading) {
                if let selectedPoi {
                    VStack(alignment: .leading) {
                        PropView(key: "name", prop: selectedPoi.name)
                        PropView(key: "group", prop: selectedPoi.group)
                        PropView(key: "class", prop: selectedPoi.class)
                        PropView(key: "maki", prop: selectedPoi.maki)
                        PropView(key: "transitMode", prop: selectedPoi.transitMode)
                        PropView(key: "transitStopType", prop: selectedPoi.transitStopType)
                        PropView(key: "transitNetwork", prop: selectedPoi.transitNetwork)
                        PropView(key: "airportRef", prop: selectedPoi.airportRef)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.9)))
                    .shadow(radius: 2)
                    .padding(.bottom, 8)
                    .font(.system(.body, design: .monospaced))
                }
                if let selectedPlace {
                    VStack(alignment: .leading) {
                        PropView(key: "name", prop: selectedPlace.name)
                        PropView(key: "class", prop: selectedPlace.class)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.9)))
                    .shadow(radius: 2)
                    .padding(.bottom, 8)
                    .font(.system(.body, design: .monospaced))
                }
                VStack {
                    HStack {
                        Text("Building Select")
                        Picker("Building Select", selection: $buildingSelectColor) {
                            Text("Default").tag(StyleColor("hsl(214, 94%, 59%)"))
                            Text("Yellow").tag(StyleColor("yellow"))
                            Text("Red").tag(StyleColor(.red))
                        }.pickerStyle(.segmented)
                    }
                    HStack {
                        Text("Light")
                        Picker("Light", selection: $lightPreset) {
                            Text("Dawn").tag(StandardLightPreset.dawn)
                            Text("Day").tag(StandardLightPreset.day)
                            Text("Dusk").tag(StandardLightPreset.dusk)
                            Text("Night").tag(StandardLightPreset.night)
                        }.pickerStyle(.segmented)
                    }
                    HStack {
                        Text("Theme")
                        Picker("Theme", selection: $theme) {
                            Text("Default").tag(StandardTheme.default)
                            Text("Faded").tag(StandardTheme.faded)
                            Text("Monochrome").tag(StandardTheme.monochrome)
                        }.pickerStyle(.segmented)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.9)))
                .shadow(radius: 2)
                .padding(.bottom, 8)
            }
            .padding()
        }
    }
}

// PinView 이름 변경 (중복을 피하기 위해)
struct CustomPinView: View {
    var text: String
    var type: String?
    
    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.caption)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.white))
                .shadow(radius: 2)
            
            Image(systemName: typeToIcon(type))
                .font(.system(size: 24))
                .foregroundColor(.red)
        }
    }
    
    private func typeToIcon(_ type: String?) -> String {
        guard let type = type else { return "mappin" }
        
        switch type.lowercased() {
        case "railway": return "tram.fill"
        case "food": return "fork.knife"
        case "shop": return "bag.fill"
        default: return "mappin"
        }
    }
}
