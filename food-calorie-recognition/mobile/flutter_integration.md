# Flutter Integration Notes

The training script exports:

```text
models/food_calorie_model.tflite
models/class_names.json
data/myfcd_cache.sqlite
```

Copy those files into your Flutter app assets, for example:

```text
assets/ml/food_calorie_model.tflite
assets/ml/class_names.json
assets/ml/myfcd_cache.sqlite
```

Add them to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/ml/food_calorie_model.tflite
    - assets/ml/class_names.json
    - assets/ml/myfcd_cache.sqlite
```

Use a Flutter TFLite package such as `tflite_flutter`. Feed a `224x224x3`
float input in RGB order. The model contains preprocessing, so pass raw pixel
values in the `0..255` range as `float32`.

Recommended mobile settings:

- Prefer the quantized `.tflite` model for smaller file size and faster CPU inference.
- Keep labels and calorie metadata versioned with the model file.
- Run prediction off the UI thread.
- Use a confidence threshold such as `0.60` before auto-logging food.
- For portion size, ask users to confirm serving size unless depth/reference-object data exists.
- Prefer the FastAPI `/predict` endpoint while the model is still improving.
- Only ship the local TFLite model after `scripts/evaluate_and_promote.py` passes.
