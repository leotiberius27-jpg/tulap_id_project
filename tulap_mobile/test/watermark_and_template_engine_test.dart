import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/geo/mini_map_renderer.dart';
import 'package:tulap_mobile/core/imaging/watermark_compositor.dart';
import 'package:tulap_mobile/core/qr/qr_location_generator.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/watermark_template_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/repositories/template_repository.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/camera_stamp_preview.dart';

class _MockTemplateRepository implements TemplateRepository {
  StampConfiguration _config = const StampConfiguration();

  @override
  Future<StampConfiguration> getSavedConfiguration() async => _config;

  @override
  Future<void> saveConfiguration(StampConfiguration config) async {
    _config = config;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Helper untuk membuat blank test image bytes
  Future<Uint8List> createTestImageBytes(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width.toDouble(), height.toDouble()),
        [const ui.Color(0xFF1E293B), const ui.Color(0xFF0F172A)],
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

  group('Phase 3: Template Catalog & Configuration Tests', () {
    test('TemplateCatalog contains 7 official Indonesian templates', () {
      expect(TemplateCatalog.all.length, equals(7));

      final gpsMapCamera = TemplateCatalog.getById('gps_map_camera');
      expect(gpsMapCamera.name, equals('GPS Map Camera'));
      expect(gpsMapCamera.hasMiniMap, isTrue);
      expect(gpsMapCamera.hasQrMaps, isTrue);

      final klasik = TemplateCatalog.getById('klasik');
      expect(klasik.name, equals('Klasik'));
      expect(klasik.hasMiniMap, isTrue);

      final pelaporan = TemplateCatalog.getById('pelaporan');
      expect(pelaporan.name, equals('Pelaporan'));
      expect(pelaporan.hasQrMaps, isTrue);

      final tanggalWaktu = TemplateCatalog.getById('tanggal_waktu');
      expect(tanggalWaktu.name, equals('Tanggal & Waktu'));
      expect(tanggalWaktu.isMinimal, isTrue);

      final lokasiQr = TemplateCatalog.getById('lokasi_qr');
      expect(lokasiQr.name, equals('Lokasi + QR'));
      expect(lokasiQr.hasQrMaps, isTrue);

      final kompak = TemplateCatalog.getById('kompak');
      expect(kompak.name, equals('Kompak'));
      expect(kompak.isMinimal, isTrue);

      final kompasTeknis = TemplateCatalog.getById('kompas_teknis');
      expect(kompasTeknis.name, equals('Kompas / Teknis'));
      expect(kompasTeknis.hasHeading, isTrue);
    });

    test('TemplateCatalog fallback gracefully to GPS Map Camera (default) on unknown ID', () {
      final template = TemplateCatalog.getById('unknown_id_999');
      expect(template.id, equals('gps_map_camera'));
      expect(template.name, equals('GPS Map Camera'));
    });

    test('StampConfiguration serializes and deserializes cleanly with toggles', () {
      const config = StampConfiguration(
        templateId: 'pelaporan',
        templateVersion: 1,
        showLocation: true,
        showDate: true,
        showTime: false,
        showCoordinates: true,
        showGpsAccuracy: true,
        showTaskName: true,
        showEvidenceId: true,
        showOfficerName: false,
        showMiniMap: false,
        showQrMaps: true,
      );

      final json = config.toJson();
      final restored = StampConfiguration.fromJson(json);

      expect(restored.templateId, equals('pelaporan'));
      expect(restored.showTime, isFalse);
      expect(restored.showOfficerName, isFalse);
      expect(restored.showMiniMap, isFalse);
      expect(restored.showQrMaps, isTrue);
      expect(restored.showEvidenceId, isTrue);
    });

    test('TemplateRepository persists and retrieves StampConfiguration', () async {
      final repo = _MockTemplateRepository();
      final initial = await repo.getSavedConfiguration();
      expect(initial.templateId, equals('gps_map_camera'));

      await repo.saveConfiguration(
        const StampConfiguration(templateId: 'lokasi_qr', showMiniMap: true),
      );
      final updated = await repo.getSavedConfiguration();
      expect(updated.templateId, equals('lokasi_qr'));
      expect(updated.showMiniMap, isTrue);
    });
  });

  group('Phase 3: Offline QR Google Maps & Mini Map Generator Tests', () {
    late QrLocationGenerator qrGenerator;
    late MiniMapRenderer miniMapRenderer;

    setUp(() {
      qrGenerator = QrLocationGenerator();
      miniMapRenderer = MiniMapRenderer();
    });

    test('QrLocationGenerator builds exact Google Maps query URL with 6 decimals', () {
      final url = qrGenerator.buildGoogleMapsUrl(
        latitude: -4.540346,
        longitude: 136.876482,
      );

      expect(
        url,
        equals(
          'https://www.google.com/maps/search/?api=1&query=-4.540346,136.876482',
        ),
      );
    });

    test('QrLocationGenerator creates valid offline QR Image bitmap', () async {
      final url = qrGenerator.buildGoogleMapsUrl(
        latitude: -4.540346,
        longitude: 136.876482,
      );
      final qrImage = await qrGenerator.generateQrImage(
        data: url,
        pixelSize: 120,
      );

      expect(qrImage, isNotNull);
      expect(qrImage.width, equals(120));
      expect(qrImage.height, equals(120));
    });

    test('MiniMapRenderer generates procedural offline map with coordinate pins', () async {
      final mapImage = await miniMapRenderer.renderMiniMap(
        latitude: -4.540346,
        longitude: 136.876482,
        pixelSize: 150,
      );

      expect(mapImage, isNotNull);
      expect(mapImage.width, equals(150));
      expect(mapImage.height, equals(150));
    });
  });

  group('Phase 3: Watermark Compositor Template Engine Tests', () {
    late WatermarkCompositor compositor;

    setUp(() {
      compositor = WatermarkCompositor();
    });

    WatermarkData buildSampleData({StampConfiguration? config}) {
      return WatermarkData(
        officerName: 'Leonardo',
        nip: '19890412 201402 1 003',
        agencyName: 'BPKAD Kabupaten Mimika',
        taskId: 'TL-202608-0001',
        taskName: 'Pemeriksaan Lapangan Kelayakan Kendaraan Dinas',
        shortEvidenceId: 'TL-20260826-9760',
        timestamp: DateTime(2026, 8, 26, 11, 13, 0),
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 12.0,
        altitude: 45.0,
        heading: 185.0,
        plusCode: '6P28+3Q Timika',
        address: 'Jl. Cenderawasih, Mimika Baru, Kabupaten Mimika',
        auditQrPayload: 'https://verify.tulap.id/e/TL-20260826-9760',
        configuration: config,
      );
    }

    test('Template 1 (KLASIK): Composes balanced geotag with mini-map', () async {
      final sourceBytes = await createTestImageBytes(1080, 1920);
      final data = buildSampleData(
        config: const StampConfiguration(templateId: 'klasik', showMiniMap: true),
      );

      final resultBytes = await compositor.compose(
        sourceImageBytes: sourceBytes,
        data: data,
      );

      expect(resultBytes.isNotEmpty, isTrue);
      final codec = await ui.instantiateImageCodec(resultBytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, equals(1080));
      expect(frame.image.height, equals(1920));
    });

    test('Template 2 (PELAPORAN): Composes official documentation with QR Google Maps', () async {
      final sourceBytes = await createTestImageBytes(1080, 1920);
      final data = buildSampleData(
        config: const StampConfiguration(templateId: 'pelaporan', showQrMaps: true),
      );

      final resultBytes = await compositor.compose(
        sourceImageBytes: sourceBytes,
        data: data,
      );

      expect(resultBytes.isNotEmpty, isTrue);
      final codec = await ui.instantiateImageCodec(resultBytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, equals(1080));
      expect(frame.image.height, equals(1920));
    });

    test('Template 3 (TANGGAL & WAKTU): Composes minimalist large date/time layout', () async {
      final sourceBytes = await createTestImageBytes(1080, 1920);
      final data = buildSampleData(
        config: const StampConfiguration(templateId: 'tanggal_waktu'),
      );

      final resultBytes = await compositor.compose(
        sourceImageBytes: sourceBytes,
        data: data,
      );

      expect(resultBytes.isNotEmpty, isTrue);
      final codec = await ui.instantiateImageCodec(resultBytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, equals(1080));
    });

    test('Template 4 (LOKASI + QR): Composes location and QR navigation layout', () async {
      final sourceBytes = await createTestImageBytes(1080, 1920);
      final data = buildSampleData(
        config: const StampConfiguration(templateId: 'lokasi_qr'),
      );

      final resultBytes = await compositor.compose(
        sourceImageBytes: sourceBytes,
        data: data,
      );

      expect(resultBytes.isNotEmpty, isTrue);
    });

    test('Template 5 (KOMPAK): Composes slim compact overlay', () async {
      final sourceBytes = await createTestImageBytes(1080, 1920);
      final data = buildSampleData(
        config: const StampConfiguration(templateId: 'kompak'),
      );

      final resultBytes = await compositor.compose(
        sourceImageBytes: sourceBytes,
        data: data,
      );

      expect(resultBytes.isNotEmpty, isTrue);
    });

    test('Template 6 (KOMPAS / TEKNIS): Composes survey layout with compass heading & elevation', () async {
      final sourceBytes = await createTestImageBytes(1080, 1920);
      final data = buildSampleData(
        config: const StampConfiguration(templateId: 'kompas_teknis'),
      );

      final resultBytes = await compositor.compose(
        sourceImageBytes: sourceBytes,
        data: data,
      );

      expect(resultBytes.isNotEmpty, isTrue);
    });

    test('Responsive scaling works from 720p up to 4K (2160x3840)', () async {
      final resolutions = [
        [720, 1280],
        [1080, 1920],
        [1440, 2560],
        [2160, 3840],
      ];

      for (final res in resolutions) {
        final w = res[0];
        final h = res[1];
        final sourceBytes = await createTestImageBytes(w, h);
        final data = buildSampleData();

        final resultBytes = await compositor.compose(
          sourceImageBytes: sourceBytes,
          data: data,
        );

        final codec = await ui.instantiateImageCodec(resultBytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, equals(w));
        expect(frame.image.height, equals(h));
      }
    });
  });

  group('Phase 3: CameraStampPreview Widget Tests', () {
    testWidgets('Renders Live Stamp Preview matching Klasik template', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraStampPreview(
              taskName: 'Monitoring Aset Kantor',
              officerName: 'Leonardo',
              agencyName: 'BPKAD Mimika',
              latitude: -4.540346,
              longitude: 136.876482,
              accuracyMeters: 14.0,
              address: 'Jl. Cenderawasih, Mimika',
              currentTime: DateTime(2026, 8, 26, 11, 13),
              stampConfig: const StampConfiguration(templateId: 'klasik'),
            ),
          ),
        ),
      );

      expect(find.text('TULAP.ID  '), findsOneWidget);
      expect(find.text('•  STANDAR GEOTAG'), findsOneWidget);
      expect(find.text('Monitoring Aset Kantor'), findsOneWidget);
      expect(find.textContaining('GPS ±14 m'), findsOneWidget);
      expect(find.byType(CameraStampPreview), findsOneWidget);
    });

    testWidgets('Renders Live Stamp Preview matching Pelaporan template with QR', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraStampPreview(
              taskName: 'Pemeriksaan Lapangan',
              officerName: 'Leonardo',
              agencyName: 'BPKAD Mimika',
              latitude: -4.540346,
              longitude: 136.876482,
              accuracyMeters: 8.0,
              address: 'Jl. Cenderawasih, Mimika',
              currentTime: DateTime(2026, 8, 26, 11, 13),
              stampConfig: const StampConfiguration(templateId: 'pelaporan', showQrMaps: true),
            ),
          ),
        ),
      );

      expect(find.text('•  DOKUMENTASI RESMI'), findsOneWidget);
      expect(find.text('Google Maps'), findsOneWidget);
    });
  });
}
