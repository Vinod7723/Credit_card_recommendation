// src/Defect.js
import React, { useState } from "react";
import axios from "axios";
import "./Defect.css";

function Defect({ onClose }) {
  const [defectDescription, setDefectDescription] = useState("");
  const [orderId, setOrderId] = useState("");
  const [defectImage, setDefectImage] = useState(null);
  const [trackingId, setTrackingId] = useState("");

  const handleImageChange = (e) => setDefectImage(e.target.files[0]);

  const handleSubmitDefect = async (e) => {
    e.preventDefault();
    const formData = new FormData();
    formData.append("description", defectDescription);
    formData.append("orderId", orderId);
    formData.append("image", defectImage);

    try {
      const response = await axios.post("http://localhost:5001/api/report_defect", formData);
      setTrackingId(response.data.trackingId);
      alert(`Defect reported successfully. Tracking ID: ${response.data.trackingId}`);
      onClose();
    } catch (error) {
      console.error("Error reporting defect:", error);
      alert("There was an error reporting the defect.");
    }
  };

  return (
    <div className="defect-report-modal">
      <div className="defect-report-form">
        <h2>Report a Defective Product</h2>
        <form onSubmit={handleSubmitDefect}>
          <input
            type="text"
            placeholder="Enter Order ID"
            value={orderId}
            onChange={(e) => setOrderId(e.target.value)}
            required
          />
          <textarea
            placeholder="Describe the defect (e.g., broken card, missing CVV)"
            value={defectDescription}
            onChange={(e) => setDefectDescription(e.target.value)}
            required
          />
          <input type="file" accept="image/*" onChange={handleImageChange} required />
          <button type="submit">Submit Defect Report</button>
        </form>

        {trackingId && <p>Your tracking ID: {trackingId}</p>}

        <button onClick={onClose} className="close-btn">Close</button>
      </div>
    </div>
  );
}

export default Defect;
