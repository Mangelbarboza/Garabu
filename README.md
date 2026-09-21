# 🐾 Garabu - Mascota Virtual Compartida para Parejas

> *"Crear, cuidar y crecer"*

**Garabu** es una aplicación móvil y PWA diseñada para parejas, centrada en el apego emocional a través de la co-creación a mano de una mascota virtual ("bichito" o "garabato") y la retención mediante rachas diarias (*streaks*).

---

## 🎨 Paleta de Diseño y Estilo Visual

- **Fondo:** Blanco suave y papel cálido (`#FFFFFF`, `#FAF8F5`, `#FDFCFA`).
- **Acentos:** Marrones claros elegantes, tonos kraft, arena y café con leche (`#C19A6B`, `#D2B48C`, `#8D6E63`, `#4A3E3D`).
- **Estética:** Minimalista, cálida, limpia y terrosa. Diseñada para un público maduro con un entorno privado 1-a-1.

---

## 🏗️ Arquitectura Modular (Feature-First)

El proyecto está estructurado siguiendo principios de Clean Architecture y Feature-First con `flutter_riverpod`:

```
lib/
├── core/
│   ├── theme/
│   │   └── garabu_theme.dart          # Paleta terrosa, estilos de botones y tipografía
│   ├── utils/
│   │   ├── flood_fill.dart            # Algoritmo BFS para balde de pintura en Dart puro
│   │   └── image_exporter.dart        # Renderizado de capas PNG transparentes
│   └── widgets/
│       └── notebook_background.dart   # Textura y líneas de libreta/cuaderno
├── features/
│   ├── auth/                          # Autenticación minimalista (Email, Nombre, Edad)
│   ├── lobby/                         # Matchmaking con código de 6 dígitos
│   ├── pet/                           # Modelos de Mascota, coordenadas de ojos y repositorios
│   ├── canvas/                        # Motor de dibujo (CustomPainter, Balde y Ojos superpuestos)
│   └── dashboard/                     # Menú principal, Stack multicapa y contador de rachas
└── main.dart                          # Inicialización de Riverpod y enrutamiento reactivo
```

---

## 📱 Flujo del MVP

1. **Autenticación y Bienvenida:**
   - Slogan central: *"Crear, cuidar y crecer"*.
   - Registro e inicio de sesión minimalista con Firebase Auth.
2. **Lobby de Vinculación (Matchmaking):**
   - **Opción 1:** Genera un código de 6 dígitos único para invitar a la pareja.
   - **Opción 2:** La pareja ingresa el código para unirse a la misma sala.
   - Tip visible: *"💡 Tip: Se recomienda crear a su mascota juntos en persona o por llamada."*
3. **Flujo del Usuario 1 (Creador del Cuerpo):**
   - Asignación de nombre: *"Pongamos nombre a nuestra mascota: "*.
   - Lienzo de dibujo con líneas de cuaderno, lápiz y balde de pintura (Flood Fill).
   - **Ojos interactivos:** Widgets superpuestos en `Stack` sobre el canvas, arrastrables mediante coordenadas relativas `(0.0 a 1.0)`, con selector de color y switch de pestañas.
   - Al terminar, se exporta el dibujo como PNG transparente y se guarda en Firebase.
4. **Flujo del Usuario 2 (Creador de la Primera Prenda):**
   - Pantalla de espera en tiempo real: *"Esperando a que [Nombre del Usuario 1] dibuje el cuerpo..."*.
   - Transición automática al completarse el cuerpo.
   - Fondo bloqueado (no editable) mostrando el cuerpo y los ojos ya colocados.
   - Lienzo para dibujar **UNA** prenda con lápiz y balde.
   - Al terminar, exporta la prenda como PNG transparente.
5. **Dashboard Principal:**
   - Mascota renderizada en un `Stack` estricto:
     1. Fondo de cuaderno
     2. Imagen PNG del Cuerpo
     3. Widgets de Ojos estáticos
     4. Imagen PNG de la Prenda
   - Contador de racha: *"Racha actual: X días 🔥"*.
   - Botones de cuidado: Alimentar, Acariciar y Clóset.

---

## 🚀 Compilación y Ejecución

### Prerrequisitos
- Flutter SDK 3.0.0 o superior
- Conexión a Firebase (Opcional: la app incluye un modo reactivo demo/local automático en caso de no vincular credenciales inmediatamente).

### Ejecución en Modo Web / PWA (Para usuarios de iOS y navegador):
```bash
flutter run -d chrome
# O compilar como PWA de producción:
flutter build web --pwa-strategy=offline-first
```

### Compilación para Android (Google Play AAB):
```bash
flutter build appbundle
```

### Configuración de Firebase en Producción:
```bash
flutterfire configure
```
Esto generará `lib/firebase_options.dart` y vinculará automáticamente el proyecto con Firebase Auth, Firestore y Cloud Storage.
