// config.js
module.exports = {
    mtn: {
      subscriptionKey: process.env.MTN_SUBSCRIPTION_KEY,
      userId: process.env.MTN_USER_ID,
      apiSecret: process.env.MTN_API_SECRET
    },
    airtel: {
      clientId: process.env.AIRTEL_CLIENT_ID,
      clientSecret: process.env.AIRTEL_CLIENT_SECRET
    },
    baseUrl: process.env.BASE_URL || 'http://localhost:2005'
  };