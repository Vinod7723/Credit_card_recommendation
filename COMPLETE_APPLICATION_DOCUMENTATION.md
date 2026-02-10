# Credit Card Recommendation System - Complete Application Documentation

## Table of Contents
1. [System Architecture Overview](#1-system-architecture-overview)
2. [Frontend Code Explanation](#2-frontend-code-explanation)
3. [Backend Code Explanation](#3-backend-code-explanation)
4. [Database Schema](#4-database-schema)
5. [AI/ML Integration](#5-aiml-integration)
6. [AWS Infrastructure](#6-aws-infrastructure)
7. [End-to-End Request Flow](#7-end-to-end-request-flow)
8. [Key Features](#8-key-features)

---

## 1. SYSTEM ARCHITECTURE OVERVIEW

### High-Level Architecture

The Credit Card Recommendation System is a modern, cloud-native application deployed on AWS EKS (Elastic Kubernetes Service) with the following architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (us-east-1)                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              EKS Cluster (vinod-credit-card-production)    │ │
│  │                                                             │ │
│  │  ┌──────────────┐        ┌──────────────┐                 │ │
│  │  │   Frontend   │        │   Backend    │                 │ │
│  │  │  (React +    │◄──────►│  (Flask +    │                 │ │
│  │  │   Nginx)     │        │  Gunicorn)   │                 │ │
│  │  │  Port: 80    │        │  Port: 5001  │                 │ │
│  │  │  Replicas: 3 │        │  Replicas: 3 │                 │ │
│  │  └──────┬───────┘        └──────┬───────┘                 │ │
│  │         │                       │                          │ │
│  │         │                       │                          │ │
│  │         │                       ▼                          │ │
│  │         │              ┌──────────────┐                    │ │
│  │         │              │   MongoDB    │                    │ │
│  │         │              │  Database    │                    │ │
│  │         │              │  Port: 27017 │                    │ │
│  │         │              │  Replicas: 1 │                    │ │
│  │         │              │  Volume: 20Gi│                    │ │
│  │         │              └──────────────┘                    │ │
│  │         │                                                   │ │
│  │         ▼                                                   │ │
│  │  ┌────────────────────────────────────┐                   │ │
│  │  │  AWS ALB (Application Load Balancer) │                 │ │
│  │  │  Routes: /api/* → Backend           │                  │ │
│  │  │          /* → Frontend               │                  │ │
│  │  └────────────────────────────────────┘                   │ │
│  │                                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────┐     ┌─────────────┐    ┌──────────────┐   │
│  │  ECR Registry  │     │  CloudWatch │    │   Secrets    │   │
│  │  (Container    │     │  (Logging & │    │  Manager     │   │
│  │   Images)      │     │  Monitoring)│    │  (API Keys)  │   │
│  └────────────────┘     └─────────────┘    └──────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ External Access
                              ▼
                    ┌──────────────────┐
                    │  OpenAI GPT-4    │
                    │  API Services    │
                    └──────────────────┘
```

### Technology Stack

#### Frontend
- **Framework**: React 18.x
- **HTTP Client**: Axios
- **Styling**: CSS3 with modular CSS files
- **Build Tool**: Create React App
- **Container**: Nginx 1.25-alpine
- **Port**: 80

#### Backend
- **Framework**: Flask 3.x (Python)
- **Web Server**: Gunicorn (4 workers)
- **AI/ML Libraries**:
  - OpenAI Python SDK (GPT-4 & GPT-4o-mini)
  - LangChain (for MongoDB query generation)
  - Pillow (image processing)
  - PyTesseract (OCR for fraud detection)
- **Database Driver**: PyMongo
- **CORS**: Flask-CORS
- **Port**: 5001

#### Database
- **Type**: MongoDB 6.0
- **Collections**:
  - `creditcards` - Credit card catalog
  - `orders` - Customer orders
  - `defective_products` - Defect reports
  - `fraud_reports` - Fraud transaction reports

#### Cloud Infrastructure
- **Provider**: AWS
- **Orchestration**: Kubernetes (EKS)
- **Container Registry**: AWS ECR
- **Load Balancer**: AWS ALB (Application Load Balancer)
- **CI/CD**: GitHub Actions
- **Region**: us-east-1

### Component Interactions

1. **User → Frontend**: User interacts with React UI
2. **Frontend → Backend**: Axios sends HTTP requests to Flask API
3. **Backend → OpenAI**: Uses GPT-4 for intent detection and natural language processing
4. **Backend → LangChain**: Converts natural language to MongoDB queries
5. **Backend → MongoDB**: Queries/stores data in MongoDB collections
6. **Backend → Frontend**: Returns JSON responses with card recommendations or status updates
7. **Frontend → User**: Displays cards, forms, and chat messages

---

## 2. FRONTEND CODE EXPLANATION

### 2.1 App.js - Main Application Component

**File**: `/credit-card-frontend/src/App.js`

This is the central component managing the entire application state and user interactions.

#### Import Section (Lines 1-11)
```javascript
import React, { useState } from "react";
import axios from "axios";
import ChatMessage from "./ChatMessage";
import Defect from "./Defect";
import Track from "./Track";
import TrackOrder from "./TrackOrder";
import FraudTransaction from "./FraudTransaction";
import TrackFraud from "./TrackFraud";
import API_BASE_URL from "./config";
import "./App.css";
```

**Explanation**:
- `useState`: React hook for managing component state
- `axios`: HTTP client for API calls
- Various components imported for different features
- `API_BASE_URL`: Centralized configuration for backend URL

#### State Management (Lines 14-26)
```javascript
const [userInput, setUserInput] = useState("");           // User's typed message
const [messages, setMessages] = useState([]);             // Chat history
const [loading, setLoading] = useState(false);            // Loading state
const [userId] = useState(() => Math.random().toString(36).substr(2, 9)); // Unique session ID
const [showOrderForm, setShowOrderForm] = useState(false);         // Order form visibility
const [showCancelForm, setShowCancelForm] = useState(false);       // Cancel form visibility
const [showDefectForm, setShowDefectForm] = useState(false);       // Defect report visibility
const [showTrackDefectForm, setShowTrackDefectForm] = useState(false);   // Track defect visibility
const [showTrackOrderForm, setShowTrackOrderForm] = useState(false);     // Track order visibility
const [showFraudForm, setShowFraudForm] = useState(false);         // Fraud report visibility
const [showTrackFraudForm, setShowTrackFraudForm] = useState(false);     // Track fraud visibility
const [orderDetails, setOrderDetails] = useState({ name: "", address: "", mobile: "", card_name: "" });
const [orderNumber, setOrderNumber] = useState("");
```

**Purpose**:
- `userInput`: Stores the current text in the input field
- `messages`: Array of chat messages (user and bot)
- `userId`: Random session identifier generated once using Math.random()
- Multiple boolean states control modal visibility for different features
- `orderDetails`: Object storing form data for card orders

#### Main Message Handler (Lines 30-81)
```javascript
const handleSendMessage = async () => {
  if (userInput.trim() === "") return;  // Prevent empty messages

  // Add user message to chat
  const userMessage = { type: "user", text: userInput };
  setMessages((prevMessages) => [...prevMessages, userMessage]);

  setLoading(true);  // Show loading indicator

  try {
    // Send message to backend /api/recommend endpoint
    const response = await axios.post(`${API_BASE_URL}/api/recommend`, {
      message: userInput,
      user_id: userId,
    });

    // Intent-based routing
    if (response.data.message === "track_intent") {
      setShowTrackOrderForm(true);
      const botMessage = { type: "bot", text: "Please enter your order number..." };
      setMessages((prevMessages) => [...prevMessages, botMessage]);
    }
    else if (response.data.message === "cancel_intent") {
      setShowCancelForm(true);
      // ... similar pattern for other intents
    }
    // ... more intent checks
    else {
      handleBackendResponse(response);  // Default: show card recommendations
    }
  } catch (error) {
    // Error handling with user-friendly messages
    const errorText = error.response?.data?.message || "There was an error...";
    const errorMessage = { type: "bot", text: errorText };
    setMessages((prevMessages) => [...prevMessages, errorMessage]);
  } finally {
    setUserInput("");    // Clear input field
    setLoading(false);   // Hide loading indicator
  }
};
```

**Flow**:
1. Validates input is not empty
2. Adds user message to chat history
3. Makes POST request to `/api/recommend` with message and user ID
4. Backend returns intent classification (e.g., "track_intent", "cancel_intent")
5. Based on intent, either shows appropriate modal OR displays card recommendations
6. Error handling catches network/server errors and displays user-friendly messages

#### Response Handler (Lines 83-91)
```javascript
const handleBackendResponse = (response) => {
  if (Array.isArray(response.data)) {
    // Card recommendations (array of card objects)
    const botMessage = { type: "bot", cards: response.data };
    setMessages((prevMessages) => [...prevMessages, botMessage]);
  } else if (response.data.message) {
    // Text message response
    const botMessage = { type: "bot", text: response.data.message };
    setMessages((prevMessages) => [...prevMessages, botMessage]);
  }
};
```

**Purpose**: Determines if response is card array or text message and adds to chat

#### Order Management (Lines 93-146)
```javascript
const handleBuy = (card) => {
  setShowOrderForm(true);
  setOrderDetails((prevDetails) => ({ ...prevDetails, card_name: card.name }));
};

const handleOrderSubmit = async (e) => {
  e.preventDefault();
  setLoading(true);
  try {
    const response = await axios.post(`${API_BASE_URL}/api/create_order`, {
      ...orderDetails,
      user_id: userId,
    });
    handleBackendResponse(response);
    setShowOrderForm(false);
    setOrderDetails({ name: "", address: "", mobile: "", card_name: "" });
  } catch (error) {
    // Error handling
  } finally {
    setLoading(false);
  }
};

const handleCancelOrderSubmit = async (e) => {
  e.preventDefault();
  setLoading(true);
  try {
    const response = await axios.post(`${API_BASE_URL}/api/cancel_order`, {
      order_number: orderNumber,
    });
    handleBackendResponse(response);
    setShowCancelForm(false);
    setOrderNumber("");
  } catch (error) {
    // Error handling
  }
};
```

**Key Points**:
- `handleBuy`: Triggered when user clicks "Apply Now" on a card
- Pre-fills card name in order form
- `handleOrderSubmit`: Sends order details to `/api/create_order`
- `handleCancelOrderSubmit`: Cancels order by order number

#### Response Callbacks (Lines 148-182)
```javascript
const handleTrackOrderResponse = (data) => {
  const botMessage = {
    type: "bot",
    text: data.message
  };
  setMessages((prevMessages) => [...prevMessages, botMessage]);
};

const handleTrackDefectResponse = (data) => {
  const botMessage = {
    type: "bot",
    text: `Defect Tracking Info: Description: ${data.description}, Order ID: ${data.orderId}...`
  };
  setMessages((prevMessages) => [...prevMessages, botMessage]);
};

const handleFraudTransactionResponse = (data) => {
  const botMessage = {
    type: "bot",
    text: `Fraud Report Tracking ID: ${data.trackingId}`
  };
  setMessages((prevMessages) => [...prevMessages, botMessage]);
};
```

**Purpose**: Callback functions passed to child components to display responses in chat

#### UI Render (Lines 184-285)
```javascript
return (
  <div className="app">
    <h1>Credit Card Recommendation Chat</h1>

    {/* Chat container showing all messages */}
    <div className="chat-container">
      {messages.map((msg, index) => (
        <ChatMessage key={index} message={msg} onBuy={handleBuy} />
      ))}
    </div>

    {/* Input field with Send button */}
    <div className="input-container">
      <input
        type="text"
        value={userInput}
        onChange={handleInputChange}
        onKeyDown={(e) => { if (e.key === "Enter") handleSendMessage(); }}
      />
      <button onClick={handleSendMessage} disabled={loading}>
        {loading ? "Loading..." : "Send"}
      </button>
    </div>

    {/* Conditional Modal Rendering */}
    {showOrderForm && (
      <div className="order-form-modal">
        <form onSubmit={handleOrderSubmit}>
          <input type="text" name="name" placeholder="Full Name" required />
          <input type="text" name="address" placeholder="Address" required />
          <input type="text" name="mobile" placeholder="Mobile Number" required />
          <input type="text" name="card_name" value={orderDetails.card_name} readOnly />
          <button type="submit">Submit Order</button>
        </form>
      </div>
    )}

    {/* Similar modals for cancel, defect, track order, fraud, etc. */}
  </div>
);
```

**Structure**:
1. Chat header
2. Message display area (scrollable)
3. Input field with Enter key support
4. Conditional modal rendering based on state flags

---

### 2.2 ChatMessage.js - Message Rendering Component

**File**: `/credit-card-frontend/src/ChatMessage.js`

```javascript
function ChatMessage({ message, onBuy, onCancel }) {
  return (
    <div className={`chat-message ${message.type === "user" ? "user-message" : "bot-message"}`}>
      {message.text && <p>{message.text}</p>}
      {message.cards && <CardList cards={message.cards} onBuy={onBuy} onCancel={onCancel} />}
    </div>
  );
}
```

**Line-by-Line**:
- **Line 2**: Conditional CSS class based on message type (user vs bot)
- **Line 3**: If message has text property, display it in paragraph
- **Line 4**: If message has cards property, render CardList component
- **Purpose**: Provides flexible rendering for both text messages and card recommendations

---

### 2.3 CardList.js - Card Display with Credit Score Categories

**File**: `/credit-card-frontend/src/CardList.js`

#### Credit Score Helper Function (Lines 5-13)
```javascript
function getCreditScoreCategory(score) {
  if (!score) return "Not specified";
  if (score >= 800) return "Excellent (800+)";
  if (score >= 740) return "Very Good (740-799)";
  if (score >= 670) return "Good (670-739)";
  if (score >= 580) return "Fair (580-669)";
  return "Poor (300-579)";
}
```

**Purpose**: Converts numeric credit score to human-readable category
- **Excellent**: 800-850
- **Very Good**: 740-799
- **Good**: 670-739
- **Fair**: 580-669
- **Poor**: 300-579

#### Card Rendering (Lines 15-73)
```javascript
function CardList({ cards, onBuy, onCancel }) {
  return (
    <div className="card-list">
      {cards.map((card, index) => (
        <div key={index} className="card-item">

          {/* Tier Banner (Bronze/Silver/Gold/Diamond) */}
          <div className={`card-tier-banner tier-${card.tier}`}>
            {card.tier?.toUpperCase()}
          </div>

          <div className="card-details">
            <h3>{card.name}</h3>
            <p className="card-issuer">{card.issuer}</p>
            <p className="card-description">{card.description}</p>

            {/* Information Grid */}
            <div className="card-info-grid">
              <div className="card-info-item">
                <span className="info-label">Annual Fee</span>
                <span className="info-value">${card.annual_fee}</span>
              </div>
              <div className="card-info-item">
                <span className="info-label">APR</span>
                <span className="info-value">{card.interest_rate}%</span>
              </div>
              <div className="card-info-item">
                <span className="info-label">Credit Limit</span>
                <span className="info-value">
                  ${card.credit_limit_min?.toLocaleString()} -
                  ${card.credit_limit_max?.toLocaleString()}
                </span>
              </div>
              <div className="card-info-item">
                <span className="info-label">Cashback</span>
                <span className="info-value">{card.rewards?.cashback_percentage}%</span>
              </div>
              <div className="card-info-item credit-score-item">
                <span className="info-label">Min Credit Score</span>
                <span className="info-value credit-score-value">
                  {getCreditScoreCategory(card.min_credit_score)}
                </span>
              </div>
            </div>

            {/* Bonus Categories */}
            {card.rewards?.bonus_categories?.length > 0 && (
              <div className="card-bonus">
                <span className="info-label">Bonus Categories: </span>
                {card.rewards.bonus_categories.map((cat, i) => (
                  <span key={i} className="bonus-badge">
                    {cat.category} {cat.multiplier}x
                  </span>
                ))}
              </div>
            )}

            {/* Benefits List */}
            <div className="card-benefits">
              <span className="info-label">Key Benefits:</span>
              <ul>
                {card.benefits?.slice(0, 4).map((benefit, i) => (
                  <li key={i}>{benefit}</li>
                ))}
              </ul>
            </div>
          </div>

          {/* Action Button */}
          <div className="card-actions">
            <button onClick={() => onBuy(card)}>Apply Now</button>
          </div>
        </div>
      ))}
    </div>
  );
}
```

**Key Features**:
- **Tier Banner**: Color-coded based on card tier
- **toLocaleString()**: Formats numbers with commas (e.g., 10000 → 10,000)
- **Optional Chaining (?)**: Prevents errors if data is missing
- **Conditional Rendering**: Shows bonus categories only if they exist
- **slice(0, 4)**: Limits benefits to first 4 items

---

### 2.4 config.js - API Configuration

**File**: `/credit-card-frontend/src/config.js`

```javascript
const API_BASE_URL = process.env.REACT_APP_API_URL ||
  'http://k8s-creditca-creditca-dffee1a493-37154518.us-east-1.elb.amazonaws.com';

export default API_BASE_URL;
```

**Explanation**:
- Checks for environment variable `REACT_APP_API_URL` first
- Falls back to AWS ALB endpoint if not set
- Centralized configuration for easy updates
- Used throughout the app for all API calls

---

### 2.5 Defect.js - Defect Reporting Component

**File**: `/credit-card-frontend/src/Defect.js`

#### State Management (Lines 7-11)
```javascript
const [defectDescription, setDefectDescription] = useState("");
const [orderId, setOrderId] = useState("");
const [defectImage, setDefectImage] = useState(null);
const [trackingId, setTrackingId] = useState("");
```

#### Form Submission with File Upload (Lines 15-34)
```javascript
const handleSubmitDefect = async (e) => {
  e.preventDefault();

  // FormData for multipart/form-data (required for file uploads)
  const formData = new FormData();
  formData.append("description", defectDescription);
  formData.append("orderId", orderId);
  formData.append("image", defectImage);

  try {
    const response = await axios.post(`${API_BASE_URL}/api/report_defect`, formData);
    setTrackingId(response.data.trackingId);
    onResponse(response.data);  // Send tracking ID to parent
    onClose();  // Close modal
  } catch (error) {
    console.error("Error reporting defect:", error);
    onResponse({ message: "There was an error reporting the defect." });
    onClose();
  }
};
```

**Key Points**:
- Uses `FormData` API for file uploads (multipart/form-data)
- Appends text fields and image file
- Backend processes image with GPT-4 Vision API
- Returns tracking ID for future reference

---

### 2.6 Track.js - Defect Tracking Component

**File**: `/credit-card-frontend/src/Track.js`

```javascript
const handleTrackSubmit = async (e) => {
  e.preventDefault();
  setStatus(null);
  setError(null);

  try {
    const response = await axios.get(`${API_BASE_URL}/api/track_defect/${trackingId}`);
    setStatus(response.data);
    onResponse(response.data);  // Send to parent for chat display
    onClose();
  } catch (error) {
    setError("Tracking ID not found or there was an error...");
  }
};
```

**Flow**:
1. User enters tracking ID from defect report
2. GET request to `/api/track_defect/{trackingId}`
3. Backend retrieves defect status from MongoDB
4. Displays description, order ID, decision (Replacement/Refund/Escalate)

---

### 2.7 TrackOrder.js - Order Tracking Component

**File**: `/credit-card-frontend/src/TrackOrder.js`

```javascript
const handleTrackSubmit = async (e) => {
  e.preventDefault();
  try {
    const response = await axios.get(`${API_BASE_URL}/api/track_order/${orderNumber}`);
    setOrderInfo(response.data);

    // Format order info for chat display
    const orderMessage = `Order ${orderNumber} Details:\n` +
      `Card: ${response.data.card_name}\n` +
      `Name: ${response.data.name}\n` +
      `Address: ${response.data.address}\n` +
      `Mobile: ${response.data.mobile}\n` +
      `Status: ${response.data.status}\n` +
      `Created: ${new Date(response.data.timestamp).toLocaleString()}`;

    onResponse({ message: orderMessage });
    onClose();
  } catch (error) {
    const errorMsg = error.response?.data?.message || "Order not found...";
    setError(errorMsg);
  }
};
```

**Features**:
- GET request with order number in URL path
- Formats multi-line message for chat display
- Converts ISO timestamp to localized date string

---

### 2.8 FraudTransaction.js - Fraud Reporting Component

**File**: `/credit-card-frontend/src/FraudTransaction.js`

```javascript
const handleSubmit = async (e) => {
  e.preventDefault();
  setError(null);

  if (!transactionDetails || !ocrImage) {
    setError("Both transaction details and image are required.");
    return;
  }

  const formData = new FormData();
  formData.append("transaction_details", transactionDetails);
  formData.append("ocr_image", ocrImage);

  try {
    const response = await axios.post(`${API_BASE_URL}/api/report_fraud`, formData);
    onResponse(response.data);  // Contains trackingId
    onClose();
  } catch (error) {
    setError("There was an error reporting the fraudulent transaction.");
  }
};
```

**Purpose**:
- User reports suspected fraud with transaction details and receipt image
- Backend uses PyTesseract OCR to extract text from image
- LangChain LLM analyzes transaction to determine: Refund/Decline/Escalate

---

### 2.9 TrackFraud.js - Fraud Status Tracking

**File**: `/credit-card-frontend/src/TrackFraud.js`

```javascript
const handleSubmit = async (e) => {
  e.preventDefault();
  try {
    const response = await axios.get(`${API_BASE_URL}/api/track_fraud/${trackingId}`);
    onResponse(response.data);  // Display fraud decision
    onClose();
  } catch (error) {
    setError("There was an error tracking the fraud status.");
  }
};
```

**Simple Flow**:
1. User enters fraud report tracking ID
2. Backend retrieves decision from MongoDB
3. Displays: Refund, Decline, or Escalate to Human-Agent

---

## 3. BACKEND CODE EXPLANATION

### 3.1 main.py - Flask Application with API Routes

**File**: `/credit-card-backend/main.py`

#### Application Setup (Lines 1-21)
```python
from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
import traceback
import os
from config import generate_mongo_query
from models.card_model import find_cards_by_query
from order_agent import create_order_with_openai, cancel_order_with_openai, find_order_by_number
from defect_agent import report_defect, track_defect_status
from fraud_agent import report_fraud, track_fraud_status
import json

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})  # Enable CORS for all /api routes

# OpenAI API setup
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
```

**Key Points**:
- **CORS**: Allows frontend (different origin) to make API requests
- **OpenAI Client**: Initialized with API key from environment variable
- **Modular Imports**: Each feature has separate module (order_agent, defect_agent, fraud_agent)

#### Intent Detection Function (Lines 24-62)
```python
def detect_intent(message):
    """Uses OpenAI's GPT-4 chat model to detect the specific intent of the message."""
    try:
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": "You are an assistant that categorizes customer inquiries into one of the following intents: 'greeting', 'track order', 'cancel order', 'report defect', 'track defect', 'report fraud transaction', 'track fraud status', or 'other'. Classify general greetings like hi, hello, hey, good morning, good evening, etc. as 'greeting'. Classify messages about checking or tracking a defect report status as 'track defect'."
                },
                {
                    "role": "user",
                    "content": f"Please categorize this message into 'greeting', 'track order', 'cancel order', 'report defect', 'track defect', 'report fraud transaction', 'track fraud status', or 'other': '{message}'."
                },
            ],
        )

        intent_response = response.choices[0].message.content.strip().lower()
        print("Detected intent response:", intent_response)

        # Map GPT-4 response to intent codes
        if "greeting" in intent_response:
            return "greeting_intent"
        elif "track defect" in intent_response:
            return "track_defect_intent"
        elif "track order" in intent_response:
            return "track_intent"
        elif "cancel order" in intent_response:
            return "cancel_intent"
        elif "report defect" in intent_response:
            return "report_defect_intent"
        elif "report fraud transaction" in intent_response:
            return "report_fraud_intent"
        elif "track fraud status" in intent_response:
            return "track_fraud_intent"
        else:
            return "other"
    except Exception as e:
        print("Error detecting intent:", e)
        return "error"
```

**How It Works**:
1. **System Message**: Defines GPT-4's role and available intents
2. **User Message**: Asks GPT-4 to categorize the user's input
3. **Response Parsing**: Extracts intent from GPT-4's response
4. **Intent Mapping**: Converts natural language response to intent code
5. **Example**: "track my order" → GPT-4 says "track order" → returns "track_intent"

#### Main Recommendation Endpoint (Lines 65-109)
```python
@app.route("/api/recommend", methods=["POST"])
def recommend():
    data = request.get_json()
    message = data.get("message")
    user_id = data.get("user_id", request.remote_addr)

    try:
        intent = detect_intent(message)  # Call GPT-4 to classify intent

        # Handle specific intents
        if intent == "greeting_intent":
            return jsonify({
                "message": "Hello! Welcome to the Credit Card Recommendation System. I can help you with:\n- Recommending credit cards based on your credit score\n- Finding cards for travel, cashback, dining rewards\n- Creating or canceling orders\n- Reporting defects or fraud\n\nTip: Tell me your credit score for personalized recommendations!\nExample: 'Show me travel cards for credit score 720'\n\nHow can I assist you today?"
            }), 200

        elif intent == "track_intent":
            return jsonify({"message": "track_intent"}), 200

        elif intent == "cancel_intent":
            return jsonify({"message": "cancel_intent"}), 200

        # ... more intent handling

        # Default: Card recommendation flow
        mongo_query_str = generate_mongo_query(message)  # LangChain generates MongoDB query
        mongo_query = json.loads(mongo_query_str)
        recommended_cards = find_cards_by_query(mongo_query)  # Execute query on MongoDB

        if recommended_cards:
            return jsonify(recommended_cards), 200
        else:
            return jsonify({"message": "No matching cards found."}), 404

    except Exception as e:
        print("Error processing recommendation:", e)
        traceback.print_exc()
        return jsonify({"message": "Error processing the recommendation request"}), 500
```

**Flow Diagram**:
```
User Message → detect_intent() → Intent Classification
                                        ↓
                    ┌───────────────────┴────────────────────┐
                    │                                        │
              Specific Intent                        Default/Other
        (track, cancel, defect, fraud)           (Card Recommendation)
                    │                                        │
            Return Intent Code                   generate_mongo_query()
            (Frontend shows modal)                          ↓
                                                 find_cards_by_query()
                                                           ↓
                                                  Return Card Array
```

#### Order Creation Endpoint (Lines 112-138)
```python
@app.route("/api/create_order", methods=["POST"])
def create_order_route():
    data = request.get_json()
    user_id = data.get("user_id", request.remote_addr)

    details = {
        "name": data.get("name"),
        "address": data.get("address"),
        "mobile": data.get("mobile"),
        "card_name": data.get("card_name"),
        "user_id": user_id,
    }

    try:
        order_number = create_order_with_openai(details)  # Uses LangChain
        if order_number:
            return jsonify({
                "message": f"Order created successfully with order number {order_number}."
            })
        else:
            return jsonify({"message": "Failed to create order."}), 500
    except Exception as e:
        print("Error in create_order_route:", e)
        return jsonify({"message": "Error processing the order request"}), 500
```

**Process**:
1. Extracts order details from request
2. Calls `create_order_with_openai()` which:
   - Generates unique order number (8-digit UUID)
   - Uses LangChain to format MongoDB insert query
   - Inserts order into `orders` collection
3. Returns order number to user

#### Cancel Order Endpoint (Lines 141-158)
```python
@app.route("/api/cancel_order", methods=["POST"])
def cancel_order_route():
    data = request.get_json()
    order_number = data.get("order_number")

    if not order_number:
        return jsonify({"message": "Please provide your order number to cancel."}), 400

    try:
        if cancel_order_with_openai(order_number):
            return jsonify({
                "message": f"Order {order_number} has been successfully canceled."
            })
        else:
            return jsonify({"message": f"Order {order_number} not found."}), 404
    except Exception as e:
        print("Error in cancel_order_route:", e)
        return jsonify({"message": "Error processing the cancellation request"}), 500
```

**Logic**:
1. Validates order number is provided
2. `cancel_order_with_openai()`:
   - Checks if order exists
   - Uses LangChain to generate MongoDB delete query
   - Deletes order from database
3. Returns success or not found message

#### Track Order Endpoint (Lines 161-172)
```python
@app.route("/api/track_order/<order_number>", methods=["GET"])
def track_order_route(order_number):
    """Endpoint to track the status of an order based on the order number."""
    try:
        order_info = find_order_by_number(order_number)
        if order_info:
            return jsonify(order_info), 200
        else:
            return jsonify({"message": "Order not found"}), 404
    except Exception as e:
        print("Error in track_order_route:", e)
        return jsonify({"message": "Error tracking the order"}), 500
```

**Returns**:
- Order details including: name, address, mobile, card_name, status, timestamp

#### Defect Reporting Endpoint (Lines 175-186)
```python
@app.route("/api/report_defect", methods=["POST"])
def report_defect_route():
    description = request.form.get("description")
    order_id = request.form.get("orderId")
    image = request.files.get("image")  # File upload

    try:
        tracking_id = report_defect(description, order_id, image)
        return jsonify({"trackingId": tracking_id}), 200
    except Exception as e:
        print("Error in report_defect_route:", e)
        return jsonify({"message": "Error processing the defect report"}), 500
```

**Processing**:
1. Receives form data (multipart/form-data)
2. `report_defect()` function:
   - Opens image with Pillow
   - Sends to GPT-4o-mini Vision API for analysis
   - LangChain LLM makes decision (Replacement/Refund/Escalate)
   - Saves to `defective_products` collection
   - Returns tracking ID

#### Track Defect Endpoint (Lines 189-199)
```python
@app.route("/api/track_defect/<tracking_id>", methods=["GET"])
def track_defect_route(tracking_id):
    try:
        defect_info = track_defect_status(tracking_id)
        if defect_info:
            return jsonify(defect_info), 200
        else:
            return jsonify({"message": "Tracking ID not found"}), 404
    except Exception as e:
        print("Error in track_defect_route:", e)
        return jsonify({"message": "Error tracking the defect status"}), 500
```

#### Fraud Reporting Endpoint (Lines 202-221)
```python
@app.route("/api/report_fraud", methods=["POST"])
def report_fraud_route():
    """Endpoint for reporting a fraudulent transaction with OCR image and transaction details."""
    try:
        transaction_details = request.form.get("transaction_details")
        ocr_image = request.files.get("ocr_image")

        if not transaction_details or not ocr_image:
            return jsonify({"message": "Transaction details and OCR image are required"}), 400

        tracking_id = report_fraud(transaction_details, ocr_image)
        return jsonify({"trackingId": tracking_id}), 200

    except Exception as e:
        print("Error processing fraud report:", e)
        return jsonify({"message": "Error processing the fraud report"}), 500
```

**Fraud Detection Flow**:
1. Receives transaction details (text) and receipt image
2. `report_fraud()`:
   - Uses PyTesseract OCR to extract text from image
   - Combines OCR text + transaction details
   - LangChain LLM analyzes for fraud indicators
   - Decides: Refund, Decline, or Escalate
   - Stores in `fraud_reports` collection

#### Health Check Endpoint (Lines 238-241)
```python
@app.route("/api/health", methods=["GET"])
def health_check():
    """Health check endpoint for container orchestration."""
    return jsonify({"status": "healthy", "service": "credit-card-backend"}), 200
```

**Purpose**: Used by Kubernetes liveness and readiness probes

---

### 3.2 config.py - LangChain MongoDB Query Generator

**File**: `/credit-card-backend/config.py`

#### Setup (Lines 1-9)
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate
import re
import os

openai_api_key = os.environ.get("OPENAI_API_KEY")
llm = ChatOpenAI(openai_api_key=openai_api_key, model_name="gpt-4o-mini")
```

**Key Components**:
- **LangChain ChatOpenAI**: Wrapper around OpenAI API
- **Model**: GPT-4o-mini (faster, cheaper than GPT-4 for query generation)

#### Prompt Template (Lines 12-50)
```python
template = """
You are a MongoDB query generator. Based on a user's message, create a MongoDB query to search for credit cards.

The credit card data has the following fields:
1. tier (e.g., "bronze", "silver", "gold", "diamond")
2. name (e.g., "Chase Starter Bronze", "Chase Rewards Silver")
3. issuer (e.g., "Chase Bank")
4. annual_fee (number, e.g., 0, 25, 95, 450)
5. interest_rate (number, e.g., 19.99, 17.99, 15.99)
6. credit_limit_min (number, minimum credit limit)
7. credit_limit_max (number, maximum credit limit)
8. rewards.cashback_percentage (number, e.g., 0.5, 1, 2, 3)
9. rewards.bonus_categories (array of objects with "category" and "multiplier", e.g., Travel, Dining, Groceries)
10. benefits (array of strings, e.g., ["Airport lounge access", "Travel insurance", "Concierge service"])
11. features (array of strings, e.g., ["Travel perks", "Premium rewards"])
12. is_active (boolean)
13. min_credit_score (number, minimum credit score required)
    Credit score ranges: Poor=300-579, Fair=580-669, Good=670-739,
    Very Good=740-799, Excellent=800-850

Generate a MongoDB query in JSON format based on the user's request:
- Always include {{"is_active": true}} in the query.
- Match "tier" if the user mentions a tier level.
- For travel cards, search "Travel" in bonus_categories or features using $regex.
- For credit limit requests, use credit_limit_max with $gte.
- For annual fee: use $lte for "low fee" or $eq: 0 for "no fee".
- For benefits, use "$regex" with "$options": "i" for case-insensitive matching.
- If user mentions credit score (e.g., "score is 720"), filter with
  {{"min_credit_score": {{"$lte": 720}}}}.
- Credit categories: Poor=579, Fair=669, Good=739, VeryGood=799, Excellent=850
- If user says "poor credit" use 579, "fair credit" use 669, etc.
- For general requests (e.g., "recommend a card"), return {{}} to show all.

Respond only with the JSON query format.

Message: {query}
MongoDB Query:
"""
prompt = PromptTemplate(input_variables=["query"], template=template)
```

**How It Works**:
1. Provides schema definition to GPT-4o-mini
2. Gives examples of query patterns for common requests
3. Specifies credit score range mappings
4. Instructs to always filter by `is_active: true`

#### Query Generation Function (Lines 54-74)
```python
chain = prompt | llm  # LangChain chain (modern syntax)

def generate_mongo_query(query):
    try:
        # Run the chain with the user query
        response = chain.invoke({"query": query})
        mongo_query = response.content
        print("Raw OpenAI Response:", mongo_query)

        # Use regex to extract JSON from code block markers
        match = re.search(r"```json\s*({.*})\s*```", mongo_query, re.DOTALL)
        if match:
            mongo_query = match.group(1)

        print("Final MongoDB Query String:", mongo_query)
        return mongo_query
    except Exception as e:
        print("Error generating MongoDB query:", e)
        return None
```

**Example Transformations**:

| User Input | MongoDB Query Generated |
|------------|-------------------------|
| "Show me travel cards" | `{"is_active": true, "$or": [{"rewards.bonus_categories.category": {"$regex": "Travel", "$options": "i"}}, {"features": {"$regex": "Travel", "$options": "i"}}]}` |
| "Cards with no annual fee and good credit score" | `{"is_active": true, "annual_fee": {"$eq": 0}, "min_credit_score": {"$lte": 739}}` |
| "Premium cards for excellent credit" | `{"is_active": true, "tier": "diamond", "min_credit_score": {"$lte": 850}}` |
| "Cashback cards under $100 fee" | `{"is_active": true, "rewards.cashback_percentage": {"$gte": 1}, "annual_fee": {"$lte": 100}}` |

**Regex Extraction**:
- GPT-4o-mini often wraps JSON in markdown code blocks: ````json ... ```
- Regex removes these markers to get pure JSON

---

### 3.3 models/card_model.py - MongoDB Card Queries

**File**: `/credit-card-backend/models/card_model.py`

```python
from pymongo import MongoClient
import os

# Connect to MongoDB - use service name in Kubernetes, localhost for local dev
mongo_host = os.environ.get("MONGO_HOST", "localhost")
client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = client["credit_card_assistant"]
cards_collection = db["creditcards"]

def find_cards_by_query(query):
    try:
        # Execute the query and exclude _id field
        return list(cards_collection.find(query, {"_id": 0}))
    except Exception as e:
        print("Error executing query:", e)
        return []
```

**Key Points**:
- **Environment Variable**: `MONGO_HOST` allows switching between localhost and Kubernetes service
- **Database**: `credit_card_assistant`
- **Collection**: `creditcards`
- **Projection**: `{"_id": 0}` excludes MongoDB's internal ID from results
- **Return**: List of card documents matching the query

---

### 3.4 models/order_model.py - Order CRUD Operations

**File**: `/credit-card-backend/models/order_model.py`

```python
from pymongo import MongoClient
import os

mongo_host = os.environ.get("MONGO_HOST", "localhost")
client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = client["credit_card_assistant"]
orders_collection = db["orders"]

def create_order(order_data):
    orders_collection.insert_one(order_data)

def cancel_order(order_number):
    result = orders_collection.delete_one({"order_number": order_number})
    return result.deleted_count > 0  # Returns True if an order was deleted
```

**Simple CRUD**:
- `create_order`: Inserts order document
- `cancel_order`: Deletes by order number, returns boolean success

---

### 3.5 order_agent.py - LangChain Order Management

**File**: `/credit-card-backend/order_agent.py`

#### Setup (Lines 1-17)
```python
from pymongo import MongoClient
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate
import uuid
import json
import os

mongo_host = os.environ.get("MONGO_HOST", "localhost")
client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = client["credit_card_assistant"]
orders_collection_name = "orders"

openai_api_key = os.environ.get("OPENAI_API_KEY")
llm = ChatOpenAI(openai_api_key=openai_api_key, model_name="gpt-4")
```

#### Insert Prompt (Lines 19-41)
```python
insert_prompt = PromptTemplate(
    input_variables=["name", "address", "mobile", "card_name", "order_number"],
    template="""
Given the following order details:
- Name: {name}
- Address: {address}
- Mobile: {mobile}
- Card Name: {card_name}
- Order Number: {order_number}

Generate a MongoDB insert query to add these details to the `orders` collection.
Ensure the query is formatted as valid JSON in a dictionary format, like this:
{{
    "name": "{name}",
    "address": "{address}",
    "mobile": "{mobile}",
    "card_name": "{card_name}",
    "order_number": "{order_number}"
}}
Only output the JSON dictionary without any additional text.
""",
)
```

**Purpose**: Instructs GPT-4 to format order data as JSON for MongoDB insertion

#### Create Order Function (Lines 68-112)
```python
def create_order_with_openai(details):
    """Generate a MongoDB insert query using OpenAI and execute it."""
    ensure_collection_exists()  # Create collection if doesn't exist

    order_number = str(uuid.uuid4().int)[:8]  # Generate 8-digit order number
    details["order_number"] = order_number

    # Create LangChain chain
    insert_chain = insert_prompt | llm

    # Generate MongoDB insert query with OpenAI
    response = insert_chain.invoke({
        "name": details["name"],
        "address": details["address"],
        "mobile": details["mobile"],
        "card_name": details["card_name"],
        "order_number": order_number,
    })
    response = response.content

    print("Generated Response from OpenAI for Insertion:", response)

    try:
        # Parse response as JSON
        mongo_query = json.loads(response)
        print("Generated MongoDB Insert Query:", mongo_query)

        # Execute the insert query
        result = db[orders_collection_name].insert_one(mongo_query)

        if result.inserted_id:
            print("Order successfully inserted into MongoDB:", mongo_query)
            return order_number
        else:
            print("Failed to insert order into MongoDB.")
            return None
    except json.JSONDecodeError as e:
        print("JSON decode error in generated query:", e)
        return None
    except Exception as e:
        print("Error generating or executing MongoDB query:", e)
        return None
```

**Flow**:
1. Generates unique 8-digit order number from UUID
2. LangChain asks GPT-4 to format order as JSON
3. Parses JSON response
4. Inserts into MongoDB
5. Returns order number on success

#### Find Order Function (Lines 115-145)
```python
def find_order_by_number(order_number):
    """Check if an order exists in MongoDB by order number and return it."""
    # Try finding as string first
    order = db[orders_collection_name].find_one({"order_number": order_number})

    if not order:
        # Try as number if the input can be converted to int
        try:
            order = db[orders_collection_name].find_one(
                {"order_number": int(order_number)}
            )
        except (ValueError, TypeError):
            pass

    if order:
        print(f"Order found: {order}")
        # Remove _id field (not JSON serializable)
        if "_id" in order:
            del order["_id"]
        # Ensure order_number is string
        if "order_number" in order:
            order["order_number"] = str(order["order_number"])
        # Add default status
        if "status" not in order:
            order["status"] = "confirmed"
        if "timestamp" not in order:
            from datetime import datetime
            order["timestamp"] = datetime.now().isoformat()
    else:
        print(f"No order found with order number: {order_number}")
    return order
```

**Handles Two Cases**:
- Order number stored as string
- Order number stored as integer
- Tries both types to ensure compatibility

#### Cancel Order Function (Lines 148-208)
```python
def cancel_order_with_openai(order_number):
    """Generate a MongoDB delete query using OpenAI and execute it."""
    # Check if order exists first
    if not find_order_by_number(order_number):
        print(f"Order {order_number} not found. Cancellation aborted.")
        return False

    # Create LangChain chain
    cancel_chain = cancel_prompt | llm

    # Generate MongoDB delete query with OpenAI
    response = cancel_chain.invoke({"order_number": order_number})
    response = response.content
    print("Generated Response for Cancellation from OpenAI:", response)

    try:
        # Parse response as JSON
        mongo_query = json.loads(response)
        print("Initial Generated MongoDB Delete Query:", mongo_query)

        # Handle different field name variations
        if "Order Number" in mongo_query:
            mongo_query["order_number"] = mongo_query.pop("Order Number")
        elif "orderNumber" in mongo_query:
            mongo_query["order_number"] = mongo_query.pop("orderNumber")

        # Try to delete with string version first
        mongo_query["order_number"] = str(mongo_query["order_number"])
        result = db[orders_collection_name].delete_one(mongo_query)

        # If not found as string, try as number
        if result.deleted_count == 0:
            try:
                mongo_query["order_number"] = int(order_number)
                result = db[orders_collection_name].delete_one(mongo_query)
            except (ValueError, TypeError):
                pass

        if result.deleted_count > 0:
            print(f"Order {order_number} successfully deleted from MongoDB.")
            return True
        else:
            print(f"Order {order_number} not found in MongoDB for deletion.")
            return False
    except json.JSONDecodeError as e:
        print("JSON decode error in generated delete query:", e)
        return False
```

**Robust Deletion**:
- Verifies order exists before attempting deletion
- Handles field name variations (Order Number vs orderNumber)
- Tries both string and integer types
- Returns boolean success indicator

---

### 3.6 defect_agent.py - Image Analysis & Defect Handling

**File**: `/credit-card-backend/defect_agent.py`

#### Setup (Lines 1-20)
```python
from PIL import Image
from openai import OpenAI
from pymongo import MongoClient
from langchain_core.prompts import PromptTemplate
from langchain_openai import ChatOpenAI
import uuid
import os

mongo_host = os.environ.get("MONGO_HOST", "localhost")
mongo_client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = mongo_client["credit_card_assistant"]
defects_collection = db["defective_products"]

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
openai_client = OpenAI(api_key=OPENAI_API_KEY)

llm = ChatOpenAI(openai_api_key=OPENAI_API_KEY, model_name="gpt-4")
```

#### Decision Prompt (Lines 22-39)
```python
decision_prompt = PromptTemplate(
    input_variables=["image_analysis", "description"],
    template="""
    A customer has reported a defect with the following details:

    Image Analysis: {image_analysis}
    Description: {description}

    Based on the image analysis and description, decide the appropriate action:
    Options are:
    - "Replacement Approved" for minor scratches or small damages.
    - "Refund Approved" for significant issues like completely damaged or broken parts.
    - "Escalate to Human" if the defect cannot be clearly identified or needs further review.

    Respond with the decision and a concise message for the customer.
    """,
)
```

**Three-Tier Decision Logic**:
- **Replacement**: Minor issues (scratches, small defects)
- **Refund**: Major damage (broken, unusable)
- **Escalate**: Unclear or requires human judgment

#### Main Report Function (Lines 42-63)
```python
def report_defect(description, order_id, image):
    """Processes the defect report by analyzing the image and making a decision using GPT-4 vision and LangChain."""

    pil_image = Image.open(image).convert("RGB")
    image_analysis = analyze_defect_image(pil_image)  # GPT-4 Vision analysis
    decision, message = get_decision_with_llm(description, image_analysis)  # LangChain decision

    # Generate tracking ID
    tracking_id = str(uuid.uuid4().int)[:8]

    # Store in MongoDB
    defect_record = {
        "trackingId": tracking_id,
        "description": description,
        "orderId": order_id,
        "decision": decision,
        "message": message,
    }
    defects_collection.insert_one(defect_record)

    return tracking_id
```

**Process**:
1. Open image with Pillow, convert to RGB
2. Send to GPT-4 Vision for analysis
3. Use LangChain LLM to make decision based on analysis
4. Generate tracking ID
5. Store in MongoDB
6. Return tracking ID to user

#### Image Analysis Function (Lines 66-112)
```python
def analyze_defect_image(image):
    """Uses OpenAI's GPT-4 with vision capabilities to analyze the defect image and return a description."""
    try:
        # Save image temporarily
        temp_image_path = "temp_image.png"
        image.save(temp_image_path, format="PNG")

        import base64
        with open(temp_image_path, "rb") as f:
            image_data = base64.b64encode(f.read()).decode("utf-8")

        # Send to GPT-4o-mini Vision
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Analyze this product image for defects. Describe any visible damage, scratches, breaks, or quality issues in detail.",
                        },
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/png;base64,{image_data}"},
                        },
                    ],
                }
            ],
            max_tokens=300,
        )

        print("Raw OpenAI Image Analysis Response:", response)

        # Extract textual analysis
        image_analysis = response.choices[0].message.content

        # Clean up temp file
        os.remove(temp_image_path)

        return image_analysis

    except Exception as e:
        print("Error analyzing defect image:", e)
        return "Image analysis failed. Please review the image manually."
```

**GPT-4 Vision Integration**:
1. Saves image to temporary file
2. Encodes as base64 string
3. Sends to GPT-4o-mini with vision capability
4. Prompt: "Analyze this product image for defects..."
5. Returns detailed text description of visible issues

#### Decision Function (Lines 115-135)
```python
def get_decision_with_llm(description, image_analysis):
    """Uses LangChain LLM to make a decision based on image analysis and description."""

    decision_chain = decision_prompt | llm

    # Run the prompt with image analysis and description
    result = decision_chain.invoke({
        "image_analysis": image_analysis,
        "description": description
    })
    response = result.content.strip()

    # Determine the decision from LLM response
    if "Replacement Approved" in response:
        decision = "Replacement Approved"
    elif "Refund Approved" in response:
        decision = "Refund Approved"
    else:
        decision = "Escalate to Human"

    message = response  # Use full response as customer message
    return decision, message
```

**Decision Flow**:
```
Image Analysis + User Description
          ↓
  LangChain LLM (GPT-4)
          ↓
   Parse Response Text
          ↓
  Extract Decision Category
          ↓
Return (Decision, Message)
```

#### Track Function (Lines 138-149)
```python
def track_defect_status(tracking_id):
    """Retrieves the defect status based on the tracking ID."""
    defect = defects_collection.find_one({"trackingId": tracking_id})
    if defect:
        return {
            "description": defect["description"],
            "orderId": defect["orderId"],
            "decision": defect["decision"],
            "message": defect["message"],
        }
    else:
        return None
```

---

### 3.7 fraud_agent.py - OCR & Fraud Detection

**File**: `/credit-card-backend/fraud_agent.py`

#### Setup (Lines 1-17)
```python
import uuid
import os
from PIL import Image
import pytesseract
from pymongo import MongoClient
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate

mongo_host = os.environ.get("MONGO_HOST", "localhost")
client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = client["credit_card_assistant"]
fraud_reports_collection = db["fraud_reports"]

llm = ChatOpenAI(openai_api_key=os.environ.get("OPENAI_API_KEY"), model_name="gpt-4")
```

#### Fraud Report Prompt (Lines 20-35)
```python
fraud_report_prompt = PromptTemplate(
    input_variables=["ocr_text", "transaction_details"],
    template="""
    A customer reported a potentially fraudulent transaction on their credit card.
    OCR Data: "{ocr_text}"
    Transaction Details: "{transaction_details}"

    Decide the appropriate action:
    - "Refund" if unauthorized or incorrect.
    - "Decline" if it's valid.
    - "Escalate to Human-Agent" if unclear.

    Respond with one option only.
    """,
)
```

#### OCR Function (Lines 49-53)
```python
def extract_text_from_image(image_file):
    """Extracts text from an OCR image using Tesseract."""
    image = Image.open(image_file)
    ocr_text = pytesseract.image_to_string(image)
    return ocr_text
```

**PyTesseract OCR**:
- Opens image with Pillow
- Runs Tesseract OCR engine
- Extracts all readable text from receipt/transaction image
- Returns as plain text string

#### Fraud Analysis Function (Lines 56-63)
```python
def analyze_fraudulent_transaction(ocr_text, transaction_details):
    """Uses LangChain LLM chain to analyze OCR text and transaction details."""
    fraud_chain = fraud_report_prompt | llm
    result = fraud_chain.invoke({
        "ocr_text": ocr_text,
        "transaction_details": transaction_details
    })
    decision = result.content.strip()
    return decision
```

**Fraud Detection Logic**:
- Combines OCR text from receipt + user's description
- LangChain LLM (GPT-4) analyzes both sources
- Looks for discrepancies, unauthorized charges, incorrect amounts
- Returns: Refund, Decline, or Escalate to Human-Agent

#### Report Fraud Function (Lines 66-80)
```python
def report_fraud(transaction_details, ocr_image):
    """Processes fraud report with OCR and LangChain-based AI decision-making."""

    ocr_text = extract_text_from_image(ocr_image)  # Extract text from receipt
    decision = analyze_fraudulent_transaction(ocr_text, transaction_details)  # Analyze

    tracking_id = str(uuid.uuid4().int)[:8]
    fraud_report = {
        "trackingId": tracking_id,
        "transactionDetails": transaction_details,
        "ocrText": ocr_text,
        "decision": decision,
    }
    fraud_reports_collection.insert_one(fraud_report)

    return tracking_id
```

#### Track Fraud Function (Lines 83-103)
```python
def track_fraud_status(tracking_id):
    """Retrieves fraud report details by tracking ID."""
    fraud_report = fraud_reports_collection.find_one({"trackingId": tracking_id})

    if fraud_report:
        decision = fraud_report["decision"]
        transaction_details = fraud_report["transactionDetails"]

        # Use the fraud_track_prompt to construct a response
        fraud_track_chain = fraud_track_prompt | llm
        result = fraud_track_chain.invoke({
            "tracking_id": tracking_id,
            "transaction_details": transaction_details
        })
        response = result.content.strip()

        return {
            "transactionDetails": transaction_details,
            "ocrText": fraud_report["ocrText"],
            "decision": decision,
            "response": response,
        }
    return None
```

---

## 4. DATABASE SCHEMA

### MongoDB Collections

#### Collection: `creditcards`
Stores the credit card catalog with detailed card information.

```json
{
  "_id": ObjectId("..."),
  "tier": "gold",
  "name": "Chase Sapphire Gold",
  "issuer": "Chase Bank",
  "description": "Premium travel rewards card",
  "annual_fee": 95,
  "interest_rate": 17.99,
  "credit_limit_min": 3000,
  "credit_limit_max": 15000,
  "min_credit_score": 670,
  "rewards": {
    "cashback_percentage": 2,
    "bonus_categories": [
      {
        "category": "Travel",
        "multiplier": 3
      },
      {
        "category": "Dining",
        "multiplier": 2
      }
    ]
  },
  "benefits": [
    "No foreign transaction fees",
    "Travel insurance",
    "Airport lounge access",
    "Priority boarding"
  ],
  "features": [
    "Travel perks",
    "Rewards program"
  ],
  "is_active": true
}
```

**Field Descriptions**:
- `tier`: Card category - bronze, silver, gold, diamond
- `name`: Full card name
- `issuer`: Bank/financial institution
- `description`: Brief card overview
- `annual_fee`: Yearly fee in dollars
- `interest_rate`: APR percentage
- `credit_limit_min/max`: Credit limit range
- `min_credit_score`: Minimum required credit score (300-850)
- `rewards.cashback_percentage`: Base cashback rate
- `rewards.bonus_categories`: Categories with bonus multipliers
- `benefits`: Array of card perks
- `features`: Array of feature tags
- `is_active`: Boolean flag for active cards

#### Collection: `orders`
Stores customer card application orders.

```json
{
  "_id": ObjectId("..."),
  "order_number": "12345678",
  "name": "John Doe",
  "address": "123 Main St, New York, NY 10001",
  "mobile": "555-1234",
  "card_name": "Chase Sapphire Gold",
  "user_id": "abc123xyz",
  "status": "confirmed",
  "timestamp": "2024-01-27T10:30:00.000Z"
}
```

**Field Descriptions**:
- `order_number`: Unique 8-digit identifier
- `name`: Customer full name
- `address`: Shipping address
- `mobile`: Contact phone number
- `card_name`: Requested credit card
- `user_id`: Session identifier
- `status`: Order status (confirmed, shipped, delivered, cancelled)
- `timestamp`: ISO 8601 timestamp

#### Collection: `defective_products`
Stores defect reports with AI-generated decisions.

```json
{
  "_id": ObjectId("..."),
  "trackingId": "87654321",
  "description": "Card has scratches on magnetic strip",
  "orderId": "12345678",
  "decision": "Replacement Approved",
  "message": "Based on the image analysis showing minor surface scratches, a replacement card will be shipped within 3-5 business days."
}
```

**Field Descriptions**:
- `trackingId`: Unique 8-digit tracking number
- `description`: Customer's defect description
- `orderId`: Associated order number
- `decision`: AI decision - "Replacement Approved", "Refund Approved", or "Escalate to Human"
- `message`: AI-generated customer message

#### Collection: `fraud_reports`
Stores fraud transaction reports with OCR data.

```json
{
  "_id": ObjectId("..."),
  "trackingId": "99887766",
  "transactionDetails": "I see a charge for $500 at XYZ Store that I didn't make",
  "ocrText": "XYZ STORE\nDATE: 01/25/2024\nAMOUNT: $500.00\nCARD: ****1234",
  "decision": "Refund"
}
```

**Field Descriptions**:
- `trackingId`: Unique tracking identifier
- `transactionDetails`: Customer's fraud description
- `ocrText`: Text extracted from receipt image via OCR
- `decision`: AI decision - "Refund", "Decline", or "Escalate to Human-Agent"

### Credit Score Ranges and Tiers

| Category | Score Range | Description |
|----------|-------------|-------------|
| Poor | 300-579 | Secured cards, high fees |
| Fair | 580-669 | Starter cards, moderate fees |
| Good | 670-739 | Standard rewards cards |
| Very Good | 740-799 | Premium cards, good benefits |
| Excellent | 800-850 | Elite cards, best rewards |

### Card Tier System

| Tier | Annual Fee Range | Typical Features |
|------|------------------|------------------|
| Bronze | $0 - $25 | Basic cashback, no perks |
| Silver | $25 - $95 | 1-2% cashback, basic travel insurance |
| Gold | $95 - $250 | 2-3% cashback, airport lounge access, travel insurance |
| Diamond | $250+ | Premium concierge, 3-5% cashback, luxury perks |

---

## 5. AI/ML INTEGRATION

### 5.1 LangChain MongoDB Query Generation

**Technology**: LangChain + OpenAI GPT-4o-mini

**Location**: `/credit-card-backend/config.py`

**Process Flow**:
```
User Query: "Show me travel cards for good credit score"
           ↓
┌──────────────────────────────────────────────────┐
│  LangChain Prompt Template                       │
│  - Provides MongoDB schema                       │
│  - Defines query patterns                        │
│  - Maps credit score categories to numbers       │
└──────────────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────────────┐
│  GPT-4o-mini Model                               │
│  - Understands natural language intent           │
│  - Generates MongoDB query JSON                  │
└──────────────────────────────────────────────────┘
           ↓
Generated Query:
{
  "is_active": true,
  "min_credit_score": {"$lte": 739},
  "$or": [
    {"rewards.bonus_categories.category": {"$regex": "Travel", "$options": "i"}},
    {"features": {"$regex": "Travel", "$options": "i"}}
  ]
}
           ↓
┌──────────────────────────────────────────────────┐
│  MongoDB Execution                               │
│  - Finds cards with is_active=true               │
│  - Credit score <= 739 (Good range)              │
│  - Travel in bonus categories OR features        │
└──────────────────────────────────────────────────┘
           ↓
    Returns Card Array
```

**Example Transformations**:

1. **Natural Language**: "No annual fee cards"
   **MongoDB Query**: `{"is_active": true, "annual_fee": {"$eq": 0}}`

2. **Natural Language**: "Premium cards with excellent credit"
   **MongoDB Query**: `{"is_active": true, "tier": "diamond", "min_credit_score": {"$lte": 850}}`

3. **Natural Language**: "Cashback cards under $50 fee"
   **MongoDB Query**: `{"is_active": true, "rewards.cashback_percentage": {"$gte": 1}, "annual_fee": {"$lte": 50}}`

**Advantages**:
- No hardcoded query logic
- Flexible to new query patterns
- Handles complex multi-condition queries
- Understands synonyms (e.g., "free" = $0 fee)

### 5.2 OpenAI GPT-4 Intent Detection

**Technology**: OpenAI GPT-4 Chat Completions

**Location**: `/credit-card-backend/main.py` - `detect_intent()` function

**System Prompt**:
```
You are an assistant that categorizes customer inquiries into one of the following intents:
'greeting', 'track order', 'cancel order', 'report defect', 'track defect',
'report fraud transaction', 'track fraud status', or 'other'.
```

**User Prompt Template**:
```
Please categorize this message into [list of intents]: '{user_message}'.
```

**Example Classifications**:

| User Message | Detected Intent |
|--------------|----------------|
| "Hi there!" | greeting_intent |
| "I want to track my order" | track_intent |
| "Cancel order 12345678" | cancel_intent |
| "My card is damaged" | report_defect_intent |
| "Check status of defect 87654321" | track_defect_intent |
| "Unauthorized charge on my card" | report_fraud_intent |
| "Show me travel cards" | other (proceeds to recommendation) |

**Intent Mapping Logic**:
```python
if "greeting" in intent_response:
    return "greeting_intent"
elif "track defect" in intent_response:
    return "track_defect_intent"
elif "track order" in intent_response:
    return "track_intent"
# ... more conditions
else:
    return "other"  # Default to card recommendation flow
```

**Why GPT-4 for Intent Detection?**
- Understands context and variations
- No need for training data
- Handles typos and informal language
- Easily extensible to new intents

### 5.3 Credit Score Filtering Logic

**Implementation**: Frontend Helper + Backend Query

#### Frontend (CardList.js):
```javascript
function getCreditScoreCategory(score) {
  if (!score) return "Not specified";
  if (score >= 800) return "Excellent (800+)";
  if (score >= 740) return "Very Good (740-799)";
  if (score >= 670) return "Good (670-739)";
  if (score >= 580) return "Fair (580-669)";
  return "Poor (300-579)";
}
```

#### Backend (config.py LangChain Prompt):
```
Credit score ranges: Poor=300-579, Fair=580-669, Good=670-739,
Very Good=740-799, Excellent=800-850

If user mentions credit score (e.g., "score is 720"), filter with
{"min_credit_score": {"$lte": 720}}.

Credit categories: Poor=579, Fair=669, Good=739, VeryGood=799, Excellent=850
If user says "poor credit" use 579, "fair credit" use 669, etc.
```

**Query Logic**:
- User's credit score: 720
- MongoDB query: `{"min_credit_score": {"$lte": 720}}`
- Returns cards requiring minimum score of 720 or less
- Example: Card requires 670 (Good) ✓, Card requires 740 (Very Good) ✗

### 5.4 GPT-4 Vision for Defect Detection

**Technology**: OpenAI GPT-4o-mini with Vision API

**Location**: `/credit-card-backend/defect_agent.py` - `analyze_defect_image()`

**Process**:
1. Customer uploads image of defective card
2. Backend converts to base64 encoding
3. Sends to GPT-4o-mini Vision API with prompt:
   ```
   "Analyze this product image for defects. Describe any visible damage,
   scratches, breaks, or quality issues in detail."
   ```
4. GPT-4o-mini returns detailed text analysis:
   ```
   "The image shows a credit card with minor surface scratches on the
   magnetic strip. The chip appears intact. There are no cracks or breaks.
   The scratches are superficial and unlikely to affect functionality."
   ```
5. LangChain LLM (GPT-4) makes decision based on analysis:
   - Minor damage → "Replacement Approved"
   - Major damage → "Refund Approved"
   - Unclear → "Escalate to Human"

**Example Decisions**:

| Image Analysis | Decision |
|----------------|----------|
| "Minor scratches on magnetic strip" | Replacement Approved |
| "Card is completely broken in half" | Refund Approved |
| "Image is blurry, cannot determine damage" | Escalate to Human |

### 5.5 PyTesseract OCR for Fraud Detection

**Technology**: PyTesseract (Tesseract OCR Engine)

**Location**: `/credit-card-backend/fraud_agent.py` - `extract_text_from_image()`

**Process**:
1. Customer uploads receipt image with suspicious transaction
2. PyTesseract extracts all text from image:
   ```
   XYZ STORE
   123 Main Street
   DATE: 01/25/2024
   TIME: 14:30
   CARD: ****1234
   AMOUNT: $500.00
   THANK YOU
   ```
3. Combines OCR text + user description:
   ```
   OCR: "XYZ STORE ... AMOUNT: $500.00 ... CARD: ****1234"
   User: "I didn't make this purchase, I was at home"
   ```
4. LangChain LLM (GPT-4) analyzes for fraud indicators:
   - Checks if amount matches user's claim
   - Verifies location plausibility
   - Identifies suspicious patterns
5. Returns decision: Refund, Decline, or Escalate

**Fraud Detection Logic**:
```python
fraud_report_prompt = PromptTemplate(
    template="""
    A customer reported a potentially fraudulent transaction.
    OCR Data: "{ocr_text}"
    Transaction Details: "{transaction_details}"

    Decide: "Refund" if unauthorized or incorrect,
            "Decline" if it's valid,
            "Escalate to Human-Agent" if unclear.
    """
)
```

---

## 6. AWS INFRASTRUCTURE

### 6.1 EKS Cluster Setup

**Cluster Name**: `vinod-credit-card-production`
**Region**: `us-east-1`
**Kubernetes Version**: 1.30
**Node Type**: Managed Node Group

**Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│             EKS Cluster: vinod-credit-card-production   │
│                                                          │
│  Namespace: credit-card-system                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Deployments:                                      │ │
│  │  - frontend (3 replicas, HPA 3-10)                │ │
│  │  - backend (3 replicas, HPA 3-10)                 │ │
│  │  - mongodb (1 replica, 20Gi PVC)                  │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Services:                                         │ │
│  │  - frontend-service (ClusterIP, port 80)          │ │
│  │  - backend-service (ClusterIP, port 5001)         │ │
│  │  - mongodb-service (ClusterIP, port 27017)        │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Ingress: credit-card-ingress (AWS ALB)           │ │
│  │  - /api/* → backend-service:5001                  │ │
│  │  - /* → frontend-service:80                        │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Kubernetes Deployments

#### Frontend Deployment
**File**: `/k8s/base/frontend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: credit-card-system
spec:
  replicas: 3  # Initial replica count
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # 1 extra pod during update
      maxUnavailable: 0  # No downtime during updates
  template:
    spec:
      containers:
      - name: frontend
        image: 489785350283.dkr.ecr.us-east-1.amazonaws.com/vinod-credit-card-credit-card-frontend-production:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Key Features**:
- **Rolling Update**: Zero-downtime deployments
- **Resource Limits**: Prevents resource exhaustion
- **Liveness Probe**: Restarts unhealthy pods
- **Readiness Probe**: Routes traffic only to ready pods
- **3 Replicas**: High availability

#### Backend Deployment
**File**: `/k8s/base/backend-deployment.yaml`

```yaml
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: backend
        image: 489785350283.dkr.ecr.us-east-1.amazonaws.com/vinod-credit-card-credit-card-backend-production:latest
        ports:
        - containerPort: 5001
        env:
        - name: FLASK_APP
          valueFrom:
            configMapKeyRef:
              name: backend-config
              key: FLASK_APP
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: backend-secrets
              key: OPENAI_API_KEY
        - name: MONGO_HOST
          value: "mongodb-service"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
```

**Configuration**:
- **Environment Variables**: ConfigMap for non-sensitive, Secret for API keys
- **MongoDB Connection**: Uses Kubernetes service name `mongodb-service`
- **Higher Resources**: Backend needs more memory for AI processing

#### MongoDB Deployment
**File**: `/k8s/base/mongodb-deployment.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: gp2  # AWS EBS gp2 volumes
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  replicas: 1  # Single instance (not HA)
  template:
    spec:
      containers:
      - name: mongodb
        image: mongo:6.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_DATABASE
          value: credit_card_assistant
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
      volumes:
      - name: mongodb-data
        persistentVolumeClaim:
          claimName: mongodb-pvc
```

**Storage**:
- **PVC**: 20Gi persistent volume
- **Storage Class**: gp2 (AWS EBS General Purpose SSD)
- **Data Persistence**: Survives pod restarts

### 6.3 Horizontal Pod Autoscaler (HPA)

#### Frontend HPA
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
spec:
  scaleTargetRef:
    kind: Deployment
    name: frontend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

**Autoscaling Behavior**:
- Scales up when CPU > 70% OR memory > 80%
- Scales down when metrics are below targets
- Minimum 3 pods (high availability)
- Maximum 10 pods (cost control)

#### Backend HPA
Similar configuration with same min/max replicas and thresholds.

### 6.4 Load Balancer Configuration

**File**: `/k8s/base/ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: credit-card-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /api/health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
spec:
  rules:
  - http:
      paths:
      - path: /api/*
        pathType: ImplementationSpecific
        backend:
          service:
            name: backend-service
            port:
              number: 5001
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

**ALB Configuration**:
- **Scheme**: internet-facing (public access)
- **Target Type**: IP (EKS pods have IP addresses)
- **Health Check**: `/api/health` endpoint every 15 seconds
- **Routing**:
  - `/api/*` → Backend service (port 5001)
  - `/*` → Frontend service (port 80)

**URL**: `http://k8s-creditca-creditca-dffee1a493-37154518.us-east-1.elb.amazonaws.com`

### 6.5 CI/CD Pipeline (GitHub Actions)

#### Backend Pipeline
**File**: `/.github/workflows/backend-deploy.yml`

**Stages**:
1. **Lint and Test**
   - Python 3.12
   - Flake8 linting
   - Black code formatting check
   - Pytest (placeholder)

2. **Build and Push**
   - Multi-platform Docker build (linux/amd64)
   - Push to AWS ECR
   - Trivy security scanning
   - GitHub Security tab integration

3. **Deploy to EKS**
   - Update kubeconfig
   - Create/update secrets (OPENAI_API_KEY)
   - Apply Kubernetes manifests
   - Wait for rollout completion
   - Smoke tests (health check)

4. **Notify**
   - Success/failure notifications
   - (Placeholder for Slack/Discord)

**Trigger**:
```yaml
on:
  push:
    branches:
      - vinod/project
      - main
      - develop
    paths:
      - 'credit-card-backend/**'
```

#### Frontend Pipeline
**File**: `/.github/workflows/frontend-deploy.yml`

**Stages**:
1. **Lint and Test**
   - Node.js 18
   - npm ci (clean install)
   - ESLint
   - Build React app
   - Upload build artifacts

2. **Build and Push**
   - Multi-stage Docker build
   - Push to ECR
   - Trivy scanning

3. **Deploy to EKS**
   - Apply manifests
   - Rollout status check
   - Smoke tests (/ and /health)

**Docker Multi-Stage Build** (Frontend):
```dockerfile
# Stage 1: Build React app
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:1.25-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Benefits**:
- Smaller final image (only production assets)
- Nginx serves static files efficiently
- Health check endpoint for Kubernetes

#### Pipeline Secrets (GitHub)
- `AWS_ACCESS_KEY_ID`: AWS credentials for ECR/EKS access
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `OPENAI_API_KEY`: OpenAI API key for GPT-4
- `REACT_APP_API_URL`: Backend URL for frontend

---

## 7. END-TO-END REQUEST FLOW

### 7.1 Card Recommendation Flow

#### User Query: "Show me travel cards for good credit score"

**Step-by-Step Execution**:

1. **Frontend: User Input (App.js)**
   ```javascript
   // Line 30: handleSendMessage()
   const userMessage = { type: "user", text: "Show me travel cards for good credit score" };
   setMessages((prevMessages) => [...prevMessages, userMessage]);

   // Line 39: POST request
   const response = await axios.post(`${API_BASE_URL}/api/recommend`, {
     message: "Show me travel cards for good credit score",
     user_id: userId,
   });
   ```

2. **Backend: Intent Detection (main.py)**
   ```python
   # Line 65: /api/recommend endpoint
   intent = detect_intent(message)  # Calls GPT-4

   # Line 24: detect_intent()
   response = client.chat.completions.create(
       model="gpt-4",
       messages=[{
           "role": "system",
           "content": "You are an assistant that categorizes customer inquiries..."
       }, {
           "role": "user",
           "content": f"Please categorize this message..."
       }]
   )
   # GPT-4 Response: "other" (not a specific intent like track/cancel)
   ```

3. **Backend: Query Generation (config.py)**
   ```python
   # Line 98: Generate MongoDB query
   mongo_query_str = generate_mongo_query(message)

   # Line 58: generate_mongo_query()
   response = chain.invoke({"query": "Show me travel cards for good credit score"})

   # GPT-4o-mini generates:
   {
     "is_active": true,
     "min_credit_score": {"$lte": 739},
     "$or": [
       {"rewards.bonus_categories.category": {"$regex": "Travel", "$options": "i"}},
       {"features": {"$regex": "Travel", "$options": "i"}}
     ]
   }
   ```

4. **Backend: Database Query (card_model.py)**
   ```python
   # Line 100: Execute query
   mongo_query = json.loads(mongo_query_str)
   recommended_cards = find_cards_by_query(mongo_query)

   # Line 13: find_cards_by_query()
   return list(cards_collection.find(query, {"_id": 0}))

   # MongoDB returns array of matching cards:
   [
     {
       "tier": "gold",
       "name": "Chase Sapphire Gold",
       "issuer": "Chase Bank",
       "annual_fee": 95,
       "min_credit_score": 670,
       "rewards": {
         "bonus_categories": [{"category": "Travel", "multiplier": 3}]
       },
       ...
     },
     {
       "tier": "silver",
       "name": "Capital One Venture Silver",
       ...
     }
   ]
   ```

5. **Backend: Response (main.py)**
   ```python
   # Line 102: Return cards
   if recommended_cards:
       return jsonify(recommended_cards), 200
   ```

6. **Frontend: Display Cards (App.js → ChatMessage.js → CardList.js)**
   ```javascript
   // App.js Line 83: handleBackendResponse()
   const botMessage = { type: "bot", cards: response.data };
   setMessages((prevMessages) => [...prevMessages, botMessage]);

   // ChatMessage.js Line 4: Render cards
   {message.cards && <CardList cards={message.cards} onBuy={onBuy} />}

   // CardList.js Line 18: Map through cards
   {cards.map((card, index) => (
     <div key={index} className="card-item">
       <div className={`card-tier-banner tier-${card.tier}`}>
         {card.tier?.toUpperCase()}
       </div>
       <h3>{card.name}</h3>
       <p>${card.annual_fee} annual fee</p>
       <p>{getCreditScoreCategory(card.min_credit_score)}</p>
       ...
       <button onClick={() => onBuy(card)}>Apply Now</button>
     </div>
   ))}
   ```

**Visual Flow**:
```
User Types Message
        ↓
Frontend (React) - App.js
        ↓ (POST /api/recommend)
Backend (Flask) - main.py
        ↓
GPT-4 Intent Detection → "other" (recommendation flow)
        ↓
LangChain Query Generation (config.py)
        ↓
GPT-4o-mini → MongoDB Query JSON
        ↓
MongoDB Query Execution (card_model.py)
        ↓
MongoDB → Array of Card Documents
        ↓
Flask → JSON Response
        ↓
Frontend (React) - App.js receives response
        ↓
ChatMessage.js renders message
        ↓
CardList.js displays cards
        ↓
User Sees Recommendations
```

**Timing Estimate**:
- Frontend → Backend: ~100ms (network)
- Intent Detection (GPT-4): ~500ms
- Query Generation (GPT-4o-mini): ~300ms
- MongoDB Query: ~50ms
- Backend → Frontend: ~100ms
- **Total: ~1050ms (1.05 seconds)**

---

### 7.2 Order Creation Flow

#### User Action: Clicks "Apply Now" on a card

**Step-by-Step Execution**:

1. **Frontend: Button Click (CardList.js)**
   ```javascript
   // Line 67: Apply Now button
   <button onClick={() => onBuy(card)}>Apply Now</button>

   // Calls onBuy prop passed from App.js
   ```

2. **Frontend: Show Order Form (App.js)**
   ```javascript
   // Line 93: handleBuy()
   const handleBuy = (card) => {
     setShowOrderForm(true);
     setOrderDetails((prevDetails) => ({
       ...prevDetails,
       card_name: card.name
     }));
   };

   // Line 210: Order form modal appears
   {showOrderForm && (
     <div className="order-form-modal">
       <form onSubmit={handleOrderSubmit}>
         <input type="text" name="name" placeholder="Full Name" required />
         <input type="text" name="address" placeholder="Address" required />
         <input type="text" name="mobile" placeholder="Mobile Number" required />
         <input type="text" name="card_name" value={orderDetails.card_name} readOnly />
         <button type="submit">Submit Order</button>
       </form>
     </div>
   )}
   ```

3. **Frontend: Form Submission (App.js)**
   ```javascript
   // Line 103: handleOrderSubmit()
   const handleOrderSubmit = async (e) => {
     e.preventDefault();
     setLoading(true);

     const response = await axios.post(`${API_BASE_URL}/api/create_order`, {
       name: "John Doe",
       address: "123 Main St",
       mobile: "555-1234",
       card_name: "Chase Sapphire Gold",
       user_id: "abc123xyz"
     });
   };
   ```

4. **Backend: Order Creation Endpoint (main.py)**
   ```python
   # Line 113: /api/create_order
   @app.route("/api/create_order", methods=["POST"])
   def create_order_route():
       data = request.get_json()
       details = {
           "name": data.get("name"),
           "address": data.get("address"),
           "mobile": data.get("mobile"),
           "card_name": data.get("card_name"),
           "user_id": data.get("user_id"),
       }

       # Line 127: Call LangChain order agent
       order_number = create_order_with_openai(details)
   ```

5. **Backend: LangChain Order Processing (order_agent.py)**
   ```python
   # Line 68: create_order_with_openai()
   order_number = str(uuid.uuid4().int)[:8]  # Generate: "12345678"
   details["order_number"] = order_number

   # Line 76: Create LangChain chain
   insert_chain = insert_prompt | llm

   # Line 79: Generate MongoDB insert query
   response = insert_chain.invoke({
       "name": "John Doe",
       "address": "123 Main St",
       "mobile": "555-1234",
       "card_name": "Chase Sapphire Gold",
       "order_number": "12345678"
   })

   # GPT-4 generates:
   {
     "name": "John Doe",
     "address": "123 Main St",
     "mobile": "555-1234",
     "card_name": "Chase Sapphire Gold",
     "order_number": "12345678"
   }

   # Line 99: Insert into MongoDB
   result = db["orders"].insert_one(mongo_query)

   # Line 102: Return order number
   return order_number  # "12345678"
   ```

6. **Backend: Response (main.py)**
   ```python
   # Line 129: Return success message
   return jsonify({
       "message": f"Order created successfully with order number {order_number}."
   })
   ```

7. **Frontend: Display Confirmation (App.js)**
   ```javascript
   // Line 111: Handle response
   handleBackendResponse(response);
   setShowOrderForm(false);
   setOrderDetails({ name: "", address: "", mobile: "", card_name: "" });

   // Line 88: handleBackendResponse adds message to chat
   const botMessage = {
     type: "bot",
     text: "Order created successfully with order number 12345678."
   };
   setMessages((prevMessages) => [...prevMessages, botMessage]);
   ```

**Visual Flow**:
```
User Clicks "Apply Now"
        ↓
Frontend Shows Order Form Modal
        ↓
User Fills Form & Submits
        ↓ (POST /api/create_order)
Backend main.py receives order data
        ↓
order_agent.py: Generate UUID order number
        ↓
LangChain + GPT-4: Format as MongoDB JSON
        ↓
Insert into MongoDB orders collection
        ↓
Return order number to frontend
        ↓
Frontend displays success message in chat
        ↓
User Sees "Order created with number 12345678"
```

---

### 7.3 Defect Reporting Flow

#### User Action: Reports defective card with image

**Step-by-Step Execution**:

1. **Frontend: Intent Detection (App.js)**
   ```javascript
   // User types: "I want to report a defect"
   // Line 39: POST /api/recommend
   const response = await axios.post(`${API_BASE_URL}/api/recommend`, {
     message: "I want to report a defect",
     user_id: userId
   });

   // Line 57: Backend returns "report_defect_intent"
   if (response.data.message === "report_defect_intent") {
     setShowDefectForm(true);
     const botMessage = { type: "bot", text: "Please fill out the defect report form." };
     setMessages((prevMessages) => [...prevMessages, botMessage]);
   }
   ```

2. **Frontend: Defect Form (Defect.js)**
   ```javascript
   // User fills form:
   // - Order ID: "12345678"
   // - Description: "Card has scratches on chip"
   // - Image: (uploads defect photo)

   // Line 15: handleSubmitDefect()
   const formData = new FormData();
   formData.append("description", "Card has scratches on chip");
   formData.append("orderId", "12345678");
   formData.append("image", defectImage);  // File object

   // Line 23: POST with multipart/form-data
   const response = await axios.post(`${API_BASE_URL}/api/report_defect`, formData);
   ```

3. **Backend: Defect Report Endpoint (main.py)**
   ```python
   # Line 175: /api/report_defect
   @app.route("/api/report_defect", methods=["POST"])
   def report_defect_route():
       description = request.form.get("description")  # "Card has scratches on chip"
       order_id = request.form.get("orderId")  # "12345678"
       image = request.files.get("image")  # File object

       # Line 182: Call defect agent
       tracking_id = report_defect(description, order_id, image)
   ```

4. **Backend: Image Analysis (defect_agent.py)**
   ```python
   # Line 42: report_defect()
   pil_image = Image.open(image).convert("RGB")

   # Line 45: Analyze with GPT-4 Vision
   image_analysis = analyze_defect_image(pil_image)

   # Line 66: analyze_defect_image()
   # Save temporarily, encode as base64
   image.save("temp_image.png", format="PNG")
   image_data = base64.b64encode(f.read()).decode("utf-8")

   # Line 79: Send to GPT-4o-mini Vision
   response = openai_client.chat.completions.create(
       model="gpt-4o-mini",
       messages=[{
           "role": "user",
           "content": [{
               "type": "text",
               "text": "Analyze this product image for defects..."
           }, {
               "type": "image_url",
               "image_url": {"url": f"data:image/png;base64,{image_data}"}
           }]
       }]
   )

   # GPT-4o-mini returns:
   "The image shows a credit card with surface scratches on the EMV chip area.
   The scratches are minor and superficial. The magnetic strip appears intact.
   No cracks or breaks are visible."
   ```

5. **Backend: Decision Making (defect_agent.py)**
   ```python
   # Line 46: Get decision from LLM
   decision, message = get_decision_with_llm(description, image_analysis)

   # Line 115: get_decision_with_llm()
   decision_chain = decision_prompt | llm
   result = decision_chain.invoke({
       "image_analysis": "...minor scratches on EMV chip...",
       "description": "Card has scratches on chip"
   })

   # GPT-4 returns:
   "Based on the image analysis showing minor surface scratches on the EMV chip,
   this qualifies for a Replacement Approved. A new card will be shipped within
   3-5 business days."

   # Line 127: Parse decision
   if "Replacement Approved" in response:
       decision = "Replacement Approved"
   ```

6. **Backend: Store in MongoDB (defect_agent.py)**
   ```python
   # Line 48: Generate tracking ID
   tracking_id = str(uuid.uuid4().int)[:8]  # "87654321"

   # Line 54: Create defect record
   defect_record = {
       "trackingId": "87654321",
       "description": "Card has scratches on chip",
       "orderId": "12345678",
       "decision": "Replacement Approved",
       "message": "Based on the image analysis..."
   }
   defects_collection.insert_one(defect_record)

   # Line 62: Return tracking ID
   return tracking_id
   ```

7. **Backend: Response (main.py)**
   ```python
   # Line 183: Return tracking ID
   return jsonify({"trackingId": "87654321"}), 200
   ```

8. **Frontend: Display Result (Defect.js → App.js)**
   ```javascript
   // Defect.js Line 24: Receive response
   setTrackingId(response.data.trackingId);
   onResponse(response.data);  // Call App.js callback
   onClose();

   // App.js Line 248: onResponse callback
   const botMessage = {
     type: "bot",
     text: `Defect reported successfully. Tracking ID: ${data.trackingId}`
   };
   setMessages((prevMessages) => [...prevMessages, botMessage]);
   ```

**Visual Flow**:
```
User Types "Report defect"
        ↓
GPT-4 Intent Detection → "report_defect_intent"
        ↓
Frontend Shows Defect Form Modal
        ↓
User Fills Form + Uploads Image
        ↓ (POST /api/report_defect with FormData)
Backend Receives Multipart Request
        ↓
defect_agent.py: Open image with Pillow
        ↓
Convert to Base64
        ↓
GPT-4o-mini Vision API: Analyze Image
        ↓
Returns: "Minor scratches on EMV chip..."
        ↓
LangChain GPT-4: Make Decision
        ↓
Returns: "Replacement Approved"
        ↓
Generate Tracking ID (8-digit UUID)
        ↓
Store in MongoDB defective_products collection
        ↓
Return Tracking ID to Frontend
        ↓
Frontend Displays: "Defect reported. Tracking ID: 87654321"
```

---

### 7.4 Fraud Detection Flow

#### User Action: Reports fraudulent transaction with receipt

**Step-by-Step Execution**:

1. **Frontend: Intent + Form (App.js → FraudTransaction.js)**
   ```javascript
   // User types: "I see a fraudulent charge"
   // GPT-4 returns: "report_fraud_intent"
   // Shows FraudTransaction form

   // User fills:
   // - Transaction Details: "I see a $500 charge at XYZ Store that I didn't make"
   // - Image: (uploads receipt photo)

   // FraudTransaction.js Line 24: Create FormData
   const formData = new FormData();
   formData.append("transaction_details", "I see a $500 charge...");
   formData.append("ocr_image", ocrImage);

   // Line 29: POST request
   const response = await axios.post(`${API_BASE_URL}/api/report_fraud`, formData);
   ```

2. **Backend: Fraud Report Endpoint (main.py)**
   ```python
   # Line 202: /api/report_fraud
   @app.route("/api/report_fraud", methods=["POST"])
   def report_fraud_route():
       transaction_details = request.form.get("transaction_details")
       ocr_image = request.files.get("ocr_image")

       # Line 215: Call fraud agent
       tracking_id = report_fraud(transaction_details, ocr_image)
   ```

3. **Backend: OCR Processing (fraud_agent.py)**
   ```python
   # Line 66: report_fraud()
   ocr_text = extract_text_from_image(ocr_image)

   # Line 49: extract_text_from_image()
   image = Image.open(image_file)
   ocr_text = pytesseract.image_to_string(image)

   # PyTesseract returns:
   """
   XYZ STORE
   123 Main Street, New York
   DATE: 01/25/2024
   TIME: 14:30:15
   CARD: ****1234
   AMOUNT: $500.00
   THANK YOU FOR YOUR PURCHASE
   """
   ```

4. **Backend: Fraud Analysis (fraud_agent.py)**
   ```python
   # Line 69: Analyze with LangChain
   decision = analyze_fraudulent_transaction(ocr_text, transaction_details)

   # Line 56: analyze_fraudulent_transaction()
   fraud_chain = fraud_report_prompt | llm
   result = fraud_chain.invoke({
       "ocr_text": "XYZ STORE ... AMOUNT: $500.00 ... CARD: ****1234",
       "transaction_details": "I see a $500 charge at XYZ Store that I didn't make"
   })

   # LangChain Prompt:
   """
   A customer reported a potentially fraudulent transaction.
   OCR Data: "XYZ STORE ... AMOUNT: $500.00..."
   Transaction Details: "I didn't make this purchase"

   Decide: "Refund" if unauthorized, "Decline" if valid, "Escalate" if unclear.
   """

   # GPT-4 returns: "Refund"
   decision = "Refund"
   ```

5. **Backend: Store in MongoDB (fraud_agent.py)**
   ```python
   # Line 71: Generate tracking ID
   tracking_id = str(uuid.uuid4().int)[:8]  # "99887766"

   # Line 72: Create fraud report
   fraud_report = {
       "trackingId": "99887766",
       "transactionDetails": "I see a $500 charge...",
       "ocrText": "XYZ STORE ... AMOUNT: $500.00...",
       "decision": "Refund"
   }
   fraud_reports_collection.insert_one(fraud_report)

   return tracking_id
   ```

6. **Backend: Response (main.py)**
   ```python
   # Line 217: Return tracking ID
   return jsonify({"trackingId": "99887766"}), 200
   ```

7. **Frontend: Display Result (FraudTransaction.js → App.js)**
   ```javascript
   // FraudTransaction.js Line 30: Receive response
   onResponse(response.data);
   onClose();

   // App.js Line 167: onResponse callback
   const botMessage = {
     type: "bot",
     text: `Fraud Report Tracking ID: ${data.trackingId}`
   };
   setMessages((prevMessages) => [...prevMessages, botMessage]);
   ```

**Visual Flow**:
```
User Reports Fraud + Uploads Receipt
        ↓ (POST /api/report_fraud)
Backend Receives Image + Description
        ↓
fraud_agent.py: Open Image with Pillow
        ↓
PyTesseract OCR: Extract Text
        ↓
Returns: "XYZ STORE ... AMOUNT: $500.00 ... CARD: ****1234"
        ↓
Combine OCR Text + User Description
        ↓
LangChain GPT-4: Analyze for Fraud
        ↓
Checks: Amount match, location plausibility, suspicious patterns
        ↓
Decision: "Refund" (unauthorized transaction)
        ↓
Generate Tracking ID
        ↓
Store in MongoDB fraud_reports collection
        ↓
Return Tracking ID to Frontend
        ↓
User Sees: "Fraud Report Tracking ID: 99887766"
```

---

## 8. KEY FEATURES

### 8.1 Credit Score-Based Recommendations

**Implementation**:
- User provides credit score in natural language (e.g., "score is 720" or "good credit")
- LangChain converts to MongoDB query: `{"min_credit_score": {"$lte": 720}}`
- Returns only cards user qualifies for
- Frontend displays credit score category for each card

**Benefits**:
- Prevents users from applying for cards they won't get approved for
- Personalized recommendations based on creditworthiness
- Transparent minimum score requirements

**Example Queries**:
- "Show me cards for excellent credit" → min_credit_score ≤ 850
- "I have a 650 score, what cards can I get?" → min_credit_score ≤ 650
- "Cards for poor credit" → min_credit_score ≤ 579

### 8.2 Order Management

**Features**:
- **Create Order**: Generate unique 8-digit order number
- **Track Order**: View order status, shipping info, timestamps
- **Cancel Order**: Delete order from database before shipping

**Data Stored**:
- Customer details (name, address, mobile)
- Card name
- Order number (UUID-based)
- User ID (session tracking)
- Timestamp
- Status (confirmed, shipped, delivered, cancelled)

**LangChain Integration**:
- GPT-4 formats order data as MongoDB JSON
- Ensures consistent data structure
- Handles field name variations

### 8.3 Defect Reporting

**AI-Powered Process**:
1. Customer uploads image of defective card
2. GPT-4o-mini Vision API analyzes image
3. Describes damage in detail (scratches, breaks, cracks)
4. LangChain LLM makes decision based on severity
5. Auto-approves replacement or refund
6. Escalates unclear cases to human agent

**Decision Matrix**:
| Damage Type | Example | Decision |
|-------------|---------|----------|
| Minor scratches | Surface scratches on plastic | Replacement Approved |
| Chip damage | EMV chip not reading | Replacement Approved |
| Magnetic strip damage | Strip demagnetized | Replacement Approved |
| Card broken in half | Physical break | Refund Approved |
| Completely unusable | Melted, burned | Refund Approved |
| Unclear damage | Blurry image | Escalate to Human |

**Benefits**:
- 24/7 automated defect processing
- Consistent decision-making
- Faster resolution for customers
- Reduced support staff workload

### 8.4 Fraud Detection

**Multi-Source Analysis**:
- **User Description**: Customer explains suspicious transaction
- **OCR Text Extraction**: PyTesseract reads receipt/statement image
- **Combined Analysis**: LangChain LLM cross-references both sources

**Fraud Indicators**:
- Amount mismatch (receipt vs. charge)
- Location implausibility (customer wasn't there)
- Duplicate charges
- Unauthorized merchant
- Incorrect card number

**Decision Logic**:
- **Refund**: Clear unauthorized transaction
- **Decline**: Valid transaction, no fraud
- **Escalate**: Requires human investigation

**Example Scenarios**:

| User Claim | OCR Data | Decision |
|------------|----------|----------|
| "I didn't make this $500 purchase" | Receipt shows $500 at XYZ Store | Refund (unauthorized) |
| "I was charged twice for $50" | Two receipts, same merchant, same time | Refund (duplicate) |
| "This $100 charge is wrong" | Receipt shows $100, valid signature | Decline (legitimate) |
| "Strange charge, unclear" | Blurry image, incomplete data | Escalate to Human-Agent |

**Benefits**:
- Fast fraud detection (< 2 seconds)
- Reduces false positives
- Automatic refund initiation
- Tracks all fraud reports with IDs

---

## INTERVIEW PREPARATION TIPS

### Architecture Questions
1. **Q**: Explain the high-level architecture.
   **A**: "The system uses a React frontend, Flask backend, and MongoDB database, all deployed on AWS EKS. The frontend communicates with the backend via RESTful APIs. The backend integrates OpenAI GPT-4 for intent detection and LangChain for MongoDB query generation. Kubernetes handles orchestration with 3 replicas each for frontend and backend, load balanced via AWS ALB."

2. **Q**: Why MongoDB instead of SQL?
   **A**: "MongoDB's flexible schema is perfect for credit card data with nested objects (rewards, bonus categories, benefits). It allows fast iteration without schema migrations. The natural language to MongoDB query conversion via LangChain is straightforward with JSON structure."

3. **Q**: How does the system scale?
   **A**: "Horizontal Pod Autoscaler (HPA) automatically scales frontend and backend from 3 to 10 replicas based on CPU (70%) and memory (80%) thresholds. AWS ALB distributes traffic. MongoDB can be scaled to replica sets for production. ECR stores immutable container images for consistent deployments."

### AI/ML Questions
1. **Q**: Explain the LangChain integration.
   **A**: "LangChain converts natural language queries to MongoDB JSON. I provide a detailed prompt template with schema definitions and example patterns. GPT-4o-mini generates the query, which is parsed and executed. This eliminates hardcoded query logic and handles complex multi-condition queries naturally."

2. **Q**: Why GPT-4 for intent detection?
   **A**: "GPT-4 understands context and variations without training data. It handles typos, informal language, and synonyms. For example, 'check my order', 'track order', 'where is my card' all map to 'track_intent'. This would require extensive training data with traditional ML models."

3. **Q**: How does defect detection work?
   **A**: "I use GPT-4o-mini Vision API to analyze uploaded images. It describes visible damage in detail. Then LangChain LLM makes a decision (Replacement/Refund/Escalate) based on severity. Minor damage gets automatic replacement, major damage gets refund, unclear cases escalate to humans."

### DevOps Questions
1. **Q**: Explain the CI/CD pipeline.
   **A**: "GitHub Actions workflows trigger on push to vinod/project branch. Pipeline has 3 stages: (1) Lint and Test - runs flake8, black, eslint, builds app; (2) Build and Push - multi-stage Docker build, pushes to ECR, Trivy security scan; (3) Deploy - updates EKS deployment, waits for rollout, runs smoke tests."

2. **Q**: How do you handle secrets?
   **A**: "Kubernetes Secrets store sensitive data like OPENAI_API_KEY. GitHub Actions creates/updates secrets before deployment. Environment variables are injected into pods via ConfigMap (non-sensitive) and Secret (sensitive). The backend reads via os.environ.get()."

3. **Q**: What's your deployment strategy?
   **A**: "RollingUpdate with maxSurge=1 and maxUnavailable=0 ensures zero downtime. New pods start before old ones terminate. Readiness probes ensure traffic only routes to healthy pods. Liveness probes restart crashed pods. Health checks run every 15 seconds on /api/health."

### Code Questions
1. **Q**: Walk through the card recommendation flow.
   **A**: "User types message → Frontend POST to /api/recommend → GPT-4 detects intent → If 'other', LangChain generates MongoDB query → Query executes on cards collection → Returns card array → Frontend renders in CardList → User clicks Apply Now → Shows order form → POST to /api/create_order → Generates UUID order number → Stores in MongoDB → Returns success."

2. **Q**: How do you handle errors?
   **A**: "Try-catch blocks at every API call. Backend returns descriptive error messages. Frontend displays user-friendly text. Logging with print statements for debugging. HTTP status codes (200, 404, 500) for different scenarios. Continue-on-error for non-critical steps like security scans."

3. **Q**: Explain the order cancellation logic.
   **A**: "User provides order number → Backend checks if order exists (find_order_by_number) → If not found, returns 404 → If found, LangChain generates MongoDB delete query → Tries deleting as string, then as integer → Returns success boolean → Frontend displays confirmation message."

---

## CONCLUSION

This Credit Card Recommendation System demonstrates:
- **Modern Full-Stack Development**: React + Flask + MongoDB
- **Cloud-Native Architecture**: Kubernetes, Docker, AWS EKS/ECR/ALB
- **AI/ML Integration**: OpenAI GPT-4, LangChain, PyTesseract OCR
- **DevOps Best Practices**: CI/CD, IaC, Monitoring, Security Scanning
- **Enterprise Features**: Autoscaling, Load Balancing, Zero Downtime Deployments

**Key Achievements**:
- Natural language understanding for card search
- Credit score-based personalization
- AI-powered defect detection with image analysis
- OCR-based fraud detection
- Complete order management lifecycle
- Production-ready Kubernetes deployment
- Automated CI/CD pipeline with security scanning

**Technologies Mastered**:
- **Frontend**: React, Axios, CSS3
- **Backend**: Flask, Gunicorn, Python 3.12
- **Database**: MongoDB 6.0, PyMongo
- **AI/ML**: OpenAI GPT-4, GPT-4o-mini, LangChain, PyTesseract
- **Cloud**: AWS EKS, ECR, ALB, VPC
- **DevOps**: Docker, Kubernetes, GitHub Actions, Trivy
- **Tools**: Git, ESLint, Flake8, Black, kubectl

This documentation serves as a complete reference for interviews, code reviews, and onboarding new team members.

---

**Document Version**: 1.0
**Last Updated**: February 10, 2026
**Author**: Vinod Reddy Billipalli
**Project**: Credit Card Recommendation System
