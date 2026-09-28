import 'package:flutter/material.dart';

class AppConfig {
  // URL del server backend (Render)
  static const String serverUrl = 'https://prenota.gentlemanbarber.it';
  static const String nomeAttivita = 'Gentleman Barber';

  // Credenziali EmailJS
  static const String emailServiceId = 'service_r51lmpo';
  static const String emailTemplateId = 'template_oz3g1jy';
  static const String emailUserId = 'DT7gJqsblmEpebX0M';

  // Credenziali Admin
  static const String adminUser = 'admin';
  static const String adminPass = 'barber2026';
  // Colori del Brand
  static const Color primaryColor = Color(0xFF0a0a0a); // Sfondo principale
  static const Color cardColor = Color(0xFF161616); // Sfondo card/input
  static const Color accentColor = Colors.white; // Colore principale / bottoni
  static const Color textColor = Colors.white70; // Testo secondario
}
