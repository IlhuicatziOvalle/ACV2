import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var fastNativeApi: FastNativeApiImpl?
    private var deviceApi: DeviceApiImpl?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Registrar APIs de Pigeon
        guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        
        let binaryMessenger = flutterViewController.binaryMessenger
        
        // Inicializar e instalar FastNativeApi
        fastNativeApi = FastNativeApiImpl(flutterViewController: flutterViewController)
        FastNativeApiSetup.setUp(binaryMessenger: binaryMessenger, api: fastNativeApi)
        
        // Inicializar e instalar DeviceApi
        deviceApi = DeviceApiImpl(flutterViewController: flutterViewController)
        DeviceApiSetup.setUp(binaryMessenger: binaryMessenger, api: deviceApi)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
