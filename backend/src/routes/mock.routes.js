// mock.routes.js - Simulasi Mock API Dukcapil & Korlantas
const express = require('express');
const r       = express.Router();
const { verifyNik, verifySim } = require('../utils/verify');

r.post('/dukcapil/verify', async (req, res) => {
  await new Promise(x => setTimeout(x, parseInt(process.env.MOCK_API_DELAY_MS) || 800));
  const result = await verifyNik(req.body.nik);
  res.json(result);
});

r.post('/korlantas/verify', async (req, res) => {
  await new Promise(x => setTimeout(x, 600));
  const result = await verifySim(req.body.nomor_sim);
  res.json(result);
});

r.post('/payment/pre-auth', async (req, res) => {
  await new Promise(x => setTimeout(x, 500));
  res.json({ success: true, pre_auth_code: `PA-${Date.now()}`, status: 'PRE_AUTHORIZED' });
});

module.exports = r;
