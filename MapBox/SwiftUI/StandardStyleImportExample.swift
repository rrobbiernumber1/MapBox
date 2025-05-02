import SwiftUI
import MapboxMaps

// 필요한 구조체 정의
struct FeaturesetFeature: Identifiable {
    var id: String
    var geometry: Geometry
    var properties: [String: Any?]
    
    var price: String? {
        if let price = properties["price"] as? Double {
            return "$ \(price)"
        }
        return nil
    }
    var name: String? { properties["name"] as? String }
}

// ColorTheme 간단한 구현
struct ColorTheme {
    var image: UIImage
    
    init(uiimage: UIImage) {
        self.image = uiimage
    }
}

struct StandardStyleImportExample: View {
    @State private var lightPreset: StandardLightPreset? = .night
    @State private var theme: StandardTheme? = .default
    @State private var showLabels = true
    @State private var panelHeight: CGFloat = 0
    @State private var showRealEstate = true
    @State private var show3DObjects = true
    @State private var selectedPriceLabel: FeaturesetFeature?

    // 더미 데이터 - 실제로는 지도에서 얻어와야 함
    private let dummyFeatures: [FeaturesetFeature] = [
        FeaturesetFeature(
            id: "hotel1",
            geometry: .point(Point(CLLocationCoordinate2D(latitude: 40.72, longitude: -73.99))),
            properties: ["name": "Luxury Hotel", "price": 299.0]
        ),
        FeaturesetFeature(
            id: "hotel2",
            geometry: .point(Point(CLLocationCoordinate2D(latitude: 40.73, longitude: -74.0))),
            properties: ["name": "Budget Inn", "price": 99.0]
        )
    ]

    var body: some View {
        Map(initialViewport: .camera(center: .init(latitude: 40.72, longitude: -73.99), zoom: 11, pitch: 45)) {
            if showRealEstate {
                // 호텔 위치를 PointAnnotation으로 표시
                PointAnnotationGroup(dummyFeatures) { feature in
                    PointAnnotation(coordinate: feature.geometry.point!.coordinates)
                        .image(.init(image: UIImage(systemName: "building.2.fill")!, name: "hotel"))
                        .iconAnchor(.bottom)
                        .iconSize(1.2)
                        .iconOpacity(selectedPriceLabel?.id == feature.id ? 0.5 : 1.0)
                        .onTapGesture { _ in
                            selectedPriceLabel = feature
                            return true
                        }
                }
                
                // 선택된 호텔에 대한 콜아웃 표시
                if let selectedPriceLabel, let coordinate = selectedPriceLabel.geometry.point?.coordinates {
                    MapViewAnnotation(coordinate: coordinate) {
                        HotelCallout(feature: selectedPriceLabel)
                            .id(selectedPriceLabel.id)
                    }
                    .variableAnchors([.init(anchor: .bottom)])
                }
            }

            /// Defines a custom layer and source to draw the border line.
            NYNJBorder()
        }
        .mapStyle(MapStyle.standard(
            theme: theme,
            lightPreset: lightPreset,
            showPointOfInterestLabels: showLabels,
            showTransitLabels: showLabels,
            showPlaceLabels: showLabels,
            showRoadLabels: showLabels,
            show3dObjects: show3DObjects))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: panelHeight)
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            settingsPanel.onChangeOfSize { panelHeight = $0.height }
        }
    }

    @ViewBuilder
    var settingsPanel: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Theme")
                Picker("Theme", selection: $theme) {
                    Text("Default").tag(Optional(StandardTheme.default))
                    Text("Faded").tag(Optional(StandardTheme.faded))
                    Text("Monochrome").tag(Optional(StandardTheme.monochrome))
                }.pickerStyle(.segmented)
            }
            HStack {
                Text("Light")
                Picker("Light preset", selection: $lightPreset) {
                    Text("Dawn").tag(Optional(StandardLightPreset.dawn))
                    Text("Day").tag(Optional(StandardLightPreset.day))
                    Text("Dusk").tag(Optional(StandardLightPreset.dusk))
                    Text("Night").tag(Optional(StandardLightPreset.night))
                    Text("None").tag(Optional<StandardLightPreset>.none)
                }.pickerStyle(.segmented)
            }
            Toggle("Labels", isOn: $showLabels)
            Toggle("Show Real Estate", isOn: $showRealEstate)
            Toggle("Show 3D Objects", isOn: $show3DObjects)
        }
        .padding(10)
        .floating(RoundedRectangle(cornerRadius: 10))
        .limitPaneWidth()
    }
}

private struct HotelCallout: View {
    var feature: FeaturesetFeature

    @State private var scale: CGFloat = 0.1

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(feature.name ?? "—")
                .font(.headline)
            Text(feature.price ?? "—")
                .font(.subheadline)
                .foregroundColor(.gray)
        }

        .padding(6)
        /// For callout shape see CalloutView.swift
        .callout(anchor: .bottom, color: .white, tailSize: 10)
        .scaleEffect(scale, anchor: .bottom)
        .onAppear {
            withAnimation(Animation.interpolatingSpring(stiffness: 200, damping: 16)) {
                scale = 1.0
            }
        }
    }
}

private struct NYNJBorder: MapContent {
    var body: some MapContent {
        GeoJSONSource(id: "border")
            .data(.geometry(.lineString(LineString([
                CLLocationCoordinate2D(latitude: 40.913503418907936, longitude: -73.91912400100642),
                CLLocationCoordinate2D(latitude: 40.82943110786286, longitude: -73.9615887363045),
                CLLocationCoordinate2D(latitude: 40.75461056309348, longitude: -74.01409059085539),
                CLLocationCoordinate2D(latitude: 40.69522028220487, longitude: -74.02798814058939),
                CLLocationCoordinate2D(latitude: 40.65188756398558, longitude: -74.05655532615407),
                CLLocationCoordinate2D(latitude: 40.64339339389301, longitude: -74.13916853846217),
            ]))))

        LineLayer(id: "border", source: "border")
            .lineColor(.orange)
            .lineWidth(8)
            .slot(.bottom)
    }
}

private let styleURL = Bundle.main.url(forResource: "fragment-realestate-NY", withExtension: "json")!
private let monochromeTheme = UIImage(named: "monochrome_lut")!

struct StandardStyleImportExample_Previews: PreviewProvider {
    static var previews: some View {
        StandardStyleImportExample()
    }
}
