import UIKit
import AVFoundation
import MediaPipeTasksVision

/// ViewController para captura y análisis facial con MediaPipe
class FaceViewController: UIViewController {
    
    // MARK: - Properties
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private lazy var cameraSwitchButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 22
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleCameraSwitch), for: .touchUpInside)
        return button
    }()
    
    private var faceLandmarker: FaceLandmarker?
    private var isProcessing = false
    
    // Overlay para dibujar landmarks
    private let overlayView = FaceOverlayView()
    
    // Estado del análisis
    private var asymmetryScores: [Double] = []
    private var facesFoundCount = 0
    private var framesProcessed = 0
    private var lowLightFrames = 0
    
    // EMA State
    private var smileLeftSmoothed: Float = 0.0
    private var smileRightSmoothed: Float = 0.0
    private let alpha: Float = 0.2

    // Analysis state (New Logic)
    private var votingWindow: [Bool] = []
    private let votingWindowSize = 20
    
    // Countdown gated
    private var facePresent = false
    private var faceBecameStableAt: Date?
    private var countdownDurationMs: Int64 = 5000
    private var countdownEndAt: Date?
    private var pauseStartedAt: Date?
    private var startedOnce = false
    private var sessionStartTime: Date?
    private var noFaceTimeoutMs: Int64 = 30000
    
    private var isFinished = false
    
    // Callback de resultado
    var completion: ((Result<FaceResult, Error>) -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupOverlay()
        setupFaceLandmarker()
        setupCamera()
        setupCameraSwitchButton()
        
        sessionStartTime = Date()
        updateOverlay(message: "Enfoca el rostro dentro del recuadro")
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
    
    private func setupFaceLandmarker() {
        guard let modelPath = Bundle.main.path(forResource: "face_landmarker", ofType: "task") else {
            finishWithError(PigeonError(code: "MODEL_NOT_FOUND", message: "Modelo face_landmarker.task no encontrado", details: nil))
            return
        }
        
        do {
            let options = FaceLandmarkerOptions()
            options.baseOptions.modelAssetPath = modelPath
            options.runningMode = .video
            options.minFaceDetectionConfidence = 0.5
            options.minFacePresenceConfidence = 0.5
            options.minTrackingConfidence = 0.5
            options.numFaces = 1
            options.outputFaceBlendshapes = true
            
            faceLandmarker = try FaceLandmarker(options: options)
        } catch {
            finishWithError(error)
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            finishWithError(PigeonError(code: "CAMERA_NOT_AVAILABLE", message: "Cámara no disponible", details: nil))
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
    
    private func setupCameraSwitchButton() {
        view.addSubview(cameraSwitchButton)
        NSLayoutConstraint.activate([
            cameraSwitchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cameraSwitchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cameraSwitchButton.widthAnchor.constraint(equalToConstant: 44),
            cameraSwitchButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func handleCameraSwitch() {
        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        reconfigureSessionForCurrentCamera()
    }
    
    private func reconfigureSessionForCurrentCamera() {
        guard let session = captureSession else {
            setupCamera()
            return
        }
        session.beginConfiguration()
        let previousInputs = session.inputs.compactMap { $0 as? AVCaptureDeviceInput }
        previousInputs.forEach { session.removeInput($0) }
        do {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
                previousInputs.forEach { session.addInput($0) }
                session.commitConfiguration()
                return
            }
            let newInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            } else {
                previousInputs.forEach { session.addInput($0) }
            }
        } catch {
            previousInputs.forEach { session.addInput($0) }
            session.commitConfiguration()
            return
        }
        session.commitConfiguration()
        updateVideoConnections()
    }
    
    private func updateVideoConnections() {
        if let connection = previewLayer?.connection {
            connection.videoOrientation = .portrait
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = currentCameraPosition == .front
        }
        if let videoConnection = videoOutput?.connection(with: .video) {
            videoConnection.videoOrientation = .portrait
            videoConnection.isVideoMirrored = false
        }
    }
    
    // MARK: - Processing
    
    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isFinished, !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }
        
        framesProcessed += 1
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Verificar luz baja
        let lowLight = isLowLight(pixelBuffer)
        if lowLight { lowLightFrames += 1 }
        
        // Crear imagen para MediaPipe
        guard let image = try? MPImage(pixelBuffer: pixelBuffer) else { return }
        
        var detected = false
        var asymmetry: Double = 0.0
        var normalizedLandmarks: [CGPoint]?
        
        do {
            let timestampMs = Int(Date().timeIntervalSince1970 * 1000)
            let result = try faceLandmarker?.detect(videoFrame: image, timestampInMilliseconds: timestampMs)
            
            if let faceLandmarks = result?.faceLandmarks, !faceLandmarks.isEmpty {
                detected = true
                facesFoundCount += 1
                
                let face = faceLandmarks[0]
                normalizedLandmarks = face.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
                
                // Blendshapes logic
                if let blendshapes = result?.faceBlendshapes, !blendshapes.isEmpty {
                    // blendshapes[0] es [Classifications], pero en Swift puede ser [Classifications] directamente o similar.
                    // Verificando la API: result.faceBlendshapes es [Classifications].
                    // Classifications tiene .categories que es [Category].
                    let categories = blendshapes[0].categories
                    
                    var rawSmileLeft: Float = 0.0
                    var rawSmileRight: Float = 0.0
                    
                    for category in categories {
                        if category.categoryName == "mouthSmileLeft" {
                            rawSmileLeft = category.score
                        }
                        if category.categoryName == "mouthSmileRight" {
                            rawSmileRight = category.score
                        }
                    }
                    
                    // EMA Smoothing
                    smileLeftSmoothed = alpha * rawSmileLeft + (1.0 - alpha) * smileLeftSmoothed
                    smileRightSmoothed = alpha * rawSmileRight + (1.0 - alpha) * smileRightSmoothed
                    
                    // Check Activation
                    let maxSmile = max(smileLeftSmoothed, smileRightSmoothed)
                    let isSmiling = maxSmile >= 0.30
                    
                    // Calculate Delta
                    let delta = abs(smileLeftSmoothed - smileRightSmoothed)
                    asymmetry = Double(delta)
                    
                    // Classify Frame
                    var isAsymmetricFrame = false
                    if isSmiling {
                        let symmetric = (smileLeftSmoothed > 0.28 && smileRightSmoothed > 0.28 && delta < 0.12)
                        if !symmetric {
                            isAsymmetricFrame = true
                        }
                        
                        // Voting window
                        if votingWindow.count >= votingWindowSize {
                            votingWindow.removeFirst()
                        }
                        votingWindow.append(isAsymmetricFrame)
                    }
                }
            }
        } catch {
            print("Error en detección facial: \(error)")
        }
        
        // Actualizar estado de gating
        let now = Date()
        
        // Timeout sin rostro
        if !startedOnce, let sessionStart = sessionStartTime {
            let elapsed = now.timeIntervalSince(sessionStart) * 1000
            if elapsed > Double(noFaceTimeoutMs) {
                DispatchQueue.main.async { [weak self] in
                    self?.updateOverlay(message: "Sin rostro detectado")
                    self?.finishAnalysis()
                }
                return
            }
        }
        
        // Actualizar presencia de rostro
        if detected {
            if !facePresent {
                facePresent = true
                faceBecameStableAt = now
            }
        } else {
            if facePresent {
                facePresent = false
                pauseStartedAt = now
            }
        }
        
        // Iniciar countdown después de rostro estable por 600ms
        if facePresent && countdownEndAt == nil {
            if let stableSince = faceBecameStableAt {
                let stableMs = now.timeIntervalSince(stableSince) * 1000
                if stableMs >= 600 {
                    countdownEndAt = Date(timeIntervalSinceNow: Double(countdownDurationMs) / 1000.0)
                    startedOnce = true
                }
            }
        }
        
        // Pausa/Resume
        if let endAt = countdownEndAt {
            if !facePresent {
                if let pausedAt = pauseStartedAt {
                    let pauseMs = now.timeIntervalSince(pausedAt) * 1000
                    if pauseMs > 1000 {
                        // Reiniciar countdown
                        countdownEndAt = nil
                        faceBecameStableAt = nil
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
                let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
                let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
                let isFront = self.currentCameraPosition == .front

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    let viewWidth = self.view.bounds.width
                    let viewHeight = self.view.bounds.height
                    let scale = max(viewWidth / imageWidth, viewHeight / imageHeight)
                    let scaledW = imageWidth * scale
                    let scaledH = imageHeight * scale
                    let offX = (viewWidth - scaledW) / 2.0
                    let offY = (viewHeight - scaledH) / 2.0
                    
                    let mapped = normalizedLandmarks?.map { point -> CGPoint in
                        var x = point.x
                        if isFront { x = 1.0 - x }
                        return CGPoint(
                            x: (x * imageWidth) * scale + offX,
                            y: (point.y * imageHeight) * scale + offY
                        )
                    }

                    self.updateOverlay(message: "Listo", landmarks: mapped, countdown: 0, lowLight: lowLight)
                    self.finishAnalysis()
                }
                return
            }
        }
        
        // Actualizar overlay
        let msg: String
        if !detected {
            msg = startedOnce ? "Rostro perdido, reencuadra" : "Buscando rostro..."
        } else if remainingMs == nil {
            msg = "Mantén el rostro quieto"
        } else {
            msg = "Analizando..."
        }
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let isFront = self.currentCameraPosition == .front

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            let viewWidth = self.view.bounds.width
            let viewHeight = self.view.bounds.height
            let scale = max(viewWidth / imageWidth, viewHeight / imageHeight)
            let scaledW = imageWidth * scale
            let scaledH = imageHeight * scale
            let offX = (viewWidth - scaledW) / 2.0
            let offY = (viewHeight - scaledH) / 2.0
            
            let mapped = normalizedLandmarks?.map { point -> CGPoint in
                var x = point.x
                if isFront { x = 1.0 - x }
                return CGPoint(
                    x: (x * imageWidth) * scale + offX,
                    y: (point.y * imageHeight) * scale + offY
                )
            }

            self.updateOverlay(message: msg, landmarks: mapped, countdown: remainingMs, lowLight: lowLight)
        }
    }
    
    private func isLowLight(_ pixelBuffer: CVPixelBuffer) -> Bool {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return false }
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        var sum: Int64 = 0
        let sampleStep = 10 // Muestrear cada 10 píxeles
        var count: Int64 = 0
        
        for y in stride(from: 0, to: height, by: sampleStep) {
            for x in stride(from: 0, to: width, by: sampleStep) {
                let offset = y * bytesPerRow + x * 4
                let b = Int64(buffer[offset])
                let g = Int64(buffer[offset + 1])
                let r = Int64(buffer[offset + 2])
                let luminance = (r + g + b) / 3
                sum += luminance
                count += 1
            }
        }
        
        let average = count > 0 ? sum / count : 0
        return average < 50
    }
    
    // MARK: - UI Updates
    
    private func updateOverlay(message: String, landmarks: [CGPoint]? = nil, countdown: Int64? = nil, lowLight: Bool = false) {
        overlayView.update(
            landmarks: landmarks,
            message: message,
            countdown: countdown,
            lowLight: lowLight
        )
    }
    

    // MARK: - Finish
    
    private func finishAnalysis() {
        guard !isFinished else { return }
        isFinished = true
        stopSession()
        
        let faceFound = facesFoundCount > (framesProcessed / 10)
        let isLowLight = lowLightFrames > (framesProcessed / 2)
        
        // Calculate final result based on voting
        var asymmetricVotes = 0
        for vote in votingWindow {
            if vote { asymmetricVotes += 1 }
        }
        
        // Threshold: 12/20 (60%)
        // Si hay suficientes votos de asimetría en la ventana reciente, se considera asimétrico
        let isAsymmetric = asymmetricVotes >= 12
        
        let finalAsymmetry = isAsymmetric ? 1.0 : 0.0
        let level = isAsymmetric ? "Fuerte" : "Sin"
        
        let result = FaceResult(
            asymmetry: finalAsymmetry,
            level: level,
            faceFound: faceFound,
            lowLight: isLowLight
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
    
    // MARK: - Configuration
    
    func configure(durationMs: Int64) {
        self.countdownDurationMs = durationMs
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension FaceViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer)
    }
}

// MARK: - FaceOverlayView

class FaceOverlayView: UIView {
    private var landmarks: [CGPoint]?
    private var message: String = ""
    private var countdown: Int64?
    private var lowLight: Bool = false
    
    func update(landmarks: [CGPoint]?, message: String, countdown: Int64?, lowLight: Bool) {
        self.landmarks = landmarks
        self.message = message
        self.countdown = countdown
        self.lowLight = lowLight
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Dibujar landmarks si hay
        if let points = landmarks, !points.isEmpty {
            context.setFillColor(UIColor.yellow.withAlphaComponent(0.8).cgColor)
            
            for point in points {
                context.fillEllipse(in: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
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
        if lowLight {
            displayMessage += "\n⚠️ Poca luz"
        }
        
        let textRect = CGRect(x: 20, y: bounds.height - 120, width: bounds.width - 40, height: 100)
        displayMessage.draw(in: textRect, withAttributes: attrs)
    }
}
