import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Decrypter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const QRScannerPage(),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  String decryptedData = '';
  bool hasScanned = false;
  static const String privateKey = 'your-secret-key'; // Replace with your actual secret key, same as Next.js

  List<Uint8List> _generateKeyAndIV(String passphrase, List<int> salt) {
    const keyLength = 32;
    const ivLength = 16;
    List<int> keyAndIV = [];
    List<int> currentHash = [];
    List<int> passwordBytes = utf8.encode(passphrase);
    while (keyAndIV.length < keyLength + ivLength) {
      List<int> input = [...currentHash, ...passwordBytes, ...salt];
      currentHash = crypto.md5.convert(input).bytes;
      keyAndIV.addAll(currentHash);
    }
    var key = Uint8List.fromList(keyAndIV.sublist(0, keyLength));
    var iv = Uint8List.fromList(keyAndIV.sublist(keyLength, keyLength + ivLength));
    return [key, iv];
  }

  String decrypt(String encryptedBase64) {
    try {
      var decoded = base64Decode(encryptedBase64);
      if (decoded.length < 16) throw Exception('Invalid ciphertext');
      String header = utf8.decode(decoded.sublist(0, 8));
      if (header != 'Salted__') throw Exception('Invalid format');
      var salt = decoded.sublist(8, 16);
      var ciphertext = decoded.sublist(16);
      var keyIv = _generateKeyAndIV(privateKey, salt);
      var key = encrypt.Key(keyIv[0]);
      var iv = encrypt.IV(keyIv[1]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
      return encrypter.decrypt(encrypt.Encrypted(Uint8List.fromList(ciphertext)), iv: iv);
    } catch (e) {
      return 'Error decrypting: $e';
    }
  }

  void _resumeScanning() {
    setState(() {
      decryptedData = '';
      hasScanned = false;
    });
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Decrypter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: hasScanned 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 48),
                            const SizedBox(height: 16),
                            const Text('QR Code Scanned Successfully', 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            const Text('Decrypted Data:', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(decryptedData, 
                                style: const TextStyle(fontSize: 16, fontFamily: 'monospace')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && !hasScanned) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null) {
                        setState(() {
                          decryptedData = decrypt(code);
                          hasScanned = true;
                        });
                        controller.stop();
                      }
                    }
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: hasScanned
              ? ElevatedButton.icon(
                  onPressed: _resumeScanning,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Another QR Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              : const Text('Scan a QR code containing encrypted data',
                  style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
