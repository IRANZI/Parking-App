// services/paymentService.js
const axios = require('axios');
const config = require('../config');

// MTN Mobile Money Integration
const processMTNPayment = async (phone, amount, reference) => {
  try {
    // Get authentication token
    const authResponse = await axios.post(
      'https://sandbox.momodeveloper.mtn.com/collection/token/',
      null,
      {
        headers: {
          'Ocp-Apim-Subscription-Key': config.mtn.subscriptionKey,
          'Authorization': `Basic ${Buffer.from(`${config.mtn.userId}:${config.mtn.apiSecret}`).toString('base64')}`
        }
      }
    );
    
    const accessToken = authResponse.data.access_token;

    // Initiate payment
    const response = await axios.post(
      'https://sandbox.momodeveloper.mtn.com/collection/v1_0/requesttopay',
      {
        amount: amount,
        currency: 'RWF',
        externalId: reference,
        payer: {
          partyIdType: 'MSISDN',
          partyId: phone.startsWith('250') ? phone : `250${phone.substring(1)}`
        },
        payerMessage: 'Parking Payment',
        payeeNote: `Booking ${reference}`
      },
      {
        headers: {
          'X-Reference-Id': reference,
          'X-Target-Environment': 'sandbox',
          'Ocp-Apim-Subscription-Key': config.mtn.subscriptionKey,
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    // Check payment status
    const statusResponse = await axios.get(
      `https://sandbox.momodeveloper.mtn.com/collection/v1_0/requesttopay/${reference}`,
      {
        headers: {
          'X-Target-Environment': 'sandbox',
          'Ocp-Apim-Subscription-Key': config.mtn.subscriptionKey,
          'Authorization': `Bearer ${accessToken}`
        }
      }
    );

    return {
      success: statusResponse.data.status === 'SUCCESSFUL',
      transactionId: reference,
      message: statusResponse.data.status
    };
  } catch (error) {
    console.error('MTN Payment Error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data?.message || 'MTN payment failed'
    };
  }
};

// Airtel Money Integration
const processAirtelPayment = async (phone, amount, reference) => {
  try {
    // Get authentication token
    const authResponse = await axios.post(
      'https://openapi.airtel.africa/auth/oauth2/token',
      new URLSearchParams({ grant_type: 'client_credentials' }),
      {
        headers: {
          'Authorization': `Basic ${Buffer.from(`${config.airtel.clientId}:${config.airtel.clientSecret}`).toString('base64')}`
        }
      }
    );
    
    const accessToken = authResponse.data.access_token;

    // Initiate payment
    const response = await axios.post(
      'https://openapi.airtel.africa/merchant/v1/payments/',
      {
        reference: reference,
        subscriber: {
          country: 'RW',
          currency: 'RWF',
          msisdn: phone.startsWith('+250') ? phone : `+250${phone.substring(1)}`
        },
        transaction: {
          amount: amount,
          country: 'RW',
          currency: 'RWF',
          id: reference
        }
      },
      {
        headers: {
          'X-Country': 'RW',
          'X-Currency': 'RWF',
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return {
      success: response.data.data.status === 'TS',
      transactionId: reference,
      message: response.data.data.status
    };
  } catch (error) {
    console.error('Airtel Payment Error:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data?.message || 'Airtel payment failed'
    };
  }
};

module.exports = {
  processMTNPayment,
  processAirtelPayment
};