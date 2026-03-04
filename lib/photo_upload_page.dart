import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:autoschool_btgp/auth_service.dart';

class PhotoUploadPage extends StatefulWidget {
  @override
  _PhotoUploadPageState createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  XFile? _image;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _image = image);
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
    setState(() => _isUploading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    String? error = await auth.uploadProfilePhoto(_image!);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      setState(() => _isUploading = false);
    } else {
      // Успех – переход на главный экран
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Загрузка фото'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Добавьте фото профиля',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.blue, width: 2),
                    image: _image != null
                        ? DecorationImage(
                      image: FileImage(File(_image!.path)),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _image == null
                      ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              if (_image != null) ...[
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadImage,
                  child: _isUploading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Загрузить фото'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isUploading ? null : _skip,
                  child: const Text('Пропустить'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _isUploading ? null : _pickImage,
                  child: const Text('Выбрать фото'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isUploading ? null : _skip,
                  child: const Text('Пропустить'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}