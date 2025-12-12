import 'dart:io';
import 'dart:ui';
import 'package:billo_app/page/splash_screens.dart';
import 'package:billo_app/utils/price_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:billo_app/page/splitbill_screens.dart';
import 'package:billo_app/models/bill_model.dart';
import 'package:billo_app/utils/receipt_parser.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  late TextRecognizer _textRecognizer;
  int _itemsFound = 0;
  List<BillItem> _extractedItems = [];

  final Color _primaryColor = const Color(0xFF37474F);
  final Color _accentColor = const Color(0xFF26A69A);
  final Color _bgColor = const Color(0xFFF5F7FA);
  final Color _surfaceColor = Colors.white;
  final Color _borderColor = const Color(0xFFE1E5E9);
  final Color _textSecondary = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _itemsFound = 0;
          _extractedItems = [];
        });

        await _processImage(pickedFile.path);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      print('=== RAW OCR TEXT ===');
      print(recognizedText.text);
      print('=== END RAW TEXT ===');

      List<BillItem> extractedItems = ReceiptParser.parseReceiptText(
        recognizedText.text,
      );

      setState(() {
        _itemsFound = extractedItems.length;
        _extractedItems = extractedItems;
      });

      if (extractedItems.isNotEmpty) {
        _showSuccess('Found $_itemsFound items from receipt');

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SplitBillScreen(
              initialItems: extractedItems,
              receiptImagePath: imagePath,
            ),
          ),
        );
      } else {
        _showError('No items found. Please enter items manually.');

        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                SplitBillScreen(initialItems: [], receiptImagePath: imagePath),
          ),
        );
      }
    } catch (e) {
      print('Error processing image: $e');
      _showError('Failed to process image: $e');

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              SplitBillScreen(initialItems: [], receiptImagePath: imagePath),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.circleExclamation,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: FaIcon(
                FontAwesomeIcons.check,
                color: _accentColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Billo Scan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 34,
            fontFamily: 'SG03Custom',
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _accentColor,
              ),
              child: IconButton(
                icon: const FaIcon(FontAwesomeIcons.lightbulb, size: 18),
                color: Colors.white,
                onPressed: _showTipDialog,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildScannerPreviewArea(),
              const SizedBox(height: 12),
              if (_isProcessing) _buildProcessingView(),
              if (_extractedItems.isNotEmpty && !_isProcessing)
                _buildParsedItemsPreview(),
              if (!_isProcessing) _buildActionButtons(),
              if (!_isProcessing || _extractedItems.isEmpty)
              _buildManualEntryOption(),
              SizedBox(height: 12),
              _buildBackToHomeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackToHomeButton() {
    return Center(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor, width: 1.5),
        ),
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SplashScreen()),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.chevronLeft,
                size: 16,
                color: _accentColor,
              ),
              SizedBox(width: 8),
              Text(
                'Kembali',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerPreviewArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _image != null
                    ? Stack(
                        children: [
                          Image.file(
                            _image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildEmptyState(),
              ),
            ),

            if (_image == null)
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: CustomPaint(
                    painter: ScannerCornerPainter(
                      color: _primaryColor.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

            if (_image != null && _itemsFound > 0 && !_isProcessing)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentColor, _accentColor.withOpacity(0.9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.check,
                          color: _accentColor,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_itemsFound items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_image != null && !_isProcessing)
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _image = null;
                      _extractedItems = [];
                      _itemsFound = 0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.arrowsRotate,
                      color: _primaryColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgColor, _bgColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: _borderColor, width: 2),
          ),
          child: Icon(
            Icons.receipt_long,
            size: 48,
            color: _primaryColor.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Belum Ada Struk yang Dipilih',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Ambil foto atau pilih dari galeri untuk mulai memindai',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                  strokeWidth: 3,
                  backgroundColor: _accentColor.withOpacity(0.1),
                ),
              ),
              FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                color: _accentColor,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Scanning Receipt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing text and extracting items...',
            style: TextStyle(fontSize: 14, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            backgroundColor: _accentColor.withOpacity(0.1),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedItemsPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.9),
                  _primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.listCheck,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items Detected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$_itemsFound items ready for splitting',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Daftar item
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: _extractedItems.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.tag,
                            size: 14,
                            color: _accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity}x • ${PriceUtils.formatPrice(item.totalPrice / item.quantity)} each',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        PriceUtils.formatPrice(item.totalPrice),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                          fontFamily: Platform.isIOS ? 'SF Mono' : 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Footer dengan count
          if (_extractedItems.length > 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _borderColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.ellipsis,
                    color: _textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_extractedItems.length - 3} more items',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: FontAwesomeIcons.camera,
                label: 'Take Photo',
                subtitle: 'Use camera',
                isPrimary: true,
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: FontAwesomeIcons.images,
                label: 'From Gallery',
                subtitle: 'Select existing',
                isPrimary: false,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      color: isPrimary ? _accentColor : _surfaceColor,
      elevation: 4,
      shadowColor: isPrimary
          ? _accentColor.withOpacity(0.4)
          : Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: isPrimary
                ? null
                : Border.all(color: _borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FaIcon(
                  icon,
                  color: isPrimary ? Colors.white : _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : _primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isPrimary
                      ? Colors.white.withOpacity(0.8)
                      : _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryOption() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SplitBillScreen(
                initialItems: [],
                receiptImagePath: _image?.path,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  FontAwesomeIcons.penToSquare,
                  size: 18,
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masukkan manual',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                    Text(
                      'Tambahkan item secara manual',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.lightbulb,
                      color: _accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Tips untuk hasil terbaik',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Untuk mendapatkan hasil scan yang optimal, ikuti tips berikut:',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildTipDetailItem(
                icon: Icons.light_mode,
                title: 'Pencahayaan Baik',
                description:
                    'Pastikan struk dalam kondisi pencahayaan yang cukup, hindari bayangan yang menutupi teks.',
              ),
              const SizedBox(height: 16),
              _buildTipDetailItem(
                icon: Icons.camera_alt,
                title: 'Fokus Tajam',
                description:
                    'Pastikan kamera fokus pada seluruh area struk sehingga semua teks terbaca jelas.',
              ),
              const SizedBox(height: 16),
              _buildTipDetailItem(
                icon: Icons.straighten,
                title: 'Posisi Sejajar',
                description:
                    'Usahakan kamera sejajar dengan struk untuk menghindari distorsi dan kemiringan teks.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipDetailItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ScannerCornerPainter extends CustomPainter {
  final Color color;
  ScannerCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 36.0;
    final double cornerWidth = 8.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, cornerWidth)
        ..quadraticBezierTo(0, 0, cornerWidth, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - cornerWidth, 0)
        ..quadraticBezierTo(size.width, 0, size.width, cornerWidth)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - cornerWidth)
        ..quadraticBezierTo(0, size.height, cornerWidth, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - cornerWidth, size.height)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - cornerWidth,
        )
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
