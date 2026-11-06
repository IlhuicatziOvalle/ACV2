import Foundation
import Speech
import AVFoundation

/// Motor de reconocimiento de voz usando Speech framework de Apple
class SpeechEngine {
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    private var isRecording = false
    
    init() {
        // Inicializar reconocedor en español
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
        }
    }
    
    /// Solicita permisos de reconocimiento de voz
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    /// Graba y reconoce habla por los segundos especificados
    func recognize(maxSeconds: Int, completion: @escaping (String?, Error?) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(nil, PigeonError(code: "SPEECH_NOT_AVAILABLE", message: "Reconocimiento de voz no disponible", details: nil))
            return
        }
        
        // Cancelar tarea anterior si existe
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configurar sesión de audio
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion(nil, error)
            return
        }
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            completion(nil, PigeonError(code: "AUDIO_ENGINE_ERROR", message: "No se pudo crear el motor de audio", details: nil))
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            completion(nil, PigeonError(code: "REQUEST_ERROR", message: "No se pudo crear la solicitud de reconocimiento", details: nil))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        // Forzar reconocimiento en dispositivo si está disponible (offline)
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        var finalTranscript = ""
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                finalTranscript = result.bestTranscription.formattedString
            }
            
            if error != nil || (result?.isFinal ?? false) {
                // La grabación terminó
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            completion(nil, error)
            return
        }
        
        // Detener después de maxSeconds
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(maxSeconds)) { [weak self] in
            self?.stopRecording()
            
            // Pequeño delay para asegurar que se procese el último audio
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(finalTranscript, nil)
            }
        }
    }
    
    /// Detiene la grabación
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    /// Calcula la similitud entre dos strings usando distancia de Levenshtein
    func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let s1 = normalizeText(text1)
        let s2 = normalizeText(text2)
        
        if s1.isEmpty && s2.isEmpty { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }
        
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    /// Clasifica el nivel según la similitud
    func classifyLevel(_ similarity: Double) -> String {
        if similarity >= 0.80 {
            return "Sin"
        } else if similarity >= 0.60 {
            return "Leve"
        } else {
            return "Fuerte"
        }
    }
    
    // MARK: - Private helpers
    
    private func normalizeText(_ text: String) -> String {
        let lowercased = text.lowercased()
        
        // Remover acentos
        let withoutAccents = lowercased
            .folding(options: .diacriticInsensitive, locale: .current)
        
        // Remover puntuación y espacios extra
        let cleaned = withoutAccents
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        return cleaned
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let m = s1.count
        let n = s2.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // Deletion
                    matrix[i][j - 1] + 1,      // Insertion
                    matrix[i - 1][j - 1] + cost // Substitution
                )
            }
        }
        
        return matrix[m][n]
    }
    
    deinit {
        stopRecording()
    }
}
