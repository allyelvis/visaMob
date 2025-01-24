#!/bin/bash

# Set project name
APP_NAME="visaMob"

# Step 1: Create project directory and initialize Node.js project
echo "Setting up $APP_NAME..."
mkdir $APP_NAME && cd $APP_NAME
npm init -y

# Step 2: Install required dependencies
echo "Installing dependencies..."
npm install express dotenv axios cors body-parser

# Step 3: Create project structure
echo "Creating project structure..."
mkdir routes controllers config

# Create server file
cat > server.js <<EOL
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Routes
const transferRoutes = require('./routes/transfer');
const balanceRoutes = require('./routes/balance');
app.use('/transfer', transferRoutes);
app.use('/balance', balanceRoutes);

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(\`Server running on port \${PORT}\`);
});
EOL

# Create transfer route
cat > routes/transfer.js <<EOL
const express = require('express');
const router = express.Router();
const { mobileToVisa, visaToMobile } = require('../controllers/transferController');

// Routes for transfer
router.post('/mobile-to-visa', mobileToVisa);
router.post('/visa-to-mobile', visaToMobile);

module.exports = router;
EOL

# Create balance route
cat > routes/balance.js <<EOL
const express = require('express');
const router = express.Router();
const { getVisaBalance, getMobileBalance } = require('../controllers/balanceController');

// Routes for balance inquiries
router.get('/visa', getVisaBalance);
router.get('/mobile', getMobileBalance);

module.exports = router;
EOL

# Create transfer controller
cat > controllers/transferController.js <<EOL
const axios = require('axios');

// Mobile to Visa transfer
exports.mobileToVisa = async (req, res) => {
  try {
    const { amount, mobileNumber, visaCard } = req.body;
    const response = await axios.post(process.env.VISA_API_URL, {
      amount,
      mobileNumber,
      visaCard,
    }, {
      headers: {
        'Authorization': \`Bearer \${process.env.VISA_API_KEY}\`,
        'Content-Type': 'application/json'
      }
    });

    res.status(200).json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Visa to Mobile transfer
exports.visaToMobile = async (req, res) => {
  try {
    const { amount, visaCard, mobileNumber } = req.body;
    const response = await axios.post(process.env.VISA_API_URL, {
      amount,
      visaCard,
      mobileNumber,
    }, {
      headers: {
        'Authorization': \`Bearer \${process.env.VISA_API_KEY}\`,
        'Content-Type': 'application/json'
      }
    });

    res.status(200).json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
EOL

# Create balance controller
cat > controllers/balanceController.js <<EOL
const axios = require('axios');

// Visa balance inquiry
exports.getVisaBalance = async (req, res) => {
  try {
    const response = await axios.get(process.env.VISA_BALANCE_API_URL, {
      headers: {
        'Authorization': \`Bearer \${process.env.VISA_API_KEY}\`,
        'Content-Type': 'application/json'
      }
    });

    res.status(200).json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Mobile Money balance inquiry
exports.getMobileBalance = async (req, res) => {
  try {
    const { mobileNumber } = req.query;
    const response = await axios.get(\`\${process.env.MOBILE_API_URL}/balance?mobileNumber=\${mobileNumber}\`, {
      headers: {
        'Authorization': \`Bearer \${process.env.MOBILE_API_KEY}\`,
        'Content-Type': 'application/json'
      }
    });

    res.status(200).json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
EOL

# Step 4: Set up environment variables
echo "Setting up environment variables..."
cat > .env <<EOL
PORT=3000
VISA_API_URL=https://sandbox.api.visa.com/vdp/v1/transfer
VISA_API_KEY=<your-visa-api-key>
VISA_BALANCE_API_URL=https://sandbox.api.visa.com/vdp/v1/balance
MOBILE_API_URL=https://sandbox.mobile-money-api.com
MOBILE_API_KEY=<your-mobile-api-key>
EOL

# Step 5: Start the application
echo "Starting the server..."
npm start

echo "Setup complete! The server is running."