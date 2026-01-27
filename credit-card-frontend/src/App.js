// src/App.js
import React, { useState } from "react";
import axios from "axios";
import ChatMessage from "./ChatMessage";
import Defect from "./Defect"; // Import Defect component
import Track from "./Track"; // Import Track component for defect tracking
import TrackOrder from "./TrackOrder"; // Import TrackOrder component for order tracking
import FraudTransaction from "./FraudTransaction"; // Import FraudTransaction component
import TrackFraud from "./TrackFraud"; // Import TrackFraud component
import API_BASE_URL from "./config"; // Import API base URL
import "./App.css";

function App() {
  const [userInput, setUserInput] = useState("");
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const [userId] = useState(() => Math.random().toString(36).substr(2, 9));
  const [showOrderForm, setShowOrderForm] = useState(false);
  const [showCancelForm, setShowCancelForm] = useState(false);
  const [showDefectForm, setShowDefectForm] = useState(false); // State for defect form
  const [showTrackDefectForm, setShowTrackDefectForm] = useState(false); // State for track defect form
  const [showTrackOrderForm, setShowTrackOrderForm] = useState(false); // State for track order form
  const [showFraudForm, setShowFraudForm] = useState(false); // State for fraud transaction form
  const [showTrackFraudForm, setShowTrackFraudForm] = useState(false); // State for fraud tracking form
  const [orderDetails, setOrderDetails] = useState({ name: "", address: "", mobile: "", card_name: "" });
  const [orderNumber, setOrderNumber] = useState("");

  const handleInputChange = (e) => setUserInput(e.target.value);

  const handleSendMessage = async () => {
    if (userInput.trim() === "") return;

    const userMessage = { type: "user", text: userInput };
    setMessages((prevMessages) => [...prevMessages, userMessage]);

    setLoading(true);

    try {
      const response = await axios.post(`${API_BASE_URL}/api/recommend`, {
        message: userInput,
        user_id: userId,
      });

      // Handle intent responses from the backend
      if (response.data.message === "track_intent") {
        setShowTrackOrderForm(true); // Display track order form modal
        const botMessage = { type: "bot", text: "Please enter your order number to track your order." };
        setMessages((prevMessages) => [...prevMessages, botMessage]);
      } else if (response.data.message === "cancel_intent") {
        setShowCancelForm(true); // Display cancel form modal
        const botMessage = { type: "bot", text: "Please enter your order number to cancel your order." };
        setMessages((prevMessages) => [...prevMessages, botMessage]);
      } else if (response.data.message === "track_defect_intent") {
        setShowTrackDefectForm(true); // Display track defect form modal
        const botMessage = { type: "bot", text: "Please enter your defect tracking ID." };
        setMessages((prevMessages) => [...prevMessages, botMessage]);
      } else if (response.data.message === "report_defect_intent") {
        setShowDefectForm(true); // Display defect form modal
        const botMessage = { type: "bot", text: "Please fill out the defect report form." };
        setMessages((prevMessages) => [...prevMessages, botMessage]);
      } else if (response.data.message === "report_fraud_intent") {
        setShowFraudForm(true); // Display fraud transaction form modal
        const botMessage = { type: "bot", text: "Please fill out the fraud report form." };
        setMessages((prevMessages) => [...prevMessages, botMessage]);
      } else if (response.data.message === "track_fraud_intent") {
        setShowTrackFraudForm(true); // Display fraud tracking form modal
        const botMessage = { type: "bot", text: "Please enter your fraud report tracking ID." };
        setMessages((prevMessages) => [...prevMessages, botMessage]);
      } else {
        handleBackendResponse(response);
      }
    } catch (error) {
      console.error("Error processing message:", error.response?.data || error.message);
      const errorText = error.response?.data?.message || "There was an error processing your request.";
      const errorMessage = { type: "bot", text: errorText };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
    } finally {
      setUserInput("");
      setLoading(false);
    }
  };

  const handleBackendResponse = (response) => {
    if (Array.isArray(response.data)) {
      const botMessage = { type: "bot", cards: response.data };
      setMessages((prevMessages) => [...prevMessages, botMessage]);
    } else if (response.data.message) {
      const botMessage = { type: "bot", text: response.data.message };
      setMessages((prevMessages) => [...prevMessages, botMessage]);
    }
  };

  const handleBuy = (card) => {
    setShowOrderForm(true);
    setOrderDetails((prevDetails) => ({ ...prevDetails, card_name: card.name }));
  };

  const handleOrderFormChange = (e) => {
    const { name, value } = e.target;
    setOrderDetails((prevDetails) => ({ ...prevDetails, [name]: value }));
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
      console.error("Error creating order:", error);
      const errorText = error.response?.data?.message || "There was an error processing your order.";
      const errorMessage = { type: "bot", text: errorText };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
      setShowOrderForm(false);
      setOrderDetails({ name: "", address: "", mobile: "", card_name: "" });
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
      console.error("Error canceling order:", error);
      const errorText = error.response?.data?.message || "There was an error processing your cancellation request.";
      const errorMessage = { type: "bot", text: errorText };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
      setShowCancelForm(false);
      setOrderNumber("");
    } finally {
      setLoading(false);
    }
  };

  // Function to handle track order response
  const handleTrackOrderResponse = (data) => {
    const botMessage = {
      type: "bot",
      text: data.message
    };
    setMessages((prevMessages) => [...prevMessages, botMessage]);
  };

  // Function to handle track defect response
  const handleTrackDefectResponse = (data) => {
    const botMessage = {
      type: "bot",
      text: `Defect Tracking Info: Description: ${data.description}, Order ID: ${data.orderId}, Decision: ${data.decision}, Message: ${data.message}`
    };
    setMessages((prevMessages) => [...prevMessages, botMessage]);
  };

  // Function to handle fraud transaction response
  const handleFraudTransactionResponse = (data) => {
    const botMessage = {
      type: "bot",
      text: `Fraud Report Tracking ID: ${data.trackingId}`
    };
    setMessages((prevMessages) => [...prevMessages, botMessage]);
  };

  // Function to handle fraud tracking response
  const handleTrackFraudResponse = (data) => {
    const botMessage = {
      type: "bot",
      text: `Fraud Tracking Update: Decision: ${data.decision}`
    };
    setMessages((prevMessages) => [...prevMessages, botMessage]);
  };

  return (
    <div className="app">
      <h1>Credit Card Recommendation Chat</h1>
      <div className="chat-container">
        {messages.map((msg, index) => (
          <ChatMessage key={index} message={msg} onBuy={handleBuy} />
        ))}
      </div>
      <div className="input-container">
        <input
          type="text"
          value={userInput}
          onChange={handleInputChange}
          placeholder="Type your message here..."
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              handleSendMessage();
            }
          }}
        />
        <button onClick={handleSendMessage} disabled={loading}>
          {loading ? "Loading..." : "Send"}
        </button>
      </div>

      {/* Order Form Modal */}
      {showOrderForm && (
        <div className="order-form-modal">
          <div className="order-form">
            <h2>Enter Your Details</h2>
            <form onSubmit={handleOrderSubmit}>
              <input type="text" name="name" placeholder="Full Name" value={orderDetails.name} onChange={handleOrderFormChange} required />
              <input type="text" name="address" placeholder="Address" value={orderDetails.address} onChange={handleOrderFormChange} required />
              <input type="text" name="mobile" placeholder="Mobile Number" value={orderDetails.mobile} onChange={handleOrderFormChange} required />
              <input type="text" name="card_name" placeholder="Card Name" value={orderDetails.card_name} readOnly />
              <button type="submit" disabled={loading}>Submit Order</button>
              <button type="button" onClick={() => setShowOrderForm(false)}>Cancel</button>
            </form>
          </div>
        </div>
      )}

      {/* Cancel Order Form Modal */}
      {showCancelForm && (
        <div className="cancel-form-modal">
          <div className="cancel-form">
            <h2>Cancel Your Order</h2>
            <form onSubmit={handleCancelOrderSubmit}>
              <input
                type="text"
                name="order_number"
                placeholder="Order Number"
                value={orderNumber}
                onChange={(e) => setOrderNumber(e.target.value)}
                required
              />
              <button type="submit" disabled={loading}>Cancel Order</button>
              <button type="button" onClick={() => setShowCancelForm(false)}>Close</button>
            </form>
          </div>
        </div>
      )}

      {/* Defect Report Form Modal */}
      {showDefectForm && <Defect onClose={() => setShowDefectForm(false)} onResponse={(data) => {
        const botMessage = { type: "bot", text: `Defect reported successfully. Tracking ID: ${data.trackingId}` };
        setMessages((prevMessages) => [...prevMessages, botMessage]);
      }} />}

      {/* Track Order Form Modal */}
      {showTrackOrderForm && (
        <TrackOrder
          onClose={() => setShowTrackOrderForm(false)}
          onResponse={handleTrackOrderResponse}
        />
      )}

      {/* Track Defect Form Modal */}
      {showTrackDefectForm && (
        <Track
          onClose={() => setShowTrackDefectForm(false)}
          onResponse={handleTrackDefectResponse}
        />
      )}

      {/* Fraud Transaction Report Form Modal */}
      {showFraudForm && (
        <FraudTransaction
          onClose={() => setShowFraudForm(false)}
          onResponse={handleFraudTransactionResponse}
        />
      )}

      {/* Fraud Tracking Form Modal */}
      {showTrackFraudForm && (
        <TrackFraud
          onClose={() => setShowTrackFraudForm(false)}
          onResponse={handleTrackFraudResponse}
        />
      )}
    </div>
  );
}

export default App;
