// src/TrackFraud.js
import React, { useState } from "react";
import axios from "axios";
import "./TrackFraud.css";

function TrackFraud({ onClose, onResponse }) {
  const [trackingId, setTrackingId] = useState("");
  const [error, setError] = useState(null);

  const handleTrackingIdChange = (e) => setTrackingId(e.target.value);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);

    if (!trackingId) {
      setError("Tracking ID is required.");
      return;
    }

    try {
      const response = await axios.get(`http://localhost:5001/api/track_fraud/${trackingId}`);
      onResponse(response.data);  // Display response in chat
      onClose();  // Close modal after response
    } catch (error) {
      setError("There was an error tracking the fraud status.");
      console.error("Error tracking fraud:", error);
    }
  };

  return (
    <div className="track-fraud-modal">
      <div className="track-fraud-form">
        <h2>Track Fraud Status</h2>
        <form onSubmit={handleSubmit}>
          <input
            type="text"
            placeholder="Enter Tracking ID"
            value={trackingId}
            onChange={handleTrackingIdChange}
            required
          />
          <button type="submit">Track</button>
          <button type="button" onClick={onClose}>Cancel</button>
        </form>
        {error && <p className="error-message">{error}</p>}
      </div>
    </div>
  );
}

export default TrackFraud;
