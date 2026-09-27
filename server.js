const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Stringa di connessione ufficiale a MongoDB Atlas
const MONGO_URI ='mongodb+srv://gentlemanbarbermessina_db_user:eyuEjSxP3WEfKyk9@gentlemanbarber.80prjoz.mongodb.net/gentleman_barber?appName=gentlemanbarber';

// Connessione a MongoDB Atlas
mongoose.connect(MONGO_URI)
.then(() => console.log('Connesso a MongoDB Atlas con successo! 💈'))
.catch(err => console.error('Errore di connessione a MongoDB:', err));

// Schema e Modello della Prenotazione
const prenotazioneSchema = new mongoose.Schema({
    servizio: { type: String, required: true },
    prezzo: { type: String, required: true },
    data: { type: String, required: true },
    ora: { type: String, required: true },
    nome: { type: String, required: true },
    telefono: { type: String, required: true }
});

// Indice unico per bloccare i doppioni sullo stesso orario e data
prenotazioneSchema.index({ data: 1, ora: 1 }, { unique: true });

const Prenotazione = mongoose.model('Prenotazione', prenotazioneSchema, 'prenotazioni');

// Rotta per creare una nuova prenotazione
app.post('/api/prenotazioni', async (req, res) => {
    console.log("Richiesta ricevuta dal client:", req.body);
    try {
        const nuovaPrenotazione = new Prenotazione(req.body);
        await nuovaPrenotazione.save();
        console.log("Salvato con successo su MongoDB!");
        res.status(201).json({ success: true, message: 'Prenotazione effettuata con successo!' });
    } catch (error) {
        console.error("ERRORE DURANTE IL SALVATAGGIO:", error);
        if (error.code === 11000) {
            return res.status(400).json({ 
                success: false, 
                message: 'Questo orario in questa data è già stato prenotato. Scegli un altro slot.' 
            });
        }
        res.status(500).json({ success: false, message: 'Errore del server: ' + error.message });
    }
});

// Rotta per ottenere le ore già prenotate in una determinata data
app.get('/api/prenotazioni/occupate', async (req, res) => {
    try {
        const { data } = req.query;
        const prenotazioni = await Prenotazione.find({ data }, 'ora');
        const orariOccupati = prenotazioni.map(p => p.ora);
        res.status(200).json({ success: true, orariOccupati });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Errore nel recupero degli orari.' });
    }
});
const path = require('path');

// Serve i file statici generati da Flutter nella cartella build/web
app.use(express.static(path.join(__dirname, 'build', 'web')));

// Rotta esplicita per la homepage di Flutter
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'build', 'web', 'index.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server in ascolto sulla porta ${PORT}`);
});