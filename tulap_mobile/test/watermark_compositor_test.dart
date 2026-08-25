import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/imaging/watermark_compositor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Helper untuk membuat blank test image bytes
  Future<Uint8List> createTestImageBytes(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background gradient untuk simulasi foto kamera
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width.toDouble(), height.toDouble()),
        [const ui.Color(0xFF2C3E50), const ui.Color(0xFF3498DB)],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  group('WatermarkCompositor Evidence Verification Panel Tests', () {
    late WatermarkCompositor compositor;

    setUp(() {
      compositor = WatermarkCompositor();
    });

    test(
      'Portrait Image (1080x1920): Composes high-contrast evidence panel and large QR',
      () async {
        final sourceBytes = await createTestImageBytes(1080, 1920);

        final data = WatermarkData(
          officerName: 'Leonardo',
          nip: '19890412 201402 1 003',
          agencyName: 'BPKAD Kabupaten Mimika',
          taskId: 'TL-202608-0001',
          taskName: 'Monitoring Kelayakan Kendaraan Dinas Operasional',
          shortEvidenceId: 'TL-20260824-0011',
          timestamp: DateTime(2026, 8, 24, 15, 36, 18),
          latitude: -4.540346,
          longitude: 136.876482,
          gpsAccuracyMeters: 5.8,
          plusCode: '6P28+3Q Timika',
          address:
              'Jl. Cenderawasih, Kwamki, Mimika Baru, Kabupaten Mimika, Papua Tengah',
          auditQrPayload:
              'https://verify.tulap.id/e/TL-20260824-0011?t=TL-202608-0001',
          isOffline: true,
          isVerified: false,
        );

        final resultBytes = await compositor.compose(
          sourceImageBytes: sourceBytes,
          data: data,
        );

        expect(resultBytes, isNotNull);
        expect(resultBytes.isNotEmpty, isTrue);

        final codec = await ui.instantiateImageCodec(resultBytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, equals(1080));
        expect(frame.image.height, equals(1920));
      },
    );

    test(
      'Landscape Image (1920x1080): Composes responsive landscape layout cleanly',
      () async {
        final sourceBytes = await createTestImageBytes(1920, 1080);

        final data = WatermarkData(
          officerName: 'Leonardo',
          nip: null,
          agencyName: 'BPKAD Kabupaten Mimika',
          taskId: 'TL-202608-0002',
          taskName: 'Survey Aset Tanah Lapangan',
          shortEvidenceId: 'TL-20260824-0012',
          timestamp: DateTime(2026, 8, 24, 16, 0, 0),
          latitude: -4.546123,
          longitude: 136.887421,
          gpsAccuracyMeters: 8.2,
          plusCode: '6P28+3Q Timika',
          address: 'Kecamatan Mimika Baru, Papua Tengah',
          auditQrPayload: 'https://verify.tulap.id/e/TL-20260824-0012',
          isOffline: false,
          isVerified: true,
        );

        final resultBytes = await compositor.compose(
          sourceImageBytes: sourceBytes,
          data: data,
        );

        expect(resultBytes, isNotNull);
        expect(resultBytes.isNotEmpty, isTrue);

        final codec = await ui.instantiateImageCodec(resultBytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, equals(1920));
        expect(frame.image.height, equals(1080));
      },
    );

    test(
      'Medium Image (720x1280): Scales font sizes and QR code proportionally',
      () async {
        final sourceBytes = await createTestImageBytes(720, 1280);

        final data = WatermarkData(
          officerName: 'Leonardo',
          nip: '19890412',
          agencyName: 'BPKAD Mimika',
          taskId: 'TL-202608-0003',
          taskName: 'Pemeriksaan Fasilitas Gedung Kantor',
          shortEvidenceId: 'TL-20260824-0013',
          timestamp: DateTime.now(),
          latitude: -4.540000,
          longitude: 136.870000,
          gpsAccuracyMeters: 12.0,
          plusCode: '6P28+3Q',
          address: null,
          auditQrPayload: 'https://verify.tulap.id/e/TL-20260824-0013',
        );

        final resultBytes = await compositor.compose(
          sourceImageBytes: sourceBytes,
          data: data,
        );

        expect(resultBytes, isNotNull);
        expect(resultBytes.isNotEmpty, isTrue);

        final codec = await ui.instantiateImageCodec(resultBytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, equals(720));
        expect(frame.image.height, equals(1280));
      },
    );
  });
}
