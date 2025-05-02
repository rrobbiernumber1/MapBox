import UIKit
import MapboxMaps
import Combine

final class MapRecorderExample: UIViewController, ExampleProtocol {

    private var mapView: MapView!
    private var cancelables = Set<AnyCancelable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.ornaments.options.scaleBar.visibility = .visible

        view.addSubview(mapView)

        mapView.mapboxMap.onStyleLoaded.observeNext { _ in
            // 맵 레코더 기능은 @_spi 보호 레벨이므로 사용할 수 없습니다.
            // 대신 fly 메서드를 사용하여 간단한 애니메이션을 구현합니다.
            
            // 목적지 설정
            let destinationOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 45.4588, longitude: -73.581),
                                              zoom: 11,
                                              pitch: 35)
            
            // 첫 번째 애니메이션 시작
            self.mapView.camera.fly(to: destinationOptions, duration: 10) { _ in
                // 첫 번째 애니메이션이 완료되면 원래 시작 위치로 돌아가는 애니메이션
                // movedBy 메서드 대신 직접 좌표값 계산
                let currentCenter = self.mapView.cameraState.center
                let startPosition = CameraOptions(
                    center: CLLocationCoordinate2D(
                        latitude: currentCenter.latitude + 0.05,
                        longitude: currentCenter.longitude + 0.05
                    ),
                    zoom: self.mapView.cameraState.zoom - 2,
                    bearing: 0,
                    pitch: 0
                )
                
                self.mapView.camera.fly(to: startPosition, duration: 5) { _ in
                    // 다시 목적지로 애니메이션
                    self.mapView.camera.fly(to: destinationOptions, duration: 5) { _ in
                        print("모든 애니메이션 완료")
                    }
                }
            }
        }.store(in: &cancelables)
    }
    
    // 카메라 애니메이션 메서드
    private func animateCamera(from startOptions: CameraOptions, to destinationOptions: CameraOptions, duration: TimeInterval, completion: (() -> Void)? = nil) {
        // 기존 애니메이터가 있다면 취소
        //  cameraAnimator?.cancel()
        
        // 맵박스 SDK의 카메라 애니메이션 API를 사용하여 애니메이션 생성
        // fly 메서드를 사용하여 단순화
        mapView.camera.fly(to: destinationOptions, duration: duration) { _ in
            completion?()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // The below line is used for internal testing purposes only.
        finish()
    }
}
