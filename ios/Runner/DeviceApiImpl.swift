import UIKit
import MessageUI
import CoreLocation

/// Implementación de DeviceApi para iOS
class DeviceApiImpl: NSObject, DeviceApi {
    
    private weak var flutterViewController: FlutterViewController?
    private var locationManager: CLLocationManager?
    private var currentLocation: CLLocation?
    private var smsCompletion: ((Bool) -> Void)?
    
    init(flutterViewController: FlutterViewController) {
        self.flutterViewController = flutterViewController
        super.init()
        setupLocationManager()
    }
    
    // MARK: - DeviceApi Protocol
    
    func placeCall911() throws -> Bool {
        guard let url = URL(string: "tel://911") else {
            throw PigeonError(code: "INVALID_URL", message: "No se pudo crear URL de llamada", details: nil)
        }
        
        guard UIApplication.shared.canOpenURL(url) else {
            throw PigeonError(code: "CANNOT_CALL", message: "El dispositivo no puede realizar llamadas", details: nil)
        }
        
        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { opened in
                success = opened
                semaphore.signal()
            }
        }
        
        _ = semaphore.wait(timeout: .now() + 5)
        return success
    }
    
    func sendEmergencySms(message: String, includeLocation: Bool) throws -> Bool {
        guard MFMessageComposeViewController.canSendText() else {
            throw PigeonError(code: "CANNOT_SEND_SMS", message: "El dispositivo no puede enviar SMS", details: nil)
        }
        
        var finalMessage = message
        
        if includeLocation, let location = currentLocation {
            let locationString = String(format: "\nUbicación: https://maps.google.com/?q=%.6f,%.6f",
                                        location.coordinate.latitude,
                                        location.coordinate.longitude)
            finalMessage += locationString
        }
        
        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.async { [weak self] in
            guard let vc = self?.flutterViewController else {
                semaphore.signal()
                return
            }
            
            let composeVC = MFMessageComposeViewController()
            composeVC.messageComposeDelegate = self
            composeVC.body = finalMessage
            // Número de emergencia (puede configurarse según el país)
            composeVC.recipients = ["911"]
            
            self?.smsCompletion = { sent in
                success = sent
                semaphore.signal()
            }
            
            vc.present(composeVC, animated: true)
        }
        
        // Esperar hasta 60 segundos por interacción del usuario
        _ = semaphore.wait(timeout: .now() + 60)
        return success
    }
    
    // MARK: - Location
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        
        // Solicitar permiso si no se ha determinado
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        }
        
        // Iniciar actualizaciones de ubicación
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
           CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        }
    }
}

// MARK: - MFMessageComposeViewControllerDelegate

extension DeviceApiImpl: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        let success = result == .sent
        controller.dismiss(animated: true) { [weak self] in
            self?.smsCompletion?(success)
            self?.smsCompletion = nil
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension DeviceApiImpl: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager?.startUpdatingLocation()
        }
    }
}
