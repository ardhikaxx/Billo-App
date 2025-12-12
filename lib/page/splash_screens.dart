import 'package:flutter/material.dart';
import 'package:billo_app/page/scan_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  final Color _primaryColor = const Color(0xFF37474F);
  final Color _accentColor = const Color(0xFF26A69A);
  final Color _bgColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _navigateToNextScreen() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ScanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _accentColor.withOpacity(0.1),
                _bgColor,
                _bgColor,
                _bgColor,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 200),
                  painter: _CurvePainter(_accentColor),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 125,
                        height: 125,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.asset(
                            'assets/img/logo-billo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Text(
                            'BILLO',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                              fontFamily: 'SG03Custom',
                              letterSpacing: 3,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -8),
                            child: Text(
                              'Smart bill splitting made easy',
                              style: TextStyle(
                                color: _primaryColor.withOpacity(0.85),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Fitur Unggulan',
                              style: TextStyle(
                                color: _primaryColor.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildEnhancedFeatureItem(
                                  icon: Icons.qr_code_scanner_rounded,
                                  title: 'Scan Cepat',
                                  description: 'Scan struk dengan mudah',
                                  delay: 0,
                                ),
                                const SizedBox(width: 16),
                                _buildEnhancedFeatureItem(
                                  icon: Icons.calculate_rounded,
                                  title: 'Otomatis',
                                  description: 'Hitung tagihan secara otomatis',
                                  delay: 100,
                                ),
                                const SizedBox(width: 16),
                                _buildEnhancedFeatureItem(
                                  icon: Icons.group_rounded,
                                  title: 'Bagi Rata',
                                  description: 'Bagi tagihan dengan rata',
                                  delay: 200,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: [
                              _accentColor,
                              _accentColor.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          child: InkWell(
                            onTap: _isLoading ? null : _navigateToNextScreen,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 32,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.rocket_launch_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isLoading ? 'MEMUAT...' : 'MULAI SEKARANG',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 78),
                        child: Text(
                          'Pisahkan tagihan dengan mudah, nikmati momen bersama',
                          style: TextStyle(
                            color: _primaryColor.withOpacity(0.5),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [_accentColor, _accentColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: _primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: _primaryColor.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final Color color;

  _CurvePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.6,
        size.width * 0.5,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 1.0,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
