import UIKit
import AVFoundation
import MediaPipeTasksVision

/// ViewController para captura y análisis de brazos con MediaPipe Pose Landmarker
class ArmsViewController: UIViewController {
    
    // MARK: - Pose connections (MediaPipe Pose skeleton)
    static let poseConnections: [(Int, Int)] = [
        // Face
        (0, 1), (1, 2), (2, 3), (3, 7), (0, 4), (4, 5), (5, 6), (6, 8),
        (9, 10),
        // Body
        (11, 12), (11, 13), (13, 15), (12, 14), (14, 16),
        (11, 23), (12, 24), (23, 24), (23, 25), (24, 26),
        (25, 27), (26, 28), (27, 29), (28, 30), (29, 31), (30, 32),
        (27, 31), (28, 32),
        // Hands
        (15, 17), (15, 19), (15, 21), (17, 19),
        (16, 18), (16, 20), (16, 22), (18, 20)
    ]
    
    // MARK: - Properties
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let cameraPosition: AVCaptureDevice.Position = .back
    
    private var poseLandmarker: PoseLandmarker?
    private var isProcessing = false
    
    // Overlay para dibujar landmarks
    private let overlayView = ArmsOverlayView()
    
    // Estado del análisis
    private var deltaYLeftValues: [Double] = []
    private var deltaYRightValues: [Double] = []
    private var leftDropDetected = false
    private var rightDropDetected = false
    private var framesProcessed = 0
    private var framesWithPose = 0
    
    // Countdown y gating
    private var posePresent = false
    private var poseBecameStableAt: Date?
    private var countdownDurationMs: Int64 = 5000
    private var countdownEndAt: Date?
    private var pauseStartedAt: Date?
    private var startedOnce = false
    private var sessionStartTime: Date?
    private var noBodyTimeoutMs: Int64 = 30000
    
    // Referencia inicial de muñecas
    private var leftWristInitialY: Float?
    private var rightWristInitialY: Float?
    private var dropThreshold: Float = 0.05 // 5% del alto
    
    private var isFinished = false
    
    // Callback de resultado
    var completion: ((Result<ArmsResult, Error>) -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupOverlay()
        setupPoseLandmarker()
        setupCamera()
        
        sessionStartTime = Date()
        updateOverlay(message: "Levanta ambos brazos horizontalmente", landmarks: nil, connections: nil, countdown: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        overlayView.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    // MARK: - Setup
    
    private func setupOverlay() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupPoseLandmarker() {
        guard let modelPath = Bundle.main.path(forResource: "pose_landmarker_lite", ofType: "task") else {
            finishWithError(PigeonError(code: "MODEL_NOT_FOUND", message: "Modelo pose_landmarker_lite.task no encontrado", details: nil))
            return
        }
        
        do {
            let options = PoseLandmarkerOptions()
            options.baseOptions.modelAssetPath = modelPath
            options.runningMode = .video
            options.minPoseDetectionConfidence = 0.5
            options.minPosePresenceConfidence = 0.5
            options.minTrackingConfidence = 0.5
            options.numPoses = 1
            
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
            finishWithError(error)
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium
        
        // Usar cámara trasera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            finishWithError(PigeonError(code: "CAMERA_NOT_AVAILABLE", message: "Cámara trasera no disponible", details: nil))
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }
        } catch {
            finishWithError(error)
            return
        }
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        videoOutput?.alwaysDiscardsLateVideoFrames = true
        
        if let output = videoOutput, captureSession?.canAddOutput(output) == true {
            captureSession?.addOutput(output)
        }
        
        // Preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.insertSublayer(previewLayer!, at: 0)
        updateVideoConnections()
        
        // Iniciar captura
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    // MARK: - Processing
    
    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isFinished, !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        
        framesProcessed += 1
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Crear imagen para MediaPipe
        guard let image = makeImage(from: pixelBuffer) else { return }
        
        var detected = false
        var normalizedLandmarks: [CGPoint]?
        var connections: [(Int, Int)]?
        
        do {
            let timestampMs = Int(Date().timeIntervalSince1970 * 1000)
            let result = try poseLandmarker?.detect(videoFrame: image, timestampInMilliseconds: timestampMs)
            
            if let poseLandmarks = result?.landmarks, !poseLandmarks.isEmpty {
                detected = true
                framesWithPose += 1
                
                let pose = poseLandmarks[0]
                
                // Mapear todos los 33 landmarks
                normalizedLandmarks = pose.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
                
                // Conectores del esqueleto de pose (definidos manualmente)
                connections = Self.poseConnections
                
                // Índices de MediaPipe Pose:
                // 11 = left_shoulder, 12 = right_shoulder
                // 13 = left_elbow, 14 = right_elbow
                // 15 = left_wrist, 16 = right_wrist
                
                if pose.count > 16 {
                    let leftShoulder = pose[11]
                    let rightShoulder = pose[12]
                    let leftWrist = pose[15]
                    let rightWrist = pose[16]
                    
                    // Establecer posición inicial si no existe
                    if leftWristInitialY == nil {
                        leftWristInitialY = leftWrist.y
                    }
                    if rightWristInitialY == nil {
                        rightWristInitialY = rightWrist.y
                    }
                    
                    // Calcular deltaY (caída relativa al hombro)
                    let deltaYLeft = Double(leftWrist.y - leftShoulder.y)
                    let deltaYRight = Double(rightWrist.y - rightShoulder.y)
                    
                    deltaYLeftValues.append(deltaYLeft)
                    deltaYRightValues.append(deltaYRight)
                    
                    // Detectar caída significativa
                    if let initialY = leftWristInitialY {
                        let drop = leftWrist.y - initialY
                        if drop > dropThreshold {
                            leftDropDetected = true
                        }
                    }
                    
                    if let initialY = rightWristInitialY {
                        let drop = rightWrist.y - initialY
                        if drop > dropThreshold {
                            rightDropDetected = true
                        }
                    }
                }
            }
        } catch {
            print("Error en detección de pose: \(error)")
        }
        
        // Actualizar estado de gating
        let now = Date()
        
        // Timeout sin cuerpo
        if !startedOnce, let sessionStart = sessionStartTime {
            let elapsed = now.timeIntervalSince(sessionStart) * 1000
            if elapsed > Double(noBodyTimeoutMs) {
                DispatchQueue.main.async { [weak self] in
                    self?.updateOverlay(message: "Sin cuerpo detectado", landmarks: nil, connections: nil, countdown: nil)
                    self?.finishAnalysis()
                }
                return
            }
        }
        
        // Actualizar presencia de pose
        if detected {
            if !posePresent {
                posePresent = true
                poseBecameStableAt = now
            }
        } else {
            if posePresent {
                posePresent = false
                pauseStartedAt = now
            }
        }
        
        // Iniciar countdown después de pose estable por 600ms
        if posePresent && countdownEndAt == nil {
            if let stableSince = poseBecameStableAt {
                let stableMs = now.timeIntervalSince(stableSince) * 1000
                if stableMs >= 600 {
                    countdownEndAt = Date(timeIntervalSinceNow: Double(countdownDurationMs) / 1000.0)
                    startedOnce = true
                }
            }
        }
        
        // Pausa/Resume
        if let endAt = countdownEndAt {
            if !posePresent {
                if let pausedAt = pauseStartedAt {
                    let pauseMs = now.timeIntervalSince(pausedAt) * 1000
                    if pauseMs > 1000 {
                        // Reiniciar countdown
                        countdownEndAt = nil
                        poseBecameStableAt = nil
                        pauseStartedAt = nil
                    }
                }
            } else if let pausedAt = pauseStartedAt {
                // Extender countdown
                let pauseDuration = now.timeIntervalSince(pausedAt)
                countdownEndAt = endAt.addingTimeInterval(pauseDuration)
                pauseStartedAt = nil
            }
        }
        
        // Calcular tiempo restante
        var remainingMs: Int64?
        if let endAt = countdownEndAt {
            let remaining = endAt.timeIntervalSince(now) * 1000
            remainingMs = Int64(max(0, remaining))
            
            if remaining <= 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let mapped = normalizedLandmarks.flatMap { self.convertToViewPoints($0) }
                    self.updateOverlay(message: "Listo", landmarks: mapped, connections: connections, countdown: 0)
                    self.finishAnalysis()
                }
                return
            }
        }
        
        // Actualizar overlay
        let msg: String
        if !detected {
            msg = startedOnce ? "Cuerpo perdido, reencuadra" : "Buscando cuerpo..."
        } else if remainingMs == nil {
            msg = "Mantén los brazos extendidos"
        } else {
            msg = "Analizando..."
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let mapped = normalizedLandmarks.flatMap { self.convertToViewPoints($0) }
            self.updateOverlay(message: msg, landmarks: mapped, connections: connections, countdown: remainingMs)
        }
    }
    
    // MARK: - UI Updates
    
    private func updateOverlay(message: String, landmarks: [CGPoint]?, connections: [(Int, Int)]?, countdown: Int64?) {
        overlayView.update(landmarks: landmarks, connections: connections, message: message, countdown: countdown)
    }
    
    // MARK: - Finish
    
    private func finishAnalysis() {
        guard !isFinished else { return }
        isFinished = true
        stopSession()
        
        // Calcular deltaY promedio (máximo de ambos brazos)
        var avgDeltaYLeft = 0.0
        var avgDeltaYRight = 0.0
        
        if !deltaYLeftValues.isEmpty {
            avgDeltaYLeft = deltaYLeftValues.reduce(0, +) / Double(deltaYLeftValues.count)
        }
        if !deltaYRightValues.isEmpty {
            avgDeltaYRight = deltaYRightValues.reduce(0, +) / Double(deltaYRightValues.count)
        }
        
        // Usar el máximo deltaY
        let maxDeltaY = max(avgDeltaYLeft, avgDeltaYRight)
        let dropDetected = leftDropDetected || rightDropDetected
        
        // ArmsResult de Pigeon tiene: deltaY, dropDetected
        let result = ArmsResult(
            deltaY: maxDeltaY,
            dropDetected: dropDetected
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.completion?(.success(result))
            self?.dismiss(animated: true)
        }
    }
    
    private func finishWithError(_ error: Error) {
        guard !isFinished else { return }
        isFinished = true
        stopSession()
        
        DispatchQueue.main.async { [weak self] in
            self?.completion?(.failure(error))
            self?.dismiss(animated: true)
        }
    }
    
    private func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    private func updateVideoConnections() {
        if let connection = previewLayer?.connection {
            connection.videoOrientation = .portrait
        }
        if let videoConnection = videoOutput?.connection(with: .video) {
            videoConnection.videoOrientation = .portrait
        }
    }
    
    private func convertToViewPoints(_ normalizedPoints: [CGPoint]) -> [CGPoint]? {
        guard let previewLayer = previewLayer else { return nil }
        let layerPoints = normalizedPoints.map { previewLayer.layerPointConverted(fromCaptureDevicePoint: $0) }
        return adjustForVideoOrientation(layerPoints)
    }

    private func adjustForVideoOrientation(_ points: [CGPoint]) -> [CGPoint]? {
        guard let orientation = videoOutput?.connection(with: .video)?.videoOrientation else { return points }
        switch orientation {
        case .portrait:
            return rotateCounterClockwise(points)
        case .portraitUpsideDown:
            return rotateClockwise(points)
        default:
            return points
        }
    }

    private func rotateCounterClockwise(_ points: [CGPoint]) -> [CGPoint] {
        let bounds = overlayView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return points }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        return points.map { point in
            let translated = CGPoint(x: point.x - center.x, y: point.y - center.y)
            let rotated = CGPoint(x: translated.y, y: -translated.x)
            return CGPoint(x: rotated.x + center.x, y: rotated.y + center.y)
        }
    }

    private func rotateClockwise(_ points: [CGPoint]) -> [CGPoint] {
        let bounds = overlayView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return points }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        return points.map { point in
            let translated = CGPoint(x: point.x - center.x, y: point.y - center.y)
            let rotated = CGPoint(x: -translated.y, y: translated.x)
            return CGPoint(x: rotated.x + center.x, y: rotated.y + center.y)
        }
    }

    private func makeImage(from pixelBuffer: CVPixelBuffer) -> MPImage? {
        let orientation = imageOrientation(
            for: previewLayer?.connection?.videoOrientation ?? .portrait,
            cameraPosition: cameraPosition
        )
        return try? MPImage(pixelBuffer: pixelBuffer, orientation: orientation)
    }

    private func imageOrientation(for videoOrientation: AVCaptureVideoOrientation, cameraPosition: AVCaptureDevice.Position) -> UIImage.Orientation {
        switch (videoOrientation, cameraPosition) {
        case (.portrait, .front):
            return .leftMirrored
        case (.portrait, _):
            return .right
        case (.portraitUpsideDown, .front):
            return .rightMirrored
        case (.portraitUpsideDown, _):
            return .left
        case (.landscapeLeft, .front):
            return .downMirrored
        case (.landscapeLeft, _):
            return .up
        case (.landscapeRight, .front):
            return .upMirrored
        case (.landscapeRight, _):
            return .down
        @unknown default:
            return .right
        }
    }
    
    // MARK: - Configuration
    
    func configure(durationMs: Int64) {
        self.countdownDurationMs = durationMs
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ArmsViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer)
    }
}

// MARK: - ArmsOverlayView

class ArmsOverlayView: UIView {
    private var landmarks: [CGPoint]?
    private var connections: [(Int, Int)]?
    private var message: String = ""
    private var countdown: Int64?
    
    func update(landmarks: [CGPoint]?, connections: [(Int, Int)]?, message: String, countdown: Int64?) {
        self.landmarks = landmarks
        self.connections = connections
        self.message = message
        self.countdown = countdown
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Dibujar conexiones del esqueleto
        if let points = landmarks, let conns = connections {
            context.setStrokeColor(UIColor.green.withAlphaComponent(0.7).cgColor)
            context.setLineWidth(3)
            
            for (start, end) in conns {
                if start < points.count && end < points.count {
                    let p1 = points[start]
                    let p2 = points[end]
                    
                    context.move(to: p1)
                    context.addLine(to: p2)
                    context.strokePath()
                }
            }
            
            // Dibujar landmarks
            for (index, point) in points.enumerated() {
                let x = point.x
                let y = point.y
                
                // Tamaño diferenciado para muñecas (15, 16), codos (13, 14), hombros (11, 12)
                let radius: CGFloat
                let color: UIColor
                
                if index == 15 || index == 16 { // Wrists
                    radius = 8
                    color = .red
                } else if index == 13 || index == 14 { // Elbows
                    radius = 6
                    color = .orange
                } else if index == 11 || index == 12 { // Shoulders
                    radius = 6
                    color = .yellow
                } else {
                    radius = 4
                    color = .cyan
                }
                
                context.setFillColor(color.cgColor)
                context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
            }
        }
        
        // Dibujar mensaje
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle,
            .backgroundColor: UIColor.black.withAlphaComponent(0.6)
        ]
        
        var displayMessage = message
        if let cd = countdown {
            let seconds = Double(cd) / 1000.0
            displayMessage += String(format: "\n%.1fs", seconds)
        }
        
        let textRect = CGRect(x: 20, y: bounds.height - 100, width: bounds.width - 40, height: 80)
        displayMessage.draw(in: textRect, withAttributes: attrs)
    }
}
