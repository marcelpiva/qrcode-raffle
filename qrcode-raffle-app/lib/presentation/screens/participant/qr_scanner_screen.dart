import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: 12,
                borderLength: 30,
                borderWidth: 4,
                cutOutSize: 280,
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aponte para o QR Code do sorteio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _hasScanned = true;
        _handleQrCode(code);
        break;
      }
    }
  }

  void _handleQrCode(String code) {
    // Parse QR code to extract raffle ID
    // Expected format: https://domain.com/register/RAFFLE_ID or just RAFFLE_ID

    String? raffleId;

    // Try to parse as URL
    final uri = Uri.tryParse(code);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      // Look for 'register' or 'participate' in path
      final registerIndex = uri.pathSegments.indexOf('register');
      final participateIndex = uri.pathSegments.indexOf('participate');

      if (registerIndex != -1 && registerIndex + 1 < uri.pathSegments.length) {
        raffleId = uri.pathSegments[registerIndex + 1];
      } else if (participateIndex != -1 &&
          participateIndex + 1 < uri.pathSegments.length) {
        raffleId = uri.pathSegments[participateIndex + 1];
      } else if (uri.pathSegments.length == 1) {
        // Just the ID
        raffleId = uri.pathSegments.first;
      }
    } else {
      // Assume it's just the raffle ID
      raffleId = code;
    }

    if (raffleId != null && raffleId.isNotEmpty) {
      // Navigate to registration screen
      context.go('/participate/$raffleId');
    } else {
      // Show error and allow rescan
      setState(() {
        _hasScanned = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code inválido'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutWidth / 2 + borderOffset,
      rect.top + height / 2 - cutOutHeight / 2 + borderOffset,
      cutOutWidth - borderOffset * 2,
      cutOutHeight - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        boxPaint,
      )
      ..restore();

    // Draw corners
    final path = Path();

    // Top left corner
    path.moveTo(cutOutRect.left - borderOffset, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderOffset);

    // Top right corner
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top - borderOffset);
    path.lineTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset);
    path.lineTo(cutOutRect.right + borderOffset, cutOutRect.top + borderLength);

    // Bottom right corner
    path.moveTo(
        cutOutRect.right + borderOffset, cutOutRect.bottom - borderLength);
    path.lineTo(
        cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset);
    path.lineTo(
        cutOutRect.right - borderLength, cutOutRect.bottom + borderOffset);

    // Bottom left corner
    path.moveTo(
        cutOutRect.left + borderLength, cutOutRect.bottom + borderOffset);
    path.lineTo(
        cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset);
    path.lineTo(
        cutOutRect.left - borderOffset, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
