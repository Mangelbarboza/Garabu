import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../pet/domain/pet_model.dart';

enum ClothingCategory {
  bows,
  glasses,
  caps,
  hats,
  shoes,
}

class CatalogItem {
  final String id;
  final String name;
  final ClothingCategory category;
  final int price;
  final double defaultOffsetX;
  final double defaultOffsetY;
  final void Function(Canvas canvas, Size size) painter;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.defaultOffsetX,
    required this.defaultOffsetY,
    required this.painter,
  });

  /// Genera un PNG Data URI transparente con el accesorio vectorizado
  Future<String> generatePngDataUrl() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 300, 300));
    painter(canvas, const Size(300, 300));
    final picture = recorder.endRecording();
    final image = await picture.toImage(300, 300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return '';
    final base64String = base64Encode(byteData.buffer.asUint8List());
    return 'data:image/png;base64,$base64String';
  }

  /// Convierte este artículo en una prenda GarmentItem para el clóset
  Future<GarmentItem> toGarmentItem() async {
    final dataUrl = await generatePngDataUrl();
    return GarmentItem(
      id: id,
      name: name,
      imageUrl: dataUrl,
      createdAt: DateTime.now(),
      offsetX: defaultOffsetX,
      offsetY: defaultOffsetY,
    );
  }
}

// -------------------------------------------------------------
// LISTADO OFICIAL DE 25 PRENDAS Y ACCESORIOS GARABU
// -------------------------------------------------------------
const List<CatalogItem> kClothingCatalog = [
  // --- 1. LAZOS & MOÑOS (5) ---
  CatalogItem(
    id: 'lazo_clasico_rojo',
    name: 'Lazo Clásico Rojo',
    category: ClothingCategory.bows,
    price: 20,
    defaultOffsetX: 0,
    defaultOffsetY: -75,
    painter: _drawLazoRojo,
  ),
  CatalogItem(
    id: 'lazo_coquette_rosa',
    name: 'Lazo Coquette Rosa',
    category: ClothingCategory.bows,
    price: 22,
    defaultOffsetX: 35,
    defaultOffsetY: -70,
    painter: _drawLazoRosa,
  ),
  CatalogItem(
    id: 'lazo_marinero_azul',
    name: 'Moño Marinero Azul',
    category: ClothingCategory.bows,
    price: 24,
    defaultOffsetX: 0,
    defaultOffsetY: -72,
    painter: _drawLazoMarinero,
  ),
  CatalogItem(
    id: 'lazo_gotico_negro',
    name: 'Lazo Gótico Negro',
    category: ClothingCategory.bows,
    price: 26,
    defaultOffsetX: -32,
    defaultOffsetY: -70,
    painter: _drawLazoGotico,
  ),
  CatalogItem(
    id: 'lazo_corbatin_elegante',
    name: 'Corbatín Elegante',
    category: ClothingCategory.bows,
    price: 30,
    defaultOffsetX: 0,
    defaultOffsetY: -5,
    painter: _drawCorbatin,
  ),

  // --- 2. LENTES (5) ---
  CatalogItem(
    id: 'lentes_vintage_oro',
    name: 'Lentes Redondos Vintage',
    category: ClothingCategory.glasses,
    price: 25,
    defaultOffsetX: 0,
    defaultOffsetY: -35,
    painter: _drawLentesVintage,
  ),
  CatalogItem(
    id: 'lentes_sol_cool',
    name: 'Gafas de Sol Cool',
    category: ClothingCategory.glasses,
    price: 28,
    defaultOffsetX: 0,
    defaultOffsetY: -35,
    painter: _drawLentesSol,
  ),
  CatalogItem(
    id: 'lentes_corazon_rosa',
    name: 'Lentes Corazón Rosa',
    category: ClothingCategory.glasses,
    price: 30,
    defaultOffsetX: 0,
    defaultOffsetY: -35,
    painter: _drawLentesCorazon,
  ),
  CatalogItem(
    id: 'lentes_nerd_negros',
    name: 'Lentes Nerd Negros',
    category: ClothingCategory.glasses,
    price: 22,
    defaultOffsetX: 0,
    defaultOffsetY: -35,
    painter: _drawLentesNerd,
  ),
  CatalogItem(
    id: 'lentes_monoculo_steampunk',
    name: 'Monóculo Steampunk',
    category: ClothingCategory.glasses,
    price: 35,
    defaultOffsetX: 18,
    defaultOffsetY: -35,
    painter: _drawMonoculo,
  ),

  // --- 3. GORRAS (5) ---
  CatalogItem(
    id: 'gorra_urbana_roja',
    name: 'Gorra Urbana Roja',
    category: ClothingCategory.caps,
    price: 28,
    defaultOffsetX: 0,
    defaultOffsetY: -70,
    painter: _drawGorraRoja,
  ),
  CatalogItem(
    id: 'gorra_beisbol_azul',
    name: 'Gorra Beisbolera Azul',
    category: ClothingCategory.caps,
    price: 28,
    defaultOffsetX: 0,
    defaultOffsetY: -70,
    painter: _drawGorraAzul,
  ),
  CatalogItem(
    id: 'gorra_pastel_lila',
    name: 'Gorra Pastel Lila',
    category: ClothingCategory.caps,
    price: 30,
    defaultOffsetX: 0,
    defaultOffsetY: -70,
    painter: _drawGorraLila,
  ),
  CatalogItem(
    id: 'gorra_pato_amarilla',
    name: 'Gorra de Pato Amarilla',
    category: ClothingCategory.caps,
    price: 32,
    defaultOffsetX: 0,
    defaultOffsetY: -70,
    painter: _drawGorraPato,
  ),
  CatalogItem(
    id: 'gorra_gamer_verde',
    name: 'Gorra Gamer Verde',
    category: ClothingCategory.caps,
    price: 35,
    defaultOffsetX: 0,
    defaultOffsetY: -70,
    painter: _drawGorraGamer,
  ),

  // --- 4. SOMBREROS (5) ---
  CatalogItem(
    id: 'sombrero_copa_magico',
    name: 'Sombrero de Copa Mágico',
    category: ClothingCategory.hats,
    price: 40,
    defaultOffsetX: 0,
    defaultOffsetY: -78,
    painter: _drawSombreroCopa,
  ),
  CatalogItem(
    id: 'sombrero_brujita_noche',
    name: 'Gorro de Brujita',
    category: ClothingCategory.hats,
    price: 42,
    defaultOffsetX: 0,
    defaultOffsetY: -82,
    painter: _drawGorroBrujita,
  ),
  CatalogItem(
    id: 'sombrero_boina_francesa',
    name: 'Boina Francesa',
    category: ClothingCategory.hats,
    price: 35,
    defaultOffsetX: 5,
    defaultOffsetY: -72,
    painter: _drawBoinaFrancesa,
  ),
  CatalogItem(
    id: 'sombrero_paja_verano',
    name: 'Sombrero de Paja',
    category: ClothingCategory.hats,
    price: 30,
    defaultOffsetX: 0,
    defaultOffsetY: -74,
    painter: _drawSombreroPaja,
  ),
  CatalogItem(
    id: 'sombrero_corona_real',
    name: 'Corona Real',
    category: ClothingCategory.hats,
    price: 50,
    defaultOffsetX: 0,
    defaultOffsetY: -80,
    painter: _drawCoronaReal,
  ),

  // --- 5. ZAPATOS (5) con anclaje a los pies (offsetY: 95) ---
  CatalogItem(
    id: 'zapatos_converse_rojos',
    name: 'Zapatitos Converse Rojos',
    category: ClothingCategory.shoes,
    price: 35,
    defaultOffsetX: 0,
    defaultOffsetY: 95,
    painter: _drawConverseRojos,
  ),
  CatalogItem(
    id: 'zapatos_lluvia_amarillas',
    name: 'Botitas de Lluvia Amarillas',
    category: ClothingCategory.shoes,
    price: 35,
    defaultOffsetX: 0,
    defaultOffsetY: 95,
    painter: _drawBotitasLluvia,
  ),
  CatalogItem(
    id: 'zapatos_pantuflas_garabito',
    name: 'Pantuflas de Garabito',
    category: ClothingCategory.shoes,
    price: 38,
    defaultOffsetX: 0,
    defaultOffsetY: 95,
    painter: _drawPantuflasGarabito,
  ),
  CatalogItem(
    id: 'zapatos_formales_charol',
    name: 'Zapatos Formales Charol',
    category: ClothingCategory.shoes,
    price: 40,
    defaultOffsetX: 0,
    defaultOffsetY: 95,
    painter: _drawZapatosCharol,
  ),
  CatalogItem(
    id: 'zapatos_deportivos_verdes',
    name: 'Tenis Deportivos Verdes',
    category: ClothingCategory.shoes,
    price: 35,
    defaultOffsetX: 0,
    defaultOffsetY: 95,
    painter: _drawTenisDeportivos,
  ),
];

// =============================================================
// PINTORES VECTORIALES ARTESANALES (ESTILO CUADERNO GARABU)
// =============================================================

Paint _sketchOutline({double strokeWidth = 3.0, Color color = const Color(0xFF2B221E)}) {
  return Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
}

Paint _sketchFill(Color color) {
  return Paint()
    ..color = color
    ..style = PaintingStyle.fill;
}

// --- PINTORES: LAZOS ---
void _drawLazoRojo(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final fill = _sketchFill(const Color(0xFFE53935));
  final outline = _sketchOutline();

  // Lazos laterales
  final pathLeft = Path()
    ..moveTo(cx, cy)
    ..quadraticBezierTo(cx - 35, cy - 25, cx - 45, cy)
    ..quadraticBezierTo(cx - 35, cy + 25, cx, cy);
  canvas.drawPath(pathLeft, fill);
  canvas.drawPath(pathLeft, outline);

  final pathRight = Path()
    ..moveTo(cx, cy)
    ..quadraticBezierTo(cx + 35, cy - 25, cx + 45, cy)
    ..quadraticBezierTo(cx + 35, cy + 25, cx, cy);
  canvas.drawPath(pathRight, fill);
  canvas.drawPath(pathRight, outline);

  // Colitas colgantes
  final tails = Path()
    ..moveTo(cx - 6, cy + 4)
    ..lineTo(cx - 22, cy + 34)
    ..lineTo(cx - 14, cy + 34)
    ..lineTo(cx, cy + 6)
    ..lineTo(cx + 14, cy + 34)
    ..lineTo(cx + 22, cy + 34)
    ..lineTo(cx + 6, cy + 4);
  canvas.drawPath(tails, fill);
  canvas.drawPath(tails, outline);

  // Nudo central
  canvas.drawCircle(Offset(cx, cy), 9, fill);
  canvas.drawCircle(Offset(cx, cy), 9, outline);
}

void _drawLazoRosa(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final fill = _sketchFill(const Color(0xFFF48FB1));
  final outline = _sketchOutline(color: const Color(0xFF4A148C));

  final pathLeft = Path()
    ..moveTo(cx, cy)
    ..cubicTo(cx - 40, cy - 28, cx - 50, cy + 15, cx, cy);
  canvas.drawPath(pathLeft, fill);
  canvas.drawPath(pathLeft, outline);

  final pathRight = Path()
    ..moveTo(cx, cy)
    ..cubicTo(cx + 40, cy - 28, cx + 50, cy + 15, cx, cy);
  canvas.drawPath(pathRight, fill);
  canvas.drawPath(pathRight, outline);

  // Colitas largas
  final tailL = Path()
    ..moveTo(cx - 5, cy + 5)
    ..quadraticBezierTo(cx - 25, cy + 20, cx - 30, cy + 45)
    ..lineTo(cx - 20, cy + 42)
    ..quadraticBezierTo(cx - 15, cy + 22, cx, cy + 5);
  canvas.drawPath(tailL, fill);
  canvas.drawPath(tailL, outline);

  final tailR = Path()
    ..moveTo(cx + 5, cy + 5)
    ..quadraticBezierTo(cx + 25, cy + 20, cx + 30, cy + 45)
    ..lineTo(cx + 20, cy + 42)
    ..quadraticBezierTo(cx + 15, cy + 22, cx, cy + 5);
  canvas.drawPath(tailR, fill);
  canvas.drawPath(tailR, outline);

  canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 14, height: 16), fill);
  canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 14, height: 16), outline);
}

void _drawLazoMarinero(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final fill = _sketchFill(const Color(0xFF1565C0));
  final outline = _sketchOutline();

  final pathL = Path()
    ..moveTo(cx, cy)
    ..lineTo(cx - 42, cy - 18)
    ..lineTo(cx - 36, cy + 18)
    ..close();
  canvas.drawPath(pathL, fill);
  canvas.drawPath(pathL, outline);

  final pathR = Path()
    ..moveTo(cx, cy)
    ..lineTo(cx + 42, cy - 18)
    ..lineTo(cx + 36, cy + 18)
    ..close();
  canvas.drawPath(pathR, fill);
  canvas.drawPath(pathR, outline);

  // Raya blanca
  final whitePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;
  canvas.drawLine(Offset(cx - 38, cy - 12), Offset(cx - 33, cy + 12), whitePaint);
  canvas.drawLine(Offset(cx + 38, cy - 12), Offset(cx + 33, cy + 12), whitePaint);

  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 14), const Radius.circular(4)), fill);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 14), const Radius.circular(4)), outline);
}

void _drawLazoGotico(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final fill = _sketchFill(const Color(0xFF212121));
  final outline = _sketchOutline(color: const Color(0xFF616161));

  final pathL = Path()
    ..moveTo(cx, cy)
    ..quadraticBezierTo(cx - 40, cy - 20, cx - 48, cy + 4)
    ..quadraticBezierTo(cx - 35, cy + 22, cx, cy);
  canvas.drawPath(pathL, fill);
  canvas.drawPath(pathL, outline);

  final pathR = Path()
    ..moveTo(cx, cy)
    ..quadraticBezierTo(cx + 40, cy - 20, cx + 48, cy + 4)
    ..quadraticBezierTo(cx + 35, cy + 22, cx, cy);
  canvas.drawPath(pathR, fill);
  canvas.drawPath(pathR, outline);

  // Gema roja central
  canvas.drawCircle(Offset(cx, cy), 8, _sketchFill(const Color(0xFFC62828)));
  canvas.drawCircle(Offset(cx, cy), 8, outline);
}

void _drawCorbatin(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final fill = _sketchFill(const Color(0xFF1E1E1E));
  final outline = _sketchOutline(strokeWidth: 2.6);

  final pathL = Path()
    ..moveTo(cx, cy)
    ..lineTo(cx - 34, cy - 16)
    ..lineTo(cx - 34, cy + 16)
    ..close();
  canvas.drawPath(pathL, fill);
  canvas.drawPath(pathL, outline);

  final pathR = Path()
    ..moveTo(cx, cy)
    ..lineTo(cx + 34, cy - 16)
    ..lineTo(cx + 34, cy + 16)
    ..close();
  canvas.drawPath(pathR, fill);
  canvas.drawPath(pathR, outline);

  // Botón dorado
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 16), const Radius.circular(3)), _sketchFill(const Color(0xFFFFD54F)));
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 16), const Radius.circular(3)), outline);
}

// --- PINTORES: LENTES ---
void _drawLentesVintage(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final framePaint = Paint()
    ..color = const Color(0xFFD4AF37)
    ..strokeWidth = 3.2
    ..style = PaintingStyle.stroke;
  final glassPaint = Paint()
    ..color = Colors.cyan.withValues(alpha: 0.15)
    ..style = PaintingStyle.fill;

  // Lente izquierdo
  canvas.drawCircle(Offset(cx - 28, cy), 20, glassPaint);
  canvas.drawCircle(Offset(cx - 28, cy), 20, framePaint);

  // Lente derecho
  canvas.drawCircle(Offset(cx + 28, cy), 20, glassPaint);
  canvas.drawCircle(Offset(cx + 28, cy), 20, framePaint);

  // Puente
  final bridge = Path()
    ..moveTo(cx - 8, cy - 4)
    ..quadraticBezierTo(cx, cy - 12, cx + 8, cy - 4);
  canvas.drawPath(bridge, framePaint);
}

void _drawLentesSol(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final darkFill = _sketchFill(const Color(0xFF1A1A1A));
  final outline = _sketchOutline(strokeWidth: 2.8);

  final lRect = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 48, cy - 14, 42, 28), const Radius.circular(8));
  canvas.drawRRect(lRect, darkFill);
  canvas.drawRRect(lRect, outline);

  final rRect = RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6, cy - 14, 42, 28), const Radius.circular(8));
  canvas.drawRRect(rRect, darkFill);
  canvas.drawRRect(rRect, outline);

  // Puente
  canvas.drawRect(Rect.fromLTWH(cx - 8, cy - 10, 16, 5), darkFill);
  canvas.drawRect(Rect.fromLTWH(cx - 8, cy - 10, 16, 5), outline);
}

void _drawLentesCorazon(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final pinkFill = _sketchFill(const Color(0xFFFF4081).withValues(alpha: 0.35));
  final outline = _sketchOutline(color: const Color(0xFFC2185B), strokeWidth: 3.2);

  void drawHeart(double centerX) {
    final path = Path();
    path.moveTo(centerX, cy + 14);
    path.cubicTo(centerX - 24, cy - 4, centerX - 18, cy - 18, centerX, cy - 8);
    path.cubicTo(centerX + 18, cy - 18, centerX + 24, cy - 4, centerX, cy + 14);
    canvas.drawPath(path, pinkFill);
    canvas.drawPath(path, outline);
  }

  drawHeart(cx - 26);
  drawHeart(cx + 26);
  canvas.drawLine(Offset(cx - 6, cy - 4), Offset(cx + 6, cy - 4), outline);
}

void _drawLentesNerd(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final frameFill = _sketchFill(const Color(0xFF263238));
  final glassFill = _sketchFill(Colors.white.withValues(alpha: 0.2));

  // Marcos gruesos
  final lRect = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 50, cy - 16, 44, 32), const Radius.circular(6));
  canvas.drawRRect(lRect, frameFill);
  final lInner = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 44, cy - 11, 32, 22), const Radius.circular(4));
  canvas.drawRRect(lInner, glassFill);

  final rRect = RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6, cy - 16, 44, 32), const Radius.circular(6));
  canvas.drawRRect(rRect, frameFill);
  final rInner = RRect.fromRectAndRadius(Rect.fromLTWH(cx + 12, cy - 11, 32, 22), const Radius.circular(4));
  canvas.drawRRect(rInner, glassFill);

  // Cinta adhesiva blanca en el puente (clásico nerd)
  canvas.drawRect(Rect.fromLTWH(cx - 8, cy - 12, 16, 8), _sketchFill(const Color(0xFFFFFFFF)));
  canvas.drawRect(Rect.fromLTWH(cx - 8, cy - 12, 16, 8), _sketchOutline(strokeWidth: 1.5));
}

void _drawMonoculo(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final goldPaint = Paint()
    ..color = const Color(0xFFFFB300)
    ..strokeWidth = 3.5
    ..style = PaintingStyle.stroke;

  canvas.drawCircle(Offset(cx + 20, cy), 22, _sketchFill(Colors.amber.withValues(alpha: 0.1)));
  canvas.drawCircle(Offset(cx + 20, cy), 22, goldPaint);

  // Cadena colgante
  final chain = Path()
    ..moveTo(cx + 42, cy)
    ..quadraticBezierTo(cx + 54, cy + 25, cx + 46, cy + 45);
  canvas.drawPath(chain, goldPaint..strokeWidth = 2.0);
}

// --- PINTORES: GORRAS ---
void _drawGorraRoja(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final redFill = _sketchFill(const Color(0xFFD32F2F));
  final outline = _sketchOutline();

  // Copa de la gorra
  final capPath = Path()
    ..moveTo(cx - 48, cy + 6)
    ..quadraticBezierTo(cx - 40, cy - 36, cx, cy - 36)
    ..quadraticBezierTo(cx + 40, cy - 36, cx + 48, cy + 6)
    ..close();
  canvas.drawPath(capPath, redFill);
  canvas.drawPath(capPath, outline);

  // Visera curva
  final visor = Path()
    ..moveTo(cx - 52, cy + 6)
    ..quadraticBezierTo(cx, cy + 22, cx + 58, cy + 6)
    ..lineTo(cx + 46, cy + 1)
    ..quadraticBezierTo(cx, cy + 14, cx - 44, cy + 1)
    ..close();
  canvas.drawPath(visor, _sketchFill(const Color(0xFFB71C1C)));
  canvas.drawPath(visor, outline);

  // Botón superior
  canvas.drawCircle(Offset(cx, cy - 36), 4, _sketchFill(Colors.white));
  canvas.drawCircle(Offset(cx, cy - 36), 4, outline);
}

void _drawGorraAzul(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final blueFill = _sketchFill(const Color(0xFF1976D2));
  final outline = _sketchOutline();

  final capPath = Path()
    ..moveTo(cx - 46, cy + 6)
    ..quadraticBezierTo(cx - 36, cy - 34, cx, cy - 34)
    ..quadraticBezierTo(cx + 36, cy - 34, cx + 46, cy + 6)
    ..close();
  canvas.drawPath(capPath, blueFill);
  canvas.drawPath(capPath, outline);

  // Letra G blanca bordada
  final textPainter = TextPainter(
    text: const TextSpan(text: 'G', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, Offset(cx - 6, cy - 24));

  // Visera
  final visor = Path()
    ..moveTo(cx - 50, cy + 6)
    ..quadraticBezierTo(cx, cy + 20, cx + 54, cy + 6)
    ..close();
  canvas.drawPath(visor, _sketchFill(const Color(0xFF0D47A1)));
  canvas.drawPath(visor, outline);
}

void _drawGorraLila(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final lilaFill = _sketchFill(const Color(0xFFCE93D8));
  final outline = _sketchOutline(color: const Color(0xFF4A148C));

  final capPath = Path()
    ..moveTo(cx - 46, cy + 6)
    ..quadraticBezierTo(cx, cy - 38, cx + 46, cy + 6)
    ..close();
  canvas.drawPath(capPath, lilaFill);
  canvas.drawPath(capPath, outline);

  // Florcita en la copa
  canvas.drawCircle(Offset(cx, cy - 14), 6, _sketchFill(Colors.white));
  canvas.drawCircle(Offset(cx, cy - 14), 3, _sketchFill(Colors.amber));

  final visor = Path()
    ..moveTo(cx - 48, cy + 6)
    ..quadraticBezierTo(cx, cy + 20, cx + 52, cy + 6)
    ..close();
  canvas.drawPath(visor, _sketchFill(const Color(0xFFBA68C8)));
  canvas.drawPath(visor, outline);
}

void _drawGorraPato(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final yellowFill = _sketchFill(const Color(0xFFFFEB3B));
  final orangeFill = _sketchFill(const Color(0xFFFF9800));
  final outline = _sketchOutline();

  // Copa amarilla
  final capPath = Path()
    ..moveTo(cx - 46, cy + 6)
    ..quadraticBezierTo(cx, cy - 36, cx + 46, cy + 6)
    ..close();
  canvas.drawPath(capPath, yellowFill);
  canvas.drawPath(capPath, outline);

  // Ojitos de pato
  canvas.drawCircle(Offset(cx - 12, cy - 16), 3.5, _sketchFill(Colors.black));
  canvas.drawCircle(Offset(cx + 12, cy - 16), 3.5, _sketchFill(Colors.black));

  // Pico de pato como visera
  final beak = Path()
    ..moveTo(cx - 30, cy + 4)
    ..quadraticBezierTo(cx, cy + 26, cx + 30, cy + 4)
    ..close();
  canvas.drawPath(beak, orangeFill);
  canvas.drawPath(beak, outline);
}

void _drawGorraGamer(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final darkFill = _sketchFill(const Color(0xFF212121));
  final neonFill = _sketchFill(const Color(0xFF76FF03));
  final outline = _sketchOutline();

  final capPath = Path()
    ..moveTo(cx - 46, cy + 6)
    ..quadraticBezierTo(cx, cy - 36, cx + 46, cy + 6)
    ..close();
  canvas.drawPath(capPath, darkFill);
  canvas.drawPath(capPath, outline);

  // Logo gamer
  canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 14), width: 16, height: 10), neonFill);

  // Visera verde neón
  final visor = Path()
    ..moveTo(cx - 50, cy + 6)
    ..quadraticBezierTo(cx, cy + 20, cx + 52, cy + 6)
    ..close();
  canvas.drawPath(visor, neonFill);
  canvas.drawPath(visor, outline);
}

// --- PINTORES: SOMBREROS ---
void _drawSombreroCopa(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final blackFill = _sketchFill(const Color(0xFF212121));
  final purpleFill = _sketchFill(const Color(0xFF7B1FA2));
  final outline = _sketchOutline();

  // Ala del sombrero
  final brim = Path()
    ..moveTo(cx - 56, cy + 12)
    ..quadraticBezierTo(cx, cy + 20, cx + 56, cy + 12)
    ..quadraticBezierTo(cx, cy + 4, cx - 56, cy + 12);
  canvas.drawPath(brim, blackFill);
  canvas.drawPath(brim, outline);

  // Copa alta
  final crown = Path()
    ..moveTo(cx - 36, cy + 10)
    ..lineTo(cx - 40, cy - 48)
    ..quadraticBezierTo(cx, cy - 54, cx + 40, cy - 48)
    ..lineTo(cx + 36, cy + 10)
    ..close();
  canvas.drawPath(crown, blackFill);
  canvas.drawPath(crown, outline);

  // Cinta morada
  final ribbon = Path()
    ..moveTo(cx - 36, cy + 10)
    ..lineTo(cx - 37, cy - 4)
    ..quadraticBezierTo(cx, cy - 1, cx + 37, cy - 4)
    ..lineTo(cx + 36, cy + 10)
    ..close();
  canvas.drawPath(ribbon, purpleFill);
  canvas.drawPath(ribbon, outline);
}

void _drawGorroBrujita(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final darkPurple = _sketchFill(const Color(0xFF311B92));
  final goldFill = _sketchFill(const Color(0xFFFFD54F));
  final outline = _sketchOutline();

  // Ala ancha y ondulada
  final brim = Path()
    ..moveTo(cx - 62, cy + 10)
    ..quadraticBezierTo(cx, cy + 24, cx + 62, cy + 10)
    ..quadraticBezierTo(cx, cy + 2, cx - 62, cy + 10);
  canvas.drawPath(brim, darkPurple);
  canvas.drawPath(brim, outline);

  // Cono puntiagudo curvado
  final cone = Path()
    ..moveTo(cx - 38, cy + 8)
    ..quadraticBezierTo(cx - 15, cy - 35, cx + 18, cy - 56)
    ..quadraticBezierTo(cx + 38, cy - 64, cx + 45, cy - 52)
    ..quadraticBezierTo(cx + 10, cy - 25, cx + 38, cy + 8)
    ..close();
  canvas.drawPath(cone, darkPurple);
  canvas.drawPath(cone, outline);

  // Hebilla dorada
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2), width: 14, height: 14), const Radius.circular(3)), goldFill);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2), width: 14, height: 14), const Radius.circular(3)), outline);
}

void _drawBoinaFrancesa(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final redFill = _sketchFill(const Color(0xFFB71C1C));
  final outline = _sketchOutline();

  final beret = Path()
    ..moveTo(cx - 48, cy + 6)
    ..cubicTo(cx - 56, cy - 18, cx - 20, cy - 32, cx + 15, cy - 30)
    ..cubicTo(cx + 52, cy - 26, cx + 58, cy - 4, cx + 42, cy + 8)
    ..quadraticBezierTo(cx, cy + 14, cx - 48, cy + 6);
  canvas.drawPath(beret, redFill);
  canvas.drawPath(beret, outline);

  // Rabito de la boina
  final stem = Path()
    ..moveTo(cx + 6, cy - 30)
    ..lineTo(cx + 8, cy - 38);
  canvas.drawPath(stem, outline..strokeWidth = 3);
}

void _drawSombreroPaja(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final strawFill = _sketchFill(const Color(0xFFFFE082));
  final ribbonFill = _sketchFill(const Color(0xFF26C6DA));
  final outline = _sketchOutline();

  // Ala ancha veraniega
  final brim = Path()
    ..moveTo(cx - 64, cy + 12)
    ..quadraticBezierTo(cx, cy + 22, cx + 64, cy + 12)
    ..quadraticBezierTo(cx, cy + 2, cx - 64, cy + 12);
  canvas.drawPath(brim, strawFill);
  canvas.drawPath(brim, outline);

  // Copa redonda
  final crown = Path()
    ..moveTo(cx - 36, cy + 8)
    ..quadraticBezierTo(cx - 34, cy - 28, cx, cy - 28)
    ..quadraticBezierTo(cx + 34, cy - 28, cx + 36, cy + 8)
    ..close();
  canvas.drawPath(crown, strawFill);
  canvas.drawPath(crown, outline);

  // Cinta turquesa
  final ribbon = Path()
    ..moveTo(cx - 36, cy + 8)
    ..lineTo(cx - 35, cy)
    ..quadraticBezierTo(cx, cy + 4, cx + 35, cy)
    ..lineTo(cx + 36, cy + 8)
    ..close();
  canvas.drawPath(ribbon, ribbonFill);
  canvas.drawPath(ribbon, outline);
}

void _drawCoronaReal(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final goldFill = _sketchFill(const Color(0xFFFFD54F));
  final redRuby = _sketchFill(const Color(0xFFD32F2F));
  final outline = _sketchOutline();

  final crown = Path()
    ..moveTo(cx - 45, cy + 10)
    ..lineTo(cx - 48, cy - 24)
    ..lineTo(cx - 24, cy - 6)
    ..lineTo(cx, cy - 36)
    ..lineTo(cx + 24, cy - 6)
    ..lineTo(cx + 48, cy - 24)
    ..lineTo(cx + 45, cy + 10)
    ..close();
  canvas.drawPath(crown, goldFill);
  canvas.drawPath(crown, outline);

  // Rubíes en las puntas
  canvas.drawCircle(Offset(cx - 48, cy - 24), 4, redRuby);
  canvas.drawCircle(Offset(cx, cy - 36), 5, redRuby);
  canvas.drawCircle(Offset(cx + 48, cy - 24), 4, redRuby);
}

// --- PINTORES: ZAPATOS (Par de calzado anclado a los pies) ---
void _drawConverseRojos(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final redFill = _sketchFill(const Color(0xFFE53935));
  final whiteFill = _sketchFill(Colors.white);
  final outline = _sketchOutline();

  void drawShoe(double x, bool isLeft) {
    final sign = isLeft ? -1.0 : 1.0;
    // Zapato cuerpo
    final body = Path()
      ..moveTo(x - (18 * sign), cy - 14)
      ..lineTo(x - (18 * sign), cy + 10)
      ..lineTo(x + (26 * sign), cy + 10)
      ..quadraticBezierTo(x + (28 * sign), cy - 2, x + (14 * sign), cy - 2)
      ..lineTo(x + (4 * sign), cy - 14)
      ..close();
    canvas.drawPath(body, redFill);
    canvas.drawPath(body, outline);

    // Puntera blanca
    final toe = Path()
      ..moveTo(x + (14 * sign), cy + 10)
      ..quadraticBezierTo(x + (28 * sign), cy + 6, x + (24 * sign), cy - 2)
      ..close();
    canvas.drawPath(toe, whiteFill);
    canvas.drawPath(toe, outline);

    // Suela de goma
    final sole = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - (20 * sign).clamp(-22, 22), cy + 8, 46 * sign.abs(), 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(sole, whiteFill);
    canvas.drawRRect(sole, outline);
  }

  drawShoe(cx - 28, true);
  drawShoe(cx + 28, false);
}

void _drawBotitasLluvia(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final yellowFill = _sketchFill(const Color(0xFFFFEB3B));
  final outline = _sketchOutline();

  void drawBoot(double x, bool isLeft) {
    final sign = isLeft ? -1.0 : 1.0;
    final boot = Path()
      ..moveTo(x - (16 * sign), cy - 20)
      ..lineTo(x - (16 * sign), cy + 12)
      ..lineTo(x + (26 * sign), cy + 12)
      ..quadraticBezierTo(x + (28 * sign), cy + 2, x + (12 * sign), cy + 2)
      ..lineTo(x + (10 * sign), cy - 20)
      ..close();
    canvas.drawPath(boot, yellowFill);
    canvas.drawPath(boot, outline);

    // Ribete superior
    canvas.drawLine(Offset(x - (16 * sign), cy - 20), Offset(x + (10 * sign), cy - 20), outline..strokeWidth = 3.5);
  }

  drawBoot(cx - 28, true);
  drawBoot(cx + 28, false);
}

void _drawPantuflasGarabito(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final softWhite = _sketchFill(const Color(0xFFF5F5F5));
  final outline = _sketchOutline();

  void drawSlipper(double x, bool isLeft) {
    final sign = isLeft ? -1.0 : 1.0;
    // Cuerpo mullido
    final slip = Path()
      ..moveTo(x - (20 * sign), cy + 12)
      ..quadraticBezierTo(x, cy - 14, x + (26 * sign), cy + 12)
      ..close();
    canvas.drawPath(slip, softWhite);
    canvas.drawPath(slip, outline);

    // Orejitas de osito
    canvas.drawCircle(Offset(x + (8 * sign), cy - 8), 5, softWhite);
    canvas.drawCircle(Offset(x + (8 * sign), cy - 8), 5, outline);
    canvas.drawCircle(Offset(x + (20 * sign), cy - 4), 5, softWhite);
    canvas.drawCircle(Offset(x + (20 * sign), cy - 4), 5, outline);

    // Carita dormilona (ojito '_')
    canvas.drawLine(Offset(x + (10 * sign), cy + 2), Offset(x + (16 * sign), cy + 2), outline);
  }

  drawSlipper(cx - 28, true);
  drawSlipper(cx + 28, false);
}

void _drawZapatosCharol(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final blackFill = _sketchFill(const Color(0xFF1C1C1C));
  final outline = _sketchOutline(strokeWidth: 2.6);

  void drawShoe(double x, bool isLeft) {
    final sign = isLeft ? -1.0 : 1.0;
    final shoe = Path()
      ..moveTo(x - (16 * sign), cy - 6)
      ..lineTo(x - (16 * sign), cy + 10)
      ..lineTo(x + (28 * sign), cy + 10)
      ..quadraticBezierTo(x + (30 * sign), cy + 2, x + (12 * sign), cy - 6)
      ..close();
    canvas.drawPath(shoe, blackFill);
    canvas.drawPath(shoe, outline);

    // Brillo de charol blanco
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x + (6 * sign), cy), Offset(x + (18 * sign), cy + 4), shine);
  }

  drawShoe(cx - 28, true);
  drawShoe(cx + 28, false);
}

void _drawTenisDeportivos(Canvas canvas, Size size) {
  final cx = size.width * 0.5;
  final cy = size.height * 0.5;
  final greenFill = _sketchFill(const Color(0xFF43A047));
  final whiteFill = _sketchFill(Colors.white);
  final outline = _sketchOutline();

  void drawSneaker(double x, bool isLeft) {
    final sign = isLeft ? -1.0 : 1.0;
    final body = Path()
      ..moveTo(x - (18 * sign), cy - 10)
      ..lineTo(x - (18 * sign), cy + 10)
      ..lineTo(x + (28 * sign), cy + 10)
      ..quadraticBezierTo(x + (30 * sign), cy + 2, x + (10 * sign), cy - 8)
      ..close();
    canvas.drawPath(body, greenFill);
    canvas.drawPath(body, outline);

    // Raya deportiva blanca
    final stripe = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x - (10 * sign), cy - 4), Offset(x + (16 * sign), cy + 6), stripe);

    // Suela
    final sole = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - (20 * sign).clamp(-22, 22), cy + 8, 50 * sign.abs(), 5),
      const Radius.circular(2),
    );
    canvas.drawRRect(sole, whiteFill);
    canvas.drawRRect(sole, outline);
  }

  drawSneaker(cx - 28, true);
  drawSneaker(cx + 28, false);
}
