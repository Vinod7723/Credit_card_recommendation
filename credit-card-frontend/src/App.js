// src/App.js
import React, { useState } from "react";
import axios from "axios";
import ChatMessage from "./ChatMessage";
import Defect from "./Defect"; // Import Defect component
import Track from "./Track"; // Import Track component
import FraudTransaction from "./FraudTransaction"; // Import FraudTransaction component
import TrackFraud from "./TrackFraud"; // Import TrackFraud component
import "./App.css";

function App() {
  const [userInput, setUserInput] = useState("");
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const [userId] = useState(() => Math.random().toString(36).substr(2, 9));
  const [showOrderForm, setShowOrderForm] = useState(false);
  const [showCancelForm, setShowCancelForm] = useState(false);
  const [showDefectForm, setShowDefectForm] = useState(false); // State for defect form
  const [showTrackForm, setShowTrackForm] = useState(false); // State for track form
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
      const response = await axios.post("http://localhost:5001/api/recommend", {
        message: userInput,
        user_id: userId,
      });

      // Handle intent responses from the backend
      if (response.data.message === "track_intent") {
        setShowTrackForm(true); // Display track form modal
      } else if (response.data.message === "cancel_intent") {
        setShowCancelForm(true); // Display cancel form modal
      } else if (response.data.message === "track_defect_intent") {
        setShowTrackForm(true); // Display track defect form modal
      } else if (response.data.message === "report_defect_intent") {
        setShowDefectForm(true); // Display defect form modal
      } else if (response.data.message === "report_fraud_intent") {
        setShowFraudForm(true); // Display fraud transaction form modal
      } else if (response.data.message === "track_fraud_intent") {
        setShowTrackFraudForm(true); // Display fraud tracking form modal
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
    setOrderDetails((prevDetails) => ({ ...prevDetails, card_name: card.card_name }));
  };

  const handleOrderFormChange = (e) => {
    const { name, value } = e.target;
    setOrderDetails((prevDetails) => ({ ...prevDetails, [name]: value }));
  };

  const handleOrderSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const response = await axios.post("http://localhost:5001/api/create_order", {
        ...orderDetails,
        user_id: userId,
      });
      handleBackendResponse(response);
      setShowOrderForm(false);
    } catch (error) {
      console.error("Error creating order:", error);
      const errorMessage = { type: "bot", text: "There was an error processing your order." };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
    } finally {
      setLoading(false);
      setOrderDetails({ name: "", address: "", mobile: "", card_name: "" });
    }
  };

  const handleCancelOrderSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const response = await axios.post("http://localhost:5001/api/cancel_order", {
        order_number: orderNumber,
      });
      handleBackendResponse(response);
      setShowCancelForm(false);
    } catch (error) {
      console.error("Error canceling order:", error);
      const errorMessage = { type: "bot", text: "There was an error processing your cancellation request." };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
    } finally {
      setLoading(false);
      setOrderNumber("");  // Reset the cancel form
    }
  };

  // Function to handle track response
  const handleTrackResponse = (data) => {
    const botMessage = {
      type: "bot",
      text: `Tracking Info: Description: ${data.description}, Order ID: ${data.orderId}, Decision: ${data.decision}, Message: ${data.message}`
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
      {showDefectForm && <Defect onClose={() => setShowDefectForm(false)} />}

      {/* Track Order Form Modal */}
      {showTrackForm && (
        <Track 
          onClose={() => setShowTrackForm(false)} 
          onResponse={handleTrackResponse}
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
