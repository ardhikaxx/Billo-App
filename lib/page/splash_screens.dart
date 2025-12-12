import 'package:flutter/material.dart';
import 'package:billo_app/page/scan_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }
    });
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A69A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 100, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              'Billo',
              style: TextStyle(
                fontSize: 68,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'SG03Custom',
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -16),
              child: Text(
                'Smart bill splitting made easy',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 50),
            _showButton
                ? ElevatedButton(
                    onPressed: _navigateToNextScreen,
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(double.infinity, 56),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF26A69A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Split Bill Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
