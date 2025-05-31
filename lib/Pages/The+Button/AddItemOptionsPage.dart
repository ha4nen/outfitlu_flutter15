import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../mesc/loading_page.dart';
import 'ConfirmPhotoPage.dart';

class AddItemOptionsPage extends StatelessWidget {
  const AddItemOptionsPage({super.key});

  Future<File?> removeBackground(File imageFile) async {
    final apiKey = 'Ei2ToMiKZrvmjJiGN26dbaMQ';
    final url = Uri.parse('https://api.remove.bg/v1.0/removebg');

    final request = http.MultipartRequest('POST', url)
      ..headers['X-Api-Key'] = apiKey
      ..files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final output = await getTemporaryDirectory();
      final resultFile = File('${output.path}/cutout.png');
      await response.stream.pipe(resultFile.openWrite());
      return resultFile;
    } else {
      final body = await response.stream.bytesToString();
      print('Background removal failed: ${response.statusCode}, $body');
      return null;
    }
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final originalFile = File(pickedFile.path);

      // Show loading UI
      Navigator.push(
        context,
         MaterialPageRoute(
          builder:
              (_) => LoadingPage(
                imageFile: File(pickedFile.path),
                nextPageBuilder:
                    () => ConfirmPhotoPage(
                      imageFile: File(pickedFile.path),
                    ), // Navigate to ConfirmYourPhotoPage
              ),
        ),
      );

      final cutoutFile = await removeBackground(originalFile);

      if (cutoutFile != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmPhotoPage(imageFile: cutoutFile),
          ),
        );
      } else {
        Navigator.pop(context); // Dismiss loading screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to remove background.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        "Add Item",
        style: TextStyle(color: textColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
            title: Text(
              "Take a Photo",
              style: TextStyle(color: textColor),
            ),
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: theme.colorScheme.primary),
            title: Text(
              "Choose from Library",
              style: TextStyle(color: textColor),
            ),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
