import 'package:tflite_flutter/tflite_flutter.dart';

class OutfitAIHelper {
  Interpreter? interpreter; // Nullable

  final int inputSize = 34;

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset(
      'models/full_outfit_model.tflite',
    );
    print('✅ TFLite model loaded');
  }

  Future<bool> predict(Map<String, dynamic> inputFeatures) async {
    if (interpreter == null) {
      print('⚠️ Interpreter not loaded yet');
      return false;
    }

    final input = List.generate(1, (_) => List.filled(inputSize, 0.0));

    input[0][0] = inputFeatures['temp'] ?? 0.0;
    input[0][1] = inputFeatures['season'] ?? 0.0;
    input[0][2] = inputFeatures['modesty'] ?? 0.0;
    input[0][3] = inputFeatures['occasion'] ?? 0.0;

    List<double> top1 = List<double>.from(
      inputFeatures['top1'] ?? List.filled(6, 0.0),
    );
    List<double> top2 = List<double>.from(
      inputFeatures['top2'] ?? List.filled(6, 0.0),
    );
    List<double> bottom = List<double>.from(
      inputFeatures['bottom'] ?? List.filled(6, 0.0),
    );
    List<double> shoes = List<double>.from(
      inputFeatures['shoes'] ?? List.filled(6, 0.0),
    );
    List<double> accessory = List<double>.from(
      inputFeatures['accessory'] ?? List.filled(6, 0.0),
    );

    for (int i = 0; i < 6; i++) {
      input[0][4 + i] = top1[i];
      input[0][10 + i] = top2[i];
      input[0][16 + i] = bottom[i];
      input[0][22 + i] = shoes[i];
      input[0][28 + i] = accessory[i];
    }

    final output = List.generate(1, (_) => List.filled(1, 0.0));
    interpreter!.run(input, output); // now safe to use with !

    return output[0][0] >= 0.4;
  }
}
