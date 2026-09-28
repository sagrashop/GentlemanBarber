import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // Importa la configurazione universale

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
      return [];
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

  // --- FUNZIONE DI CONFERMA USANDO CONFIG.DART ---
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

    if (selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un orario valido.')),
      );
      return;
    }

    final String formattedDate =
        '${selectedDate.day.toString()}/${selectedDate.month.toString()}/${selectedDate.year.toString()}';

    try {
      // 1. Invio al server usando AppConfig.serverUrl
      final response = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/prenotazioni'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "servizio": selectedService['name'],
          "prezzo": selectedService['price'],
          "data": formattedDate,
          "ora": selectedTime,
          "nome": nameController.text,
          "telefono": phoneController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // 2. Invio Email tramite EmailJS usando AppConfig
        try {
          await http.post(
            Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': AppConfig.emailServiceId,
              'template_id': AppConfig.emailTemplateId,
              'user_id': AppConfig.emailUserId,
              'template_params': {
                'nome': nameController.text,
                'servizio': selectedService['name'],
                'data': formattedDate,
                'ora': selectedTime,
                'telefono': phoneController.text,
              },
            }),
          );
        } catch (emailError) {
          print('Errore invio email: $emailError');
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1a1a1a),
            title: const Text(
              'Prenotazione Confermata',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Grazie ${nameController.text}!\n\nServizio: ${selectedService['name']} (${selectedService['price']})\nDurata: ${selectedService['time']}\nData: $formattedDate\nOra: $selectedTime\n\nSalvato nel database e email inviata!',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Errore durante la prenotazione.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile connettersi al server.')),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminLoginScreen(),
                ),
              );
            },
          ),
        ],
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
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Data: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

// ==========================================
// SCHERMATA DI LOGIN ADMIN (USA APCONFIG)
// ==========================================
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  void _login() {
    // Legge user e pass direttamente da AppConfig
    if (userController.text == AppConfig.adminUser &&
        passController.text == AppConfig.adminPass) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Credenziali non valide!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACCESSO ADMIN'),
        backgroundColor: const Color(0xFF111111),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 70, color: Colors.white),
            const SizedBox(height: 20),
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: 'Nome Utente',
                filled: true,
                fillColor: Color(0xFF161616),
                labelStyle: TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: Color(0xFF161616),
                labelStyle: TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: _login,
                child: const Text(
                  'ACCEDI',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PANNELLO DI CONTROLLO ADMIN (USA APCONFIG)
// ==========================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State {
  List prenotazioni = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrenotazioni();
  }

  // Scarica le prenotazioni usando AppConfig.serverUrl
  Future _fetchPrenotazioni() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/prenotazioni'),
      );
      if (response.statusCode == 200) {
        setState(() {
          prenotazioni = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Errore nel recupero prenotazioni: $e');
    }
  }

  // Elimina una prenotazione usando AppConfig.serverUrl
  Future _deletePrenotazione(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('\({AppConfig.serverUrl}/api/prenotazioni/\)id'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenotazione eliminata con successo')),
        );
        _fetchPrenotazioni();
      }
    } catch (e) {
      print('Errore cancellazione: $e');
    }
  }

  // Modifica data e ora usando AppConfig.serverUrl
  Future _mostraDialogModifica(BuildContext context, Map prenotazione) async {
    final TextEditingController dataController = TextEditingController(
      text: prenotazione['data'],
    );
    final TextEditingController oraController = TextEditingController(
      text: prenotazione['ora'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Modifica Prenotazione',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dataController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nuova Data (es. 29/9/2026)',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: oraController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nuovo Orario (es. 10:00)',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annulla',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                try {
                  final response = await http.put(
                    Uri.parse(
                      '${AppConfig.serverUrl}/api/prenotazioni/${prenotazione['_id']}',
                    ),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'data': dataController.text,
                      'ora': oraController.text,
                      'servizio': prenotazione['servizio'],
                      'prezzo': prenotazione['prezzo'],
                      'nome': prenotazione['nome'],
                      'telefono': prenotazione['telefono'],
                    }),
                  );

                  if (response.statusCode == 200) {
                    Navigator.pop(context);
                    _fetchPrenotazioni();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prenotazione spostata con successo!'),
                      ),
                    );
                  } else {
                    final resData = jsonDecode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          resData['message'] ?? 'Orario già occupato o errore',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Errore di connessione al server.'),
                    ),
                  );
                }
              },
              child: const Text(
                'Salva',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GESTIONE PRENOTAZIONI'),
        backgroundColor: const Color(0xFF111111),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchPrenotazioni();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : prenotazioni.isEmpty
          ? const Center(
              child: Text(
                'Nessuna prenotazione trovata.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: prenotazioni.length,
              itemBuilder: (context, index) {
                final p = prenotazioni[index];
                return Card(
                  color: const Color(0xFF161616),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      "${p['nome']} - ${p['servizio']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Tel: ${p['telefono']}\nData: ${p['data']} alle ${p['ora']}\nPrezzo: ${p['prezzo']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.amberAccent,
                          ),
                          onPressed: () => _mostraDialogModifica(context, p),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text(
                                  'Elimina',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Vuoi davvero cancellare questa prenotazione?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text(
                                      'Annulla',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deletePrenotazione(p['_id']);
                                    },
                                    child: const Text(
                                      'Elimina',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}