const express = require('express');
const axios = require('axios');
const fs = require('fs');
const https = require('https');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const visaAgent = new https.Agent({
  cert: fs.readFileSync(process.env.VISA_CERT_PATH),
  key: fs.readFileSync(process.env.VISA_KEY_PATH),
  passphrase: process.env.VISA_PASSPHRASE,
});

app.post('/transfer/mobile-to-visa', async (req, res) => {
  const { amount, mobileMoneyProvider, mobileNumber, visaCardNumber } = req.body;
  try {
    const transferData = {};
    const response = await axios.post(
      'https://sandbox.api.visa.com/visadirect/fundstransfer/v1/pushfundstransactions',
      transferData,
      {
        headers: {
          'Authorization': `Bearer ${process.env.VISA_API_KEY}`,
          'Content-Type': 'application/json',
        },
        httpsAgent: visaAgent,
      }
    );
    res.json(response.data);
  } catch (error) {
    console.error(error.response.data);
    res.status(500).json({ error: 'Transfer failed' });
  }
});

app.post('/transfer/visa-to-mobile', async (req, res) => {
  const { amount, visaCardNumber, mobileMoneyProvider, mobileNumber } = req.body;
  try {
    const transferData = {};
    const mobileMoneyApiUrl =
      mobileMoneyProvider === 'ecocash'
        ? process.env.ECOCASH_API_URL
        : process.env.LUMICASH_API_URL;
    const response = await axios.post(
      `${mobileMoneyApiUrl}/fundstransfer`,
      transferData,
      {
        headers: {
          'Authorization': `Bearer ${process.env.MOBILE_MONEY_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );
    res.json(response.data);
  } catch (error) {
    console.error(error.response.data);
    res.status(500).json({ error: 'Transfer failed' });
  }
});

app.get('/balance/visa', async (req, res) => {
  const { visaCardNumber } = req.query;
  try {
    const response = await axios.get(
      `https://sandbox.api.visa.com/visadirect/fundstransfer/v1/pullfundstransactions/${visaCardNumber}/balance`,
      {
        headers: {
          'Authorization': `Bearer ${process.env.VISA_API_KEY}`,
          'Content-Type': 'application/json',
        },
        httpsAgent: visaAgent,
      }
    );
    res.json(response.data);
  } catch (error) {
    console.error(error.response.data);
    res.status(500).json({ error: 'Balance inquiry failed' });
  }
});

app.get('/balance/mobile', async (req, res) => {
  const { mobileMoneyProvider, mobileNumber } = req.query;
  try {
    const mobileMoneyApiUrl =
      mobileMoneyProvider === 'ecocash'
        ? process.env.ECOCASH_API_URL
        : process.env.LUMICASH_API_URL;
    const response = await axios.get(
      `${mobileMoneyApiUrl}/account/${mobileNumber}/balance`,
      {
        headers: {
          'Authorization': `Bearer ${process.env.MOBILE_MONEY_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );
    res.json(response.data);
  } catch (error) {
    console.error(error.response.data);
    res.status(500).json({ error: 'Balance inquiry failed' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
