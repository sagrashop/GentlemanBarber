import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GentlemanBarberApp());
}

class GentlemanBarberApp extends StatelessWidget {
  const GentlemanBarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gentleman Barber - Listino e Prenotazioni',
      debugShowCheckedModeBanner: false,
      locale: const Locale('it', 'IT'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it', 'IT')],
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: const Color(0xFF0a0a0a),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
          surface: Color(0xFF161616),
        ),
      ),
      home: const BookingScreen(),
    );
  }
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State createState() => _BookingScreenState();
}

class _BookingScreenState extends State {
  Map selectedService = {
    'name': 'TAGLIO COMPLETO',
    'price': '15€',
    'time': '40 min',
  };

  String selectedTime = '';
  DateTime selectedDate = DateTime.now();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final List<Map<String, String>> services = [
    {
      'name': 'TAGLIO COMPLETO',
      'price': '15€',
      'time': '40 min',
      'desc': 'Shampoo incluso • Consulenza personalizzata. Taglio con macchinetta e/o forbici, sfumatura e styling.',
    },
    {
      'name': 'TAGLIO + BARBA',
      'price': '18€',
      'time': '45 min',
      'desc': 'Shampoo incluso • Consulenza. Taglio completo con sfumatura abbinato alla cura e definizione della barba.',
    },
    {
      'name': 'BARBA',
      'price': '7€',
      'time': '10 min',
      'desc': 'Sagomatura e definizione della barba oppure rasatura a lametta, con rifinitura precisa.',
    },
    {
      'name': 'BARBA + TRATTAMENTO',
      'price': '15€',
      'time': '20 min',
      'desc': 'Shampoo incluso. Servizio barba con trattamento dedicato alla cura della pelle e del pelo.',
    },
    {
      'name': 'MECHES',
      'price': '50€',
      'time': '50 min',
      'desc': 'Servizio dedicato alla trasformazione del look, con lavorazione personalizzata.',
    },
    {
      'name': 'TOTAL WHITY',
      'price': '70€',
      'time': '50 min',
      'desc': 'Servizio completo di schiaritura per ottenere un effetto Total White personalizzato.',
    },
    {
      'name': 'TRATTAMENTO LISCIANTE',
      'price': 'Variabile',
      'time': '40 min',
      'desc': 'Trattamento lisciante professionale studiato in base a texture, densità e lunghezza.',
    },
    {
      'name': 'PERMANENTE',
      'price': '60€',
      'time': '1 ora',
      'desc': 'Servizio professionale per ondulare o arricciare il capello in base allo stile desiderato.',
    },
  ];

  List getAvailableTimeSlots() {
    int weekday = selectedDate.weekday;

    if (weekday == DateTime.monday || weekday == DateTime.sunday) {
      return []; // Chiuso
    }
    if (weekday >= DateTime.tuesday && weekday <= DateTime.thursday) {
      return [
        '08:00',
        '09:00',
        '10:00',
        '11:00',
        '12:00',
        '15:00',
        '16:00',
        '17:00',
        '18:00',
        '19:00',
      ];
    }
    if (weekday == DateTime.friday || weekday == DateTime.saturday) {
      return [
        '08:30',
        '09:30',
        '10:30',
        '11:30',
        '15:00',
        '16:00',
        '17:00',
        '18:00',
        '19:00',
      ];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _updateDefaultTime();
  }

  void _updateDefaultTime() {
    List slots = getAvailableTimeSlots();
    if (slots.isNotEmpty) {
      selectedTime = slots.first;
    } else {
      selectedTime = '';
    }
  }

  Future _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF1a1a1a),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _updateDefaultTime();
      });
    }
  }

  // --- FUNZIONE AGGIORNATA PER COMUNICARE CON IL SERVER E SALVARE SU MONGO ---
  Future _confirmBooking() async {
    List currentSlots = getAvailableTimeSlots();
    if (currentSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Il negozio è chiuso in questo giorno. Scegli un\'altra data.',
          ),
        ),
      );
      return;
    }

    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore, inserisci nome e telefono.')),
      );
      return;
    }

    // Indirizzo del server Node.js (usa http://localhost:3000 o http://10.0.2.2:3000 per emulatore Android)
    final url = Uri.parse('http://localhost:3000/api/prenotazioni');

    final bodyData = {
      'servizio': selectedService['name'],
      'prezzo': selectedService['price'],
      'data':
          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
      'ora': selectedTime,
      'nome': nameController.text,
      'telefono': phoneController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 201) {
        // Salvataggio riuscito su MongoDB
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1a1a1a),
            title: const Text(
              'Prenotazione Confermata',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Grazie ${nameController.text}!\n\nServizio: ${selectedService['name']} (${selectedService['price']})\nData: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}\nOra: $selectedTime\n\nSalvato correttamente nel database!",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    nameController.clear();
                    phoneController.clear();
                  });
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Errore restituito dal server (es. orario già occupato grazie all'indice unico)
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Errore durante la prenotazione',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile connettersi al server: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List currentSlots = getAvailableTimeSlots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GENTLEMAN BARBER',
          style: TextStyle(
            letterSpacing: 3,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. LISTINO SERVIZI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            ...services.map((service) {
              bool isSelected = selectedService['name'] == service['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedService = service;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white24,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service['desc']!,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Durata: ${service['time']}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        service['price']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            const Text(
              '2. SCEGLI DATA E ORA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Data: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Modifica',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),
            const Text(
              'Orari Disponibili',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 8),

            currentSlots.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Il negozio è chiuso in questo giorno (Lunedì o Domenica).',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: currentSlots.map((time) {
                      bool isSelected = selectedTime == time;
                      return ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        selectedColor: Colors.white,
                        backgroundColor: const Color(0xFF161616),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (bool selected) {
                          setState(() {
                            selectedTime = time;
                          });
                        },
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 20),
            const Text(
              '3. I TUOI DATI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nome e Cognome',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF161616),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefono',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF161616),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _confirmBooking,
                child: const Text(
                  'CONFERMA PRENOTAZIONE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
