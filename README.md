# Credit Card Recommendation System

An AI-powered customer service platform that provides intelligent credit card recommendations, order management, defect reporting, and fraud detection capabilities.

## Features

- **Intelligent Card Recommendations**: AI-powered system using GPT-4o-mini that understands natural language queries
- **Multi-Intent Detection**: Automatically detects user intent and routes to appropriate handler
- **Order Management**: Create and cancel orders with AI validation
- **Defect Reporting**: Vision AI analyzes product images and makes automated decisions
- **Fraud Detection**: OCR-based transaction analysis with AI fraud detection

## Technology Stack

### Frontend
- React 18.3.1
- Axios for HTTP requests
- Modern responsive UI

### Backend
- Flask 3.1.2 (Python 3.13)
- LangChain 1.2.7 for AI orchestration
- OpenAI API (GPT-4, GPT-4o-mini)
- MongoDB for data storage

### AI/ML
- GPT-4 for intent detection and critical decisions
- GPT-4o-mini for card recommendations (cost-optimized)
- GPT-4 Vision for defect image analysis
- Pytesseract for OCR

## Quick Start

### Prerequisites
- Node.js v24.2.0+
- Python 3.13+
- MongoDB 7.0+
- OpenAI API key

### Backend Setup
```bash
cd credit-card-backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### Frontend Setup
```bash
cd credit-card-frontend
npm install
npm start
```

### Access
- Frontend: http://localhost:3000
- Backend API: http://localhost:5001

## Project Structure

```
├── credit-card-backend/     # Flask backend with AI agents
│   ├── main.py             # Main Flask application
│   ├── config.py           # MongoDB query generation
│   ├── order_agent.py      # Order management
│   ├── defect_agent.py     # Defect reporting with Vision AI
│   └── fraud_agent.py      # Fraud detection with OCR
├── credit-card-frontend/    # React frontend
│   └── src/
│       └── App.js          # Main React component
└── Images/                  # UI screenshots
```

## Key Capabilities

### Natural Language Queries
- "I want a cashback credit card"
- "Show me travel cards with no annual fee"
- "What Chase cards do you have?"

### Multi-Intent Support
- Card recommendations
- Order tracking and cancellation
- Defect reporting with image upload
- Fraud transaction reporting

## Database

MongoDB with the following collections:
- `creditCardDB.cards` - Credit card products (6 cards across 3 categories)
- `credit_card_db.orders` - Customer orders
- `customer_support.defective_products` - Defect reports
- `customer_support.fraud_reports` - Fraud reports

## API Endpoints

- `POST /api/recommend` - Get card recommendations or detect intent
- `POST /api/create_order` - Create new order
- `POST /api/cancel_order` - Cancel existing order
- `POST /api/report_defect` - Report product defect with image
- `POST /api/report_fraud` - Report fraudulent transaction
- `GET /api/track_defect/:id` - Track defect status
- `GET /api/track_fraud/:id` - Track fraud status

## Performance

- Response time: < 3 seconds for most queries
- Database queries: Sub-second
- 99.9% uptime target
- Supports 100+ concurrent users

## Cost Optimization

The system uses smart model selection to optimize costs:
- GPT-4o-mini for recommendations (98.4% cost savings vs GPT-4)
- GPT-4 only for critical operations
- Average cost per user session: $0.006 - $0.012

## License

MIT License

## Author

Vinod Reddy
