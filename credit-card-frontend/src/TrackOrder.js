// src/TrackOrder.js
import React, { useState } from "react";
import axios from "axios";
import API_BASE_URL from "./config";
import "./TrackOrder.css";

function TrackOrder({ onClose, onResponse }) {
  const [orderNumber, setOrderNumber] = useState("");
  const [orderInfo, setOrderInfo] = useState(null);
  const [error, setError] = useState(null);

  const handleOrderNumberChange = (e) => setOrderNumber(e.target.value);

  const handleTrackSubmit = async (e) => {
    e.preventDefault();
    setOrderInfo(null);
    setError(null);

    try {
      const response = await axios.get(`${API_BASE_URL}/api/track_order/${orderNumber}`);
      setOrderInfo(response.data);

      // Format order info message for chat
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
      const errorMsg = error.response?.data?.message || "Order not found or there was an error retrieving the order details.";
      setError(errorMsg);
    }
  };

  return (
    <div className="track-order-container">
      <button className="close-button" onClick={onClose}>&times;</button>
      <h2>Track Order Status</h2>
      <form onSubmit={handleTrackSubmit} className="track-order-form">
        <input
          type="text"
          placeholder="Enter Order Number"
          value={orderNumber}
          onChange={handleOrderNumberChange}
          required
        />
        <button type="submit">Track Order</button>
      </form>

      {error && <p className="error-message">{error}</p>}

      {orderInfo && (
        <div className="order-details">
          <h3>Order Details</h3>
          <p><strong>Order Number:</strong> {orderNumber}</p>
          <p><strong>Card:</strong> {orderInfo.card_name}</p>
          <p><strong>Name:</strong> {orderInfo.name}</p>
          <p><strong>Address:</strong> {orderInfo.address}</p>
          <p><strong>Mobile:</strong> {orderInfo.mobile}</p>
          <p><strong>Status:</strong> {orderInfo.status}</p>
          <p><strong>Created:</strong> {new Date(orderInfo.timestamp).toLocaleString()}</p>
        </div>
      )}
    </div>
  );
}

export default TrackOrder;
