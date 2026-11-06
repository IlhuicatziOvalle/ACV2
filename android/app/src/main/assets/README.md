# MediaPipe Models

For the Face detection feature (Epic 4) to work, you must download the MediaPipe Face Landmarker task file.

1. Download `face_landmarker.task` from Google MediaPipe:
   https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task

2. Place the file in this directory:
   `android/app/src/main/assets/face_landmarker.task`

If the file is missing, the app will log an error and face detection will not work (it might crash or return empty results).
