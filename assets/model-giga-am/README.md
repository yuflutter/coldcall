Распаковать скачанные архивы, и положить в корень /assets/ все три файла:
- model.int8.onnx
- silero_vad.onnx
- tokens.txt

Реализация на базе GigaAM v2 (Sber/NeMo CTC) + Silero VAD.

Модели (~228 MB суммарно):
    - model.int8.onnx  — скачать из:
    https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-ctc-giga-am-v2-russian-2025-04-19.tar.bz2
    
    - tokens.txt       — из того же архива

    - silero_vad.onnx  — скачать из:
    https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx

