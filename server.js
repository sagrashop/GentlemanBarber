const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const nodemailer = require('nodemailer');

const app = express();
app.use(express.json());
app.use(cors());

// Stringa di connessione ufficiale a MongoDB Atlas
const MONGO_URI = process.env.MONGO_URI;

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
        const { servizio, prezzo, data, ora, nome, telefono } = req.body;

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
// 1. Rotta per LEGGERE tutte le prenotazioni (per il pannello Admin)
app.get('/api/prenotazioni', async (req, res) => {
    try {
        // Ordina le prenotazioni dalla più recente alla meno recente
        const listaPrenotazioni = await Prenotazione.find().sort({ _id: -1 });
        res.status(200).json(listaPrenotazioni);
    } catch (error) {
        console.error("Errore nel recupero delle prenotazioni:", error);
        res.status(500).json({ success: false, message: 'Errore del server' });
    }
});

// 2. Rotta per ELIMINARE una prenotazione tramite il suo ID (_id di MongoDB)
app.delete('/api/prenotazioni/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const eliminata = await Prenotazione.findByIdAndDelete(id);
        if (!eliminata) {
            return res.status(404).json({ success: false, message: 'Prenotazione non trovata' });
        }
        console.log(`Prenotazione ${id} eliminata con successo.`);
        res.status(200).json({ success: true, message: 'Prenotazione eliminata con successo' });
    } catch (error) {
        console.error("Errore durante l'eliminazione:", error);
        res.status(500).json({ success: false, message: 'Errore del server' });
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
// MODIFICA PRENOTAZIONE (Sposta data/ora o cambia dettagli)
app.put('/api/prenotazioni/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { data, ora, servizio, prezzo, nome, telefono } = req.body;

        // 1. Controlla se il nuovo orario è già occupato (escludendo la prenotazione corrente che stiamo modificando)
        const slotOccupato = await Prenotazione.findOne({
            _id: { $ne: id }, // Esclude la prenotazione attuale
            data: data,
            ora: ora
        });

        if (slotOccupato) {
            return res.status(400).json({ 
                success: false, 
                message: 'Attenzione: Questo orario è già occupato da un\'altra prenotazione!' 
            });
        }

        // 2. Esegue l'aggiornamento
        const prenotazioneAggiornata = await Prenotazione.findByIdAndUpdate(
            id,
            { data, ora, servizio, prezzo, nome, telefono },
            { new: true }
        );

        if (!prenotazioneAggiornata) {
            return res.status(404).json({ success: false, message: 'Prenotazione non trovata.' });
        }

        console.log("Prenotazione modificata con successo:", id);
        res.status(200).json({ success: true, message: 'Prenotazione aggiornata con successo!', prenotazione: prenotazioneAggiornata });

    } catch (error) {
        console.error("Errore durante la modifica:", error);
        res.status(500).json({ success: false, message: 'Errore del server durante la modifica.' });
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