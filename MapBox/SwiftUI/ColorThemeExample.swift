import SwiftUI
import MapboxMaps

// 간단한 테마 클래스
struct SimpleColorTheme: MapStyleContent {
    var uiimage: UIImage?
    var base64String: String?
    
    init(uiimage: UIImage) {
        self.uiimage = uiimage
    }
    
    init(base64: String) {
        self.base64String = base64
    }
    
    var body: some MapStyleContent {
        // MapboxMaps의 빈 구현으로 대체
        EmptyMapStyleContent()
    }
}

struct ColorThemeExample: View {
    enum Theme: String {
        case `default`
        case pink
        case monochrome
    }

    @State private var theme: Theme = .pink
    @State private var panelHeight: CGFloat = 0
    @State private var atmosphereUseTheme = true
    @State private var circleUseTheme = true

    var body: some View {
        Map(initialViewport: .camera(center: .init(latitude: 40.72, longitude: -73.99), zoom: 2, pitch: 45)) {
            switch theme {
            case .default:
                // 빈 콘텐츠 대신에 아무것도 하지 않음
                EmptyMapStyleContent()
            case .pink:
                // 대체 구현 사용
                SimpleColorTheme(base64: pinkTheme)
            case .monochrome:
                // 대체 구현 사용
                SimpleColorTheme(uiimage: monochromeTheme)
            }

            Atmosphere()
                .color(.green)
                // 테마 사용 여부에 따라 색상 설정
                .color(atmosphereUseTheme ? .green : .clear)

            TestLayer(id: "blue-layer", radius: 2, color: .blue, coordinate: .init(latitude: 40, longitude: -104), useTheme: circleUseTheme)
        }
        .mapStyle(.streets)
        .additionalSafeAreaInsets(.bottom, panelHeight)
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            VStack(alignment: .center) {
                Group {
                    HStack {
                        ColorButton(color: .white, isOn: Binding(get: { theme == .default }, set: { _, _ in theme = .default }))
                        ColorButton(color: .systemPink, isOn: Binding(get: { theme == .pink }, set: { _, _ in theme = .pink }))
                        ColorButton(color: .secondaryLabel, isOn: Binding(get: { theme == .monochrome }, set: { _, _ in theme = .monochrome }))
                    }

                    VStack {
                        Toggle("Atmosphere Use Theme", isOn: $atmosphereUseTheme)
                        Toggle("Circle Use Theme", isOn: $circleUseTheme)
                    }
                }
                .floating()
            }
            .padding(.bottom, 30)
        }
    }
}

private struct ColorButton: View {
    let color1: UIColor
    let color2: UIColor
    let isOn: Binding<Bool>

    init(color: UIColor, isOn: Binding<Bool>) {
        self.color1 = color
        self.color2 = color
        self.isOn = isOn
    }

    init(color1: UIColor, color2: UIColor, isOn: Binding<Bool>) {
        self.color1 = color1
        self.color2 = color2
        self.isOn = isOn
    }

    var body: some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(color1), Color(color2)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Circle().strokeBorder(Color(color1.cgColor), lineWidth: 2)
            }
        }
        .opacity(isOn.wrappedValue ? 1.0 : 0.2)
        .frame(width: 50, height: 50)
    }
}

// 수정된 TestLayer - 테마 속성 대신 직접 색상 설정
private struct TestLayer: MapStyleContent {
    var id: String
    var radius: LocationDistance
    var color: UIColor
    var coordinate: CLLocationCoordinate2D
    var useTheme: Bool

    var body: some MapStyleContent {
        let sourceId = "\(id)-source"
        
        // 테마 기능 대신 직접 조건부 색상 적용
        FillLayer(id: id, source: sourceId)
            .fillColor(useTheme ? color : .clear)
            .fillOpacity(0.4)
            
        LineLayer(id: "\(id)-border", source: sourceId)
            .lineColor(useTheme ? getDarkerColor(color) : .clear)
            .lineOpacity(0.4)
            .lineWidth(2)
            
        GeoJSONSource(id: sourceId)
            .data(.geometry(.polygon(Polygon(center: coordinate, radius: radius * 1000000, vertices: 60))))
    }
    
    // UIColor.darker 대신 내부 함수 사용
    private func getDarkerColor(_ color: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: max(r - 0.1, 0), green: max(g - 0.1, 0), blue: max(b - 0.1, 0), alpha: a)
    }
}

private let styleURL = Bundle.main.url(forResource: "fragment-realestate-NY", withExtension: "json")!
private let monochromeTheme = UIImage(named: "monochrome_lut")!
private let pinkTheme = "iVBORw0KGgoAAAANSUhEUgAABAAAAAAgCAYAAACM/gqmAAAKSWlDQ1BzUkdCIElFQzYxOTY2LTIuMQAASImdU3dYk/cWPt/3ZQ9WQtjwsZdsgQAiI6wIyBBZohCSAGGEEBJAxYWIClYUFRGcSFXEgtUKSJ2I4qAouGdBiojai1VcOO4f3Ke1fXrv7e371/u855zn/M55zw+AERImkeaiagA5UoU8Otgfj09IxMm9gAIVSOAEIBDmy8JnBcUAAPADeXh+dLA//AGvbwACAHDVLiQSx+H/g7pQJlcAIJEA4CIS5wsBkFIAyC5UyBQAyBgAsFOzZAoAlAAAbHl8QiIAqg0A7PRJPgUA2KmT3BcA2KIcqQgAjQEAmShHJAJAuwBgVYFSLALAwgCgrEAiLgTArgGAWbYyRwKAvQUAdo5YkA9AYACAmUIszAAgOAIAQx4TzQMgTAOgMNK/4KlfcIW4SAEAwMuVzZdL0jMUuJXQGnfy8ODiIeLCbLFCYRcp"
