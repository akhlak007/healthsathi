import 'package:flutter/material.dart';

/// Doctor Hero Graphic Widget
/// Draws the friendly female doctor character with lab coat, stethoscope,
/// and medical tablet on a soft circular background.
class DoctorHeroWidget extends StatelessWidget {
  final double width;
  final double height;

  const DoctorHeroWidget({
    super.key,
    this.width = 130,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _DoctorPainter(),
      ),
    );
  }
}

class _DoctorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Head center & dimensions
    final headCenterX = w * 0.50;
    final headCenterY = h * 0.32;
    final headRadius = w * 0.20;

    // 1. Hair Back
    final hairBackPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headCenterX, headCenterY + 4), headRadius * 1.15, hairBackPaint);

    // 2. Neck
    final skinPaint = Paint()
      ..color = const Color(0xFFFCD34D) // Warm friendly skin tone
      ..style = PaintingStyle.fill;
    final neckRect = Rect.fromLTWH(headCenterX - w * 0.08, headCenterY + headRadius * 0.6, w * 0.16, h * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(neckRect, const Radius.circular(6)), skinPaint);

    // 3. Body / Lab Coat Base
    final coatPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final coatShadowPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    final bodyPath = Path()
      ..moveTo(headCenterX - w * 0.36, h)
      ..quadraticBezierTo(headCenterX - w * 0.34, h * 0.58, headCenterX - w * 0.15, h * 0.52)
      ..lineTo(headCenterX + w * 0.15, h * 0.52)
      ..quadraticBezierTo(headCenterX + w * 0.34, h * 0.58, headCenterX + w * 0.36, h)
      ..close();
    canvas.drawPath(bodyPath, coatPaint);

    // Inner Scrub Top (Cyan / Teal)
    final scrubPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;
    final scrubPath = Path()
      ..moveTo(headCenterX - w * 0.11, h * 0.52)
      ..lineTo(headCenterX + w * 0.11, h * 0.52)
      ..lineTo(headCenterX, h * 0.68)
      ..close();
    canvas.drawPath(scrubPath, scrubPaint);

    // Coat Lapels & Shading
    final lapelPath = Path()
      ..moveTo(headCenterX - w * 0.14, h * 0.52)
      ..lineTo(headCenterX - w * 0.04, h * 0.70)
      ..lineTo(headCenterX - w * 0.18, h * 0.85)
      ..lineTo(headCenterX - w * 0.28, h)
      ..lineTo(headCenterX - w * 0.36, h)
      ..quadraticBezierTo(headCenterX - w * 0.34, h * 0.58, headCenterX - w * 0.14, h * 0.52)
      ..close();
    canvas.drawPath(lapelPath, coatShadowPaint);

    final rightLapelPath = Path()
      ..moveTo(headCenterX + w * 0.14, h * 0.52)
      ..lineTo(headCenterX + w * 0.04, h * 0.70)
      ..lineTo(headCenterX + w * 0.18, h * 0.85)
      ..lineTo(headCenterX + w * 0.28, h)
      ..lineTo(headCenterX + w * 0.36, h)
      ..quadraticBezierTo(headCenterX + w * 0.34, h * 0.58, headCenterX + w * 0.14, h * 0.52)
      ..close();
    canvas.drawPath(rightLapelPath, coatShadowPaint);

    // 4. Stethoscope
    final stethPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final stethPath = Path()
      ..moveTo(headCenterX - w * 0.11, h * 0.52)
      ..quadraticBezierTo(headCenterX - w * 0.14, h * 0.68, headCenterX - w * 0.05, h * 0.78)
      ..lineTo(headCenterX + w * 0.05, h * 0.78)
      ..quadraticBezierTo(headCenterX + w * 0.14, h * 0.68, headCenterX + w * 0.11, h * 0.52);
    canvas.drawPath(stethPath, stethPaint);

    // Stethoscope Bell / Disc
    final bellPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headCenterX + w * 0.05, h * 0.79), 4.5, bellPaint);

    // 5. Head / Face
    canvas.drawCircle(Offset(headCenterX, headCenterY), headRadius, skinPaint);

    // 6. Hair Front / Styling
    final hairFrontPath = Path()
      ..moveTo(headCenterX - headRadius * 1.05, headCenterY)
      ..quadraticBezierTo(headCenterX - headRadius * 0.8, headCenterY - headRadius * 1.15, headCenterX, headCenterY - headRadius * 1.1)
      ..quadraticBezierTo(headCenterX + headRadius * 0.8, headCenterY - headRadius * 1.15, headCenterX + headRadius * 1.05, headCenterY)
      ..quadraticBezierTo(headCenterX + headRadius * 0.7, headCenterY - headRadius * 0.4, headCenterX + headRadius * 0.2, headCenterY - headRadius * 0.5)
      ..quadraticBezierTo(headCenterX - headRadius * 0.5, headCenterY - headRadius * 0.4, headCenterX - headRadius * 1.05, headCenterY)
      ..close();
    canvas.drawPath(hairFrontPath, hairBackPaint);

    // 7. Facial Features
    final featurePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // Eyes
    canvas.drawCircle(Offset(headCenterX - headRadius * 0.38, headCenterY + headRadius * 0.08), 2.8, featurePaint);
    canvas.drawCircle(Offset(headCenterX + headRadius * 0.38, headCenterY + headRadius * 0.08), 2.8, featurePaint);

    // Friendly Smile
    final smilePaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final smileRect = Rect.fromCircle(center: Offset(headCenterX, headCenterY + headRadius * 0.32), radius: headRadius * 0.28);
    canvas.drawArc(smileRect, 0.2, 2.7, false, smilePaint);

    // Blush cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFB7185).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headCenterX - headRadius * 0.52, headCenterY + headRadius * 0.24), 3.5, blushPaint);
    canvas.drawCircle(Offset(headCenterX + headRadius * 0.52, headCenterY + headRadius * 0.24), 3.5, blushPaint);

    // 8. Tablet / Medical Chart held in front
    final tabletPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final tabletRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(headCenterX - w * 0.20, h * 0.74, w * 0.40, h * 0.26),
      const Radius.circular(8),
    );
    canvas.drawRRect(tabletRect, tabletPaint);

    // Tablet Screen
    final screenPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(headCenterX - w * 0.17, h * 0.77, w * 0.34, h * 0.23),
      const Radius.circular(5),
    );
    canvas.drawRRect(screenRect, screenPaint);

    // Hands holding tablet
    canvas.drawCircle(Offset(headCenterX - w * 0.18, h * 0.84), 5.5, skinPaint);
    canvas.drawCircle(Offset(headCenterX + w * 0.18, h * 0.84), 5.5, skinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Documents with Green Upload Badge Illustration
/// For the "Digitize Your Health Records" Hero Banner
class DocumentsIllustrationWidget extends StatelessWidget {
  final double size;

  const DocumentsIllustrationWidget({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back document paper (tilted slightly right)
          Transform.rotate(
            angle: 0.14,
            child: Container(
              width: size * 0.58,
              height: size * 0.74,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Front document paper (crisp white with medical chart lines)
          Transform.rotate(
            angle: -0.05,
            child: Container(
              width: size * 0.64,
              height: size * 0.80,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Header bar
                  Container(
                    width: size * 0.25,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF93C5FD),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Medical Pulse Wave Line
                  SizedBox(
                    height: 20,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _PulseWavePainter(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Document text lines
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: size * 0.35,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Vibrant Green Upload Badge (bottom right)
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.cloud_upload_rounded,
                color: Colors.white,
                size: size * 0.20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final mid = h * 0.5;

    final path = Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.22, mid)
      ..lineTo(w * 0.35, mid - h * 0.42)
      ..lineTo(w * 0.48, mid + h * 0.45)
      ..lineTo(w * 0.62, mid - h * 0.25)
      ..lineTo(w * 0.75, mid)
      ..lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clipboard with Checklist and Shield Badge Illustration
/// For the Timeline Promo Card ("Keep Your Health History Organized")
class ClipboardIllustrationWidget extends StatelessWidget {
  final double size;

  const ClipboardIllustrationWidget({
    super.key,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Clipboard Board Background
          Container(
            width: size * 0.72,
            height: size * 0.90,
            decoration: BoxDecoration(
              color: const Color(0xFFBFDBFE), // Soft blue clipboard
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Top Clip
          Positioned(
            top: 2,
            child: Container(
              width: size * 0.32,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // White Sheet on Clipboard
          Positioned(
            top: 10,
            child: Container(
              width: size * 0.62,
              height: size * 0.78,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checklist items with checkmarks
                  _buildCheckItem(size),
                  const SizedBox(height: 8),
                  _buildCheckItem(size),
                  const SizedBox(height: 8),
                  _buildCheckItem(size),
                ],
              ),
            ),
          ),
          // Blue Medical Shield Badge (bottom right)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.38,
              height: size * 0.38,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(double size) {
    return Row(
      children: [
        const Icon(
          Icons.check_rounded,
          color: Color(0xFF10B981),
          size: 13,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 3.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
