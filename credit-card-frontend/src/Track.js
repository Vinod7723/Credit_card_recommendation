// src/Track.js
import React, { useState } from "react";
import axios from "axios";
import "./Track.css"; // Import CSS for styling

function Track({ onClose, onResponse }) {
  const [trackingId, setTrackingId] = useState("");
  const [status, setStatus] = useState(null);
  const [error, setError] = useState(null);

  const handleTrackingIdChange = (e) => setTrackingId(e.target.value);

  const handleTrackSubmit = async (e) => {
    e.preventDefault();
    setStatus(null);  // Reset status on new submission
    setError(null);   // Reset error

    try {
      const response = await axios.get(`http://localhost:5001/api/track_defect/${trackingId}`);
      setStatus(response.data);  // Set status based on API response
      onResponse(response.data); // Send response back to App.js for chat display
      onClose(); // Close the track form after submitting
    } catch (error) {
      setError("Tracking ID not found or there was an error retrieving the defect status.");
    }
  };

  return (
    <div className="track-container">
      <button className="close-button" onClick={onClose}>&times;</button>
      <h2>Track Defect Status</h2>
      <form onSubmit={handleTrackSubmit} className="track-form">
        <input
          type="text"
          placeholder="Enter Tracking ID"
          value={trackingId}
          onChange={handleTrackingIdChange}
          required
        />
        <button type="submit">Track</button>
      </form>

      {error && <p className="error-message">{error}</p>}

      {status && (
        <div className="status-details">
          <h3>Defect Status</h3>
          <p><strong>Description:</strong> {status.description}</p>
          <p><strong>Order ID:</strong> {status.orderId}</p>
          <p><strong>Decision:</strong> {status.decision}</p>
          <p><strong>Message:</strong> {status.message}</p>
        </div>
      )}
    </div>
  );
}

export default Track;
