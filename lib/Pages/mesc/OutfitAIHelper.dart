import 'package:tflite_flutter/tflite_flutter.dart';

class OutfitAIHelper {
  late final Interpreter interpreter;

  // Adjusted to reflect only top, bottom, shoes (each 6 features) + 4 global features
  final int inputSize = 22; // 4 (context) + 3 * 6

  /// Load the TFLite model
  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/models/big_outfit_model.tflite');

    print('✅ TFLite model loaded');
  }

  /// Predict outfit compatibility
  Future<bool> predict(Map<String, dynamic> inputFeatures) async {
    final input = List.generate(1, (_) => List.filled(inputSize, 0.0));

    // Global context features
    input[0][0] = inputFeatures['temp'] ?? 0.0;
    input[0][1] = inputFeatures['season'] ?? 0.0;
    input[0][2] = inputFeatures['modesty'] ?? 0.0;
    input[0][3] = inputFeatures['occasion'] ?? 0.0;

    // Encoded vectors: top, bottom, shoes (each = 6 values)
    List<double> top = List<double>.from(inputFeatures['top'] ?? []);
    List<double> bottom = List<double>.from(inputFeatures['bottom'] ?? []);
    List<double> shoes = List<double>.from(inputFeatures['shoes'] ?? []);

    for (int i = 0; i < 6; i++) {
      input[0][4 + i] = top[i];
      input[0][10 + i] = bottom[i];
      input[0][16 + i] = shoes[i];
    }

    // Output buffer
    final output = List.generate(1, (_) => List.filled(1, 0.0));

    interpreter.run(input, output);

return output[0][0] >= 0.4; // or even 0.3 temporarily

  }
}
