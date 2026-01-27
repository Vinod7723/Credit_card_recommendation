// src/FraudTransaction.js
import React, { useState } from "react";
import axios from "axios";
import API_BASE_URL from "./config";
import "./FraudTransaction.css"; // For styling

function FraudTransaction({ onClose, onResponse }) {
  const [transactionDetails, setTransactionDetails] = useState("");
  const [ocrImage, setOcrImage] = useState(null);
  const [error, setError] = useState(null);

  const handleDetailsChange = (e) => setTransactionDetails(e.target.value);
  const handleImageChange = (e) => setOcrImage(e.target.files[0]);

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
      onResponse(response.data);  // Pass response to App.js to display in chat
      onClose();  // Close the modal
    } catch (error) {
      setError("There was an error reporting the fraudulent transaction.");
      console.error("Error reporting fraud:", error);
    }
  };

  return (
    <div className="fraud-transaction-modal">
      <div className="fraud-transaction-form">
        <h2>Report Fraudulent Transaction</h2>
        <form onSubmit={handleSubmit}>
          <textarea
            placeholder="Enter transaction details"
            value={transactionDetails}
            onChange={handleDetailsChange}
            required
          />
          <input
            type="file"
            accept="image/*"
            onChange={handleImageChange}
            required
          />
          <button type="submit">Submit</button>
          <button type="button" onClick={onClose}>Cancel</button>
        </form>
        {error && <p className="error-message">{error}</p>}
      </div>
    </div>
  );
}

export default FraudTransaction;
