import UIKit
import AVFoundation
import Speech

/// Implementación de FastNativeApi para iOS
class FastNativeApiImpl: FastNativeApi {
    
    // Cambiamos a strong reference ya que el VC vive durante toda la app
    private var flutterViewController: FlutterViewController?
    private var speechEngine: SpeechEngine?
    
    init(flutterViewController: FlutterViewController) {
        self.flutterViewController = flutterViewController
        print("🔧 FastNativeApiImpl initialized with FlutterViewController")
    }
    
    // MARK: - FastNativeApi Protocol
    
    func initialize() throws {
        // Solicitar permisos necesarios
        requestPermissions()
        
        // Inicializar motor de reconocimiento de voz
        speechEngine = SpeechEngine()
    }
    
    func runSpeech(targetPhrase: String, maxSeconds: Int64, completion: @escaping (Result<SpeechResult, Error>) -> Void) {
        guard let engine = speechEngine else {
            completion(.failure(PigeonError(code: "NOT_INITIALIZED", message: "Motor de voz no inicializado", details: nil)))
            return
        }
        
        // Verificar permisos de micrófono y reconocimiento
        checkSpeechPermissions { [weak self] granted in
            guard granted else {
                completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Permiso de micrófono o reconocimiento de voz denegado", details: nil)))
                return
            }
            
            engine.recognize(maxSeconds: Int(maxSeconds)) { transcript, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                let recognizedText = transcript ?? ""
                let similarity = engine.calculateSimilarity(recognizedText, targetPhrase)
                let level = engine.classifyLevel(similarity)
                
                let result = SpeechResult(
                    transcript: recognizedText,
                    similarity: similarity,
                    level: level
                )
                
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            }
        }
    }
    
    func runFace(maxMillis: Int64, completion: @escaping (Result<FaceResult, Error>) -> Void) {
        // Verificar estado del permiso
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 Camera permission status: \(status.rawValue)")
        
        if status == .authorized {
            // Permiso ya concedido, proceder directamente
            DispatchQueue.main.async { [weak self] in
                guard let vc = self?.flutterViewController else {
                    print("❌ FlutterViewController is nil")
                    completion(.failure(PigeonError(code: "NO_VIEW_CONTROLLER", message: "FlutterViewController no disponible", details: nil)))
                    return
                }
                
                print("✅ Presenting FaceViewController")
                let faceVC = FaceViewController()
                faceVC.configure(durationMs: maxMillis)
                faceVC.completion = completion
                faceVC.modalPresentationStyle = .fullScreen
                vc.present(faceVC, animated: true)
            }
        } else if status == .notDetermined {
            // Solicitar permiso
            print("📷 Requesting camera permission...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("📷 Permission granted: \(granted)")
                if granted {
                    DispatchQueue.main.async {
                        guard let vc = self?.flutterViewController else {
                            completion(.failure(PigeonError(code: "NO_VIEW_CONTROLLER", message: "FlutterViewController no disponible", details: nil)))
                            return
                        }
                        
                        let faceVC = FaceViewController()
                        faceVC.configure(durationMs: maxMillis)
                        faceVC.completion = completion
                        faceVC.modalPresentationStyle = .fullScreen
                        vc.present(faceVC, animated: true)
                    }
                } else {
                    completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Permiso de cámara denegado", details: nil)))
                }
            }
        } else {
            // Permiso denegado o restringido
            print("❌ Camera permission denied or restricted")
            DispatchQueue.main.async { [weak self] in
                guard let vc = self?.flutterViewController else {
                    completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Permiso de cámara denegado", details: nil)))
                    return
                }
                
                let alert = UIAlertController(
                    title: "Permiso de Cámara Requerido",
                    message: "Esta función necesita acceso a la cámara. Por favor habilita el permiso en Configuración.",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in
                    completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Permiso de cámara denegado", details: nil)))
                })
                
                alert.addAction(UIAlertAction(title: "Abrir Configuración", style: .default) { _ in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                    completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Permiso de cámara denegado", details: nil)))
                })
                
                vc.present(alert, animated: true)
            }
        }
    }
    
    func runArms(seconds: Int64, completion: @escaping (Result<ArmsResult, Error>) -> Void) {
        checkCameraPermissionWithPrompt { [weak self] granted in
            guard granted else {
                completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Permiso de cámara denegado. Ve a Configuración > Privacidad > Cámara para habilitarlo.", details: nil)))
                return
            }
            
            DispatchQueue.main.async {
                guard let vc = self?.flutterViewController else {
                    completion(.failure(PigeonError(code: "NO_VIEW_CONTROLLER", message: "FlutterViewController no disponible", details: nil)))
                    return
                }
                
                let armsVC = ArmsViewController()
                armsVC.configure(durationMs: seconds * 1000)
                armsVC.completion = completion
                armsVC.modalPresentationStyle = .fullScreen
                vc.present(armsVC, animated: true)
            }
        }
    }
    
    func dispose() throws {
        speechEngine?.stopRecording()
        speechEngine = nil
    }
    
    // MARK: - Private Methods
    
    private func requestPermissions() {
        // Cámara - solicitar primero ya que es el más importante para Face/Arms
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }
        
        // Micrófono
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        
        // Reconocimiento de voz
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    private func checkSpeechPermissions(completion: @escaping (Bool) -> Void) {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let audioSession = AVAudioSession.sharedInstance()
        
        switch speechStatus {
        case .authorized:
            // Verificar también permiso de micrófono
            switch audioSession.recordPermission {
            case .granted:
                completion(true)
            case .undetermined:
                audioSession.requestRecordPermission { granted in
                    completion(granted)
                }
            default:
                completion(false)
            }
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                if status == .authorized {
                    // Verificar también permiso de micrófono
                    switch audioSession.recordPermission {
                    case .granted:
                        completion(true)
                    case .undetermined:
                        audioSession.requestRecordPermission { granted in
                            completion(granted)
                        }
                    default:
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        default:
            completion(false)
        }
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    private func checkCameraPermissionWithPrompt(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            // Mostrar alerta para ir a Configuración
            DispatchQueue.main.async { [weak self] in
                guard let vc = self?.flutterViewController else {
                    completion(false)
                    return
                }
                
                let alert = UIAlertController(
                    title: "Permiso de Cámara Requerido",
                    message: "Esta función necesita acceso a la cámara. Por favor habilita el permiso en Configuración.",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in
                    completion(false)
                })
                
                alert.addAction(UIAlertAction(title: "Abrir Configuración", style: .default) { _ in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                    completion(false)
                })
                
                vc.present(alert, animated: true)
            }
        @unknown default:
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}
