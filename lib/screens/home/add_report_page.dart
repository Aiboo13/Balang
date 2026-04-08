import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AddReportPage extends StatefulWidget {
  final String? docId; // ID dokumen jika mode edit
  final Map<String, dynamic>? existingData; // Data lama jika mode edit

  const AddReportPage({super.key, this.docId, this.existingData});

  @override
  State<AddReportPage> createState() => _AddReportPageState();
}

class _AddReportPageState extends State<AddReportPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _dateController;

  String _selectedCategory = 'Kehilangan';
  String? _base64Image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Jika mode edit, isi controller dengan data lama
    _titleController = TextEditingController(
      text: widget.existingData?['title'] ?? '',
    );
    _descController = TextEditingController(
      text: widget.existingData?['description'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.existingData?['location'] ?? '',
    );
    _dateController = TextEditingController(
      text: widget.existingData?['date'] ?? '',
    );
    _selectedCategory = widget.existingData?['category'] ?? 'Kehilangan';
    _base64Image = widget.existingData?['imageUrl'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User tidak terautentikasi';

      final reportData = {
        'userId': user.uid, // Sangat penting untuk filter di HistoryPage
        'title': _titleController.text,
        'description': _descController.text,
        'location': _locationController.text,
        'date': _dateController.text,
        'category': _selectedCategory,
        'imageUrl': _base64Image,
        'reportStatus':
            widget.existingData?['reportStatus'] ??
            'Aktif', // Tetap gunakan status lama jika edit
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        // MODE EDIT: Update dokumen yang sudah ada
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.docId)
            .update(reportData);

        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Laporan diperbarui!')));
      } else {
        // MODE BARU: Tambah dokumen baru
        reportData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('reports').add(reportData);

        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil dikirim!')),
          );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.docId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Laporan' : 'Tambah Laporan'),
        backgroundColor: const Color(0xFF0900FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- Picker Gambar ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _base64Image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.memory(
                                  base64Decode(_base64Image!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    'Ketuk untuk pilih gambar',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Input Judul ---
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Barang',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 15),

                    // --- Dropdown Kategori ---
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Kehilangan', 'Temuan']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                    const SizedBox(height: 15),

                    // --- Lokasi & Tanggal ---
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Kejadian',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Kejadian',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 15),

                    // --- Deskripsi ---
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Detail',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 30),

                    // --- Tombol Simpan ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0900FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEdit ? 'SIMPAN PERUBAHAN' : 'KIRIM LAPORAN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
