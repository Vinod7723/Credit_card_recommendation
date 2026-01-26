// src/OrderForm.js
import React, { useState } from "react";
import axios from "axios";

function OrderForm({ card, onOrderComplete }) {
  const [formData, setFormData] = useState({
    name: "",
    address: "",
    mobile: "",
  });
  const [orderNumber, setOrderNumber] = useState(null);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await axios.post("http://localhost:5001/api/create_order", {
        ...formData,
        card_name: card.card_name, // Pass the card name for the order
      });
      setOrderNumber(response.data.orderNumber); // Set the generated order number
      onOrderComplete(); // Notify parent component about order completion
    } catch (error) {
      console.error("Error creating order:", error);
    }
  };

  return (
    <div className="order-form">
      <h3>Enter your details for {card.card_name}</h3>
      <form onSubmit={handleSubmit}>
        <input type="text" name="name" placeholder="Name" value={formData.name} onChange={handleChange} required />
        <input type="text" name="address" placeholder="Shipping Address" value={formData.address} onChange={handleChange} required />
        <input type="text" name="mobile" placeholder="Mobile Number" value={formData.mobile} onChange={handleChange} required />
        <button type="submit">Submit Details</button>
      </form>
      {orderNumber && <p>Your order number: {orderNumber}</p>}
    </div>
  );
}

export default OrderForm;
