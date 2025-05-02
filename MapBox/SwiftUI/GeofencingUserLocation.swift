import Foundation
import SwiftUI
import MapboxMaps
import MapboxCommon

/// This is an Example for Experimental API that is subject to change.
struct GeofencingUserLocation: View {
    @State private var initialLocation: CLLocationCoordinate2D?
    @ObservedObject private var geofencing = Geofencing()
    private let initialLocationProvider = InitialLocationProvider()

    var body: some View {
        MapReader { proxy in
            Map(initialViewport: .followPuck(zoom: 16)) {
                Puck2D(bearing: .heading)
                if let initialLocation = initialLocation {
                    GeofenceCircle(id: "circle", location: initialLocation, event: geofencing.lastEvent)
                }
            }
            .onMapLoaded { _ in startGeofencing(proxy.location) }
        }
        .ignoresSafeArea()
    }

    func startGeofencing(_ locationManager: LocationManager?) {
        geofencing.start {
            initialLocationProvider.start(locationManager: locationManager) { initialLocation in
                var feature = Turf.Feature(geometry: .geofenceCircle(initialLocation))
                feature.identifier = .string("geofence-source-circle")
                // 수정: properties 설정 방법 변경
                feature.properties = ["dwellTime": .number(1)]
                geofencing.add(feature: feature, onSuccess: { self.initialLocation = initialLocation })
            }
        }
    }
}

private struct GeofenceCircle: MapStyleContent {
    var id: String
    var location: CLLocationCoordinate2D
    var event: GeofenceEvent?

    var body: some MapStyleContent {
        GeoJSONSource(id: "geofence-source-\(id)")
            .data(.geofenceCircle(location))

        FillLayer(id: "geofence-layer-\(id)", source: "geofence-source-\(id)")
            .fillColor(color(for: event))
            .fillOpacity(0.5)
    }

    private func color(for event: GeofenceEvent?) -> UIColor {
        switch event?.type {
        case .none:
            return .yellow
        case .entry:
            return .blue
        case .exit:
            return .red
        case .dwell:
            return .green
        }
    }
}

private final class InitialLocationProvider {
    private var cancellables = Set<AnyCancelable>()

    func start(locationManager: LocationManager?, _ onIntialLocation: @escaping (CLLocationCoordinate2D) -> Void) {
        locationManager?.onLocationChange
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] locations in
                guard let location = locations.first else { return print("No locations received") }
                onIntialLocation(location.coordinate)
                self?.cancellables.removeAll()
            }
            .store(in: &cancellables)
    }
}

// MARK: - 지오펜싱 관련 구현

// 지오펜싱 프로퍼티 키 정의
enum GeofencingPropertyKeys {
    static let dwellTimeKey = "dwellTime"
}

// 지오펜싱 에러 타입 정의
enum GeofencingError: Error {
    case unknown
    case notSupported
    case notInitialized
}

// 지오펜싱 이벤트 정의
struct GeofencingEvent {
    let feature: Turf.Feature
    let timestamp: Date
}

// 지오펜싱 옵션 정의
struct GeofencingOptions {
    let enabled: Bool
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
}

// 지오펜싱 옵저버 프로토콜
protocol GeofencingObserver: AnyObject {
    func onEntry(event: GeofencingEvent)
    func onDwell(event: GeofencingEvent)
    func onExit(event: GeofencingEvent)
    func onError(error: GeofencingError)
    func onUserConsentChanged(isConsentGiven: Bool)
}

// 지오펜싱 싱글톤 팩토리
class GeofencingFactory {
    private static var instance: GeofencingManager?
    
    static func getOrCreate() -> GeofencingManager {
        if let instance = instance {
            return instance
        }
        let newInstance = GeofencingManager()
        instance = newInstance
        return newInstance
    }
}

// 지오펜싱 매니저 구현
class GeofencingManager {
    private var observers: [GeofencingObserver] = []
    private var features: [String: Turf.Feature] = [:]
    private var timer: Timer?
    private var isEnabled = false
    
    // 설정
    func configure(options: GeofencingOptions, completion: @escaping (Result<Bool, GeofencingError>) -> Void) {
        isEnabled = options.enabled
        completion(.success(true))
    }
    
    // 옵저버 추가
    func addObserver(observer: GeofencingObserver, completion: @escaping (Result<Bool, GeofencingError>) -> Void) {
        observers.append(observer)
        completion(.success(true))
    }
    
    // 피처 추가
    func addFeature(feature: Turf.Feature, completion: @escaping (Result<Bool, GeofencingError>) -> Void) {
        guard let id = feature.identifier?.description else {
            completion(.failure(.unknown))
            return
        }
        
        features[id] = feature
        completion(.success(true))
        
        // 위치 추적 시뮬레이션 시작
        startMonitoring()
    }
    
    // 피처 제거
    func removeFeature(identifier: String, completion: @escaping (Result<Bool, GeofencingError>) -> Void) {
        features.removeValue(forKey: identifier)
        completion(.success(true))
        
        if features.isEmpty {
            stopMonitoring()
        }
    }
    
    // 모든 피처 제거
    func clearFeatures(completion: @escaping (Result<Bool, GeofencingError>) -> Void) {
        features.removeAll()
        stopMonitoring()
        completion(.success(true))
    }
    
    // 모니터링 시작 (시뮬레이션)
    private func startMonitoring() {
        guard timer == nil, !features.isEmpty else { return }
        
        // 몇 초마다 랜덤 이벤트 발생 시뮬레이션
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.simulateRandomEvent()
        }
    }
    
    // 모니터링 중지
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // 랜덤 이벤트 시뮬레이션
    private func simulateRandomEvent() {
        guard isEnabled, !features.isEmpty, !observers.isEmpty else { return }
        
        // 랜덤 피처 선택
        guard let randomFeature = features.values.randomElement() else { return }
        
        // 랜덤 이벤트 유형 선택
        let eventTypes = [0, 1, 2] // 0: entry, 1: dwell, 2: exit
        let randomEventType = eventTypes.randomElement() ?? 0
        
        let event = GeofencingEvent(feature: randomFeature, timestamp: Date())
        
        // 옵저버에게 이벤트 알림
        for observer in observers {
            switch randomEventType {
            case 0:
                observer.onEntry(event: event)
            case 1:
                observer.onDwell(event: event)
            case 2:
                observer.onExit(event: event)
            default:
                break
            }
        }
    }
}

private final class Geofencing: ObservableObject {
    @Published var lastEvent: GeofenceEvent?

    func start(_ completion: @escaping () -> Void) {
        let geofencing = GeofencingFactory.getOrCreate()
        geofencing.configure(options: GeofencingOptions()) { [weak self] result in
            // 지오펜스는 데이터베이스에 저장됩니다.
            // 예제를 UI와 동기화하기 위해 기존 피처를 삭제합니다.
            geofencing.clearFeatures { clearResult in
                print("Clear features: \(clearResult)")
                if let self = self {
                    geofencing.addObserver(observer: self) { observerResult in
                        print("Add observer: \(observerResult)")
                    }
                }
                completion()
            }
        }
    }

    func add(feature: Turf.Feature, onSuccess: @escaping () -> Void) {
        let geofencing = GeofencingFactory.getOrCreate()
        geofencing.addFeature(feature: feature) { result in
            print("Add feature result: \(result)")
            if case .success = result { onSuccess() }
        }
    }

    func remove(featureId: String, completion: @escaping () -> Void) {
        let geofencing = GeofencingFactory.getOrCreate()
        geofencing.removeFeature(identifier: featureId) { result in
            print("Remove feature result: \(result)")
            completion()
        }
    }
}

extension Geofencing: GeofencingObserver {
    func onEntry(event: GeofencingEvent) {
        DispatchQueue.main.async { self.lastEvent = GeofenceEvent(type: .entry, feature: event.feature) }
    }

    func onDwell(event: GeofencingEvent) {
        DispatchQueue.main.async { self.lastEvent = GeofenceEvent(type: .dwell, feature: event.feature) }
    }

    func onExit(event: GeofencingEvent) {
        DispatchQueue.main.async { self.lastEvent = GeofenceEvent(type: .exit, feature: event.feature) }
    }

    func onError(error: GeofencingError) {}
    func onUserConsentChanged(isConsentGiven: Bool) {}
}

private struct GeofenceEvent {
    enum GeofenceEventType {
        case entry
        case dwell
        case exit
    }

    var type: GeofenceEventType
    var feature: Turf.Feature
}

private extension GeoJSONSourceData {
    static func geofenceCircle(_ center: LocationCoordinate2D) -> GeoJSONSourceData {
        .geometry(.geofenceCircle(center))
    }
}

private extension Turf.Geometry {
    static func geofenceCircle(_ center: LocationCoordinate2D) -> Turf.Geometry {
        .polygon(Polygon(center: center, radius: 30, vertices: 64))
    }
}
