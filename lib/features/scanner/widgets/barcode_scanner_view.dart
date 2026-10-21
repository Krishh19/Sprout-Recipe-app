import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../design/colors.dart';
import '../../../design/radii.dart';
import '../../../design/sprout_haptics.dart';
import '../../../design/typography.dart';
import '../../../services/open_food_facts_service.dart';
import 'scanned_product_sheet.dart';
import 'sprout_scanner_overlay.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final OpenFoodFactsService _offService = OpenFoodFactsService();
  bool _isProcessing = false;
  String? _lastScannedBarcode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;
    if (rawValue == _lastScannedBarcode) return;

    _handleBarcode(rawValue);
  }

  void _handleBarcode(String barcode) async {
    setState(() {
      _isProcessing = true;
      _lastScannedBarcode = barcode;
    });
    SproutHaptics.medium();

    try {
      final product = await _offService.fetchProductByBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        SproutHaptics.success();
        await ScannedProductSheet.show(context, product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No product found for barcode "$barcode" on OpenFoodFacts.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Viewfinder Container
        Container(
          height: 280,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: SproutRadii.card,
            border: Border.all(
              color: SproutColors.sproutGreen.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: SproutColors.sproutGreen.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Real Camera Scanner
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_off_rounded,
                            size: 40,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Camera preview unavailable on this device or permission denied.',
                            textAlign: TextAlign.center,
                            style: SproutTypography.caption(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Viewfinder Reticle Overlay with Unified Corner Brackets
              SizedBox(
                width: 220,
                height: 140,
                child: SproutScannerOverlay(
                  isAnalyzing: _isProcessing,
                  margin: 6.0,
                  armLength: 20.0,
                  cornerRadius: 12.0,
                  strokeWidth: 2.8,
                ),
              ),

              // Scanning indicator line or loader
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(SproutColors.sproutGreen),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Looking up product macros...',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

              // Top Controls (Torch & Switch)
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                      onPressed: () => _controller.toggleTorch(),
                      tooltip: 'Toggle Flashlight',
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                      onPressed: () => _controller.switchCamera(),
                      tooltip: 'Switch Camera',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Helper hint text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Align the UPC or EAN barcode inside the frame to scan instantly.',
            textAlign: TextAlign.center,
            style: SproutTypography.caption(color: SproutColors.secondaryInk),
          ),
        ),

        const SizedBox(height: 14),

        // Simulator / Quick Test Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSampleChip('Barilla Pasta', '8076809513753'),
              _buildSampleChip('Nutella Spread', '3017620422003'),
              _buildSampleChip('Olive Oil', '8410199001048'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSampleChip(String label, String barcode) {
    return ActionChip(
      avatar: const Icon(Icons.qr_code_rounded, size: 16, color: SproutColors.sproutGreen),
      label: Text(label),
      labelStyle: SproutTypography.caption(
        color: SproutColors.primaryInk,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: SproutColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: SproutColors.sage.withValues(alpha: 0.3)),
      ),
      onPressed: _isProcessing ? null : () => _handleBarcode(barcode),
    );
  }
}
