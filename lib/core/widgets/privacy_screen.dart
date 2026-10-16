import 'package:flutter/material.dart';

const garabuPrivacyText = '''Garabu — Política de privacidad
Tropic Code · Actualizada el 15 de octubre de 2026
Contacto: Angelbarbozareyes29@gmail.com

Garabu es un juego de mascota virtual compartida para personas de 16 años en adelante. Es gratuito y no contiene anuncios ni compras con dinero real.

Datos y finalidad
Para crear y mantener tu cuenta usamos tu nombre o alias, correo, edad e identificador de usuario. Firebase Authentication gestiona las credenciales. Si eliges Google, recibimos los datos de cuenta que autorices.
Guardamos en Cloud Firestore la vinculación de pareja, códigos de invitación, dibujos de mascota y prendas, nombres, frases, cartas, respuestas de minijuegos, puntuaciones, inventario, rachas y fechas de actividad. Estos datos permiten sincronizar la experiencia y compartirla con la persona que vincules. Evita escribir datos sensibles en cartas, dibujos o respuestas.

Destinatarios y seguridad
Google Firebase procesa datos para autenticación y almacenamiento. Tu pareja vinculada puede ver el contenido compartido y la actividad de la sala. No hay un buscador público de perfiles. No vendemos tus datos ni los utilizamos para publicidad. Los servicios Firebase usan conexiones cifradas en tránsito. Ningún sistema garantiza seguridad absoluta.
Firebase también recibe la dirección IP y datos técnicos de la aplicación, el sistema y las versiones de sus bibliotecas para autenticar las cuentas, prevenir abusos y mantener sus servicios. No usamos estos registros para publicidad ni para localizarte.
La aplicación no solicita acceso a ubicación, contactos, cámara o micrófono. Las imágenes de la mascota se dibujan dentro de Garabu.

Conservación y eliminación
Los datos permanecen mientras la cuenta y la experiencia compartida sigan activas. En Ajustes > Cuenta y Seguridad > Eliminar Cuenta puedes solicitar la eliminación del perfil y las credenciales. Una sesión antigua puede requerir volver a iniciar sesión. Los contenidos de la sala compartida pueden permanecer disponibles para la otra persona; eliminar el perfil no borra automáticamente las cartas, los dibujos o la sala.
Para solicitar la eliminación de tu cuenta y de los datos asociados, incluidos contenidos compartidos, escribe a Angelbarbozareyes29@gmail.com con el asunto «Eliminar cuenta Garabu», desde el correo registrado. Indica qué contenido quieres eliminar. No envíes tu contraseña. Verificaremos la titularidad y coordinaremos la eliminación y cualquier dato que deba conservarse por obligaciones legales o por derechos de la otra persona. También puedes usar este contacto sin tener instalada la aplicación.

Tus opciones
Puedes modificar los contenidos que la app permite editar, cerrar sesión y solicitar acceso, corrección o eliminación mediante el correo de contacto. No está dirigida a menores de 16 años. Si detectas una cuenta de un menor de esa edad, avísanos para revisarla.

Cambios
Publicaremos las actualizaciones de esta política con su fecha. Consulta esta información antes de compartir contenido personal.
''';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Privacidad y eliminación de datos')),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: SelectableText(garabuPrivacyText,
              style: TextStyle(fontSize: 15, height: 1.5)),
        ),
      );
}
