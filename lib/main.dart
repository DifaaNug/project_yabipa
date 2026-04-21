import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart'; 

void main() {
  runApp(const FloraApp());
}

class FloraApp extends StatelessWidget {
  const FloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flora ID (SMP IT YABIPA)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MultimodalGeminiScreen(),
    );
  }
}

class MultimodalGeminiScreen extends StatefulWidget {
  const MultimodalGeminiScreen({super.key});

  @override
  State<MultimodalGeminiScreen> createState() => _MultimodalGeminiScreenState();
}

class _MultimodalGeminiScreenState extends State<MultimodalGeminiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // Instance untuk memilih gambar
  
  // Variabel untuk menyimpan data
  String _response = "Upload foto flora atau ketik pertanyaan di bawah...";
  XFile? _selectedImage; // Menyimpan data gambar sementara
  bool _isLoading = false;

  // 1. FUNGSI UNTUK MEMILIH GAMBAR
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image; // Simpan gambar ke state
        _response = "Gambar terpilih. Silakan ketik pertanyaan atau langsung kirim.";
      });
    }
  }

  // 2. FUNGSI MULTIMODAL GEMINI (KIRIM GAMBAR + TEKS)
  Future<void> askGeminiMultimodal() async {
    // API KEY JANGAN LUPA DIGANTI
    const apiKey = "AIzaSyAGf686CR9cx-lkrxkPORzmXFnQKUN7DzU"; 

    // Pakai Gemini 2.5 Flash yang tadi berhasil
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    
    // Siapkan Prompt Teks (kalau kosong, kita kasih prompt default untuk flora)
    String promptText = _controller.text.isEmpty 
        ? "Identifikasi tumbuhan dalam gambar ini. Berikan nama, deskripsi singkat, dan 1 fakta unik dalam Bahasa Indonesia yang mudah dipahami anak SMP."
        : _controller.text;

    // Siapkan List Content (Multimodal)
    List<Content> content = [];
    
    // Tambahkan Teks Part
    content.add(Content.text(promptText));

    // Tambahkan Gambar Part (jika ada)
    if (_selectedImage != null) {
      // Kita perlu membaca bytes gambar tersebut
      final imageBytes = await _selectedImage!.readAsBytes();
      
      // Buat DataPart (MimeType gambar adalah image/jpeg atau image/png)
      // Kita pakai 'image/jpeg' sebagai default, atau kamu bisa cek detail XFile
      content.add(Content.data('image/jpeg', imageBytes));
    } else {
      // Kalau tidak ada gambar, teks input tidak boleh kosong
      if (_controller.text.isEmpty) {
        setState(() => _response = "Error: Masukkan teks pertanyaan atau pilih gambar dulu!");
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _response = "Gemini sedang 'melihat' dan berpikir...";
    });

    try {
      final response = await model.generateContent(content);
      setState(() {
        _response = response.text ?? "Tidak ada jawaban.";
        _selectedImage = null; // Reset gambar setelah terkirim
        _controller.clear(); // Bersihkan kotak input
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = "Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flora ID & Edukasi Multibahasa"),
        backgroundColor: Colors.green.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _response = "Tampilan direset.";
              });
            }
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // AREA HASIL JAWABAN (Scrollable)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(_response, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // PREVIEW GAMBAR (Hanya muncul kalau sudah dipilih)
            if (_selectedImage != null)
              Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ImagePreviewWidget(xfile: _selectedImage!), // Widget preview khusus web
                ),
              ),
            
            // BAGIAN INPUT (Gambar + Teks + Tombol)
            Row(
              children: [
                // Tombol Ambil Gambar
                IconButton(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.image, size: 30, color: Colors.green),
                ),
                const SizedBox(width: 10),
                
                // Kotak Input Teks
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Tanya tentang Flora ini...",
                      hintText: "Contoh: Ini bunga apa?",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                
                // Tombol Kirim
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : askGeminiMultimodal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget sederhana untuk menampilkan preview gambar dari XFile (Bekerja di Web juga)
class ImagePreviewWidget extends StatelessWidget {
  final XFile xfile;
  const ImagePreviewWidget({super.key, required this.xfile});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Di Web, kita tidak bisa baca file path langsung, harus pakai network image
      return Image.network(xfile.path, fit: BoxFit.cover);
    } else {
      // Kalau di mobile nanti, kodenya akan sedikit beda (pakai Image.file)
      return Container(child: const Text("Preview Mobile belum dibuat")); 
    }
  }
}