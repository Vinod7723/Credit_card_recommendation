// src/CardRecommendations.js
import React from "react";
import "./CardRecommendations.css";

function CardRecommendations({ cards, onBuy, onCancel }) {
  return (
    <div className="card-recommendations">
      {cards.map((card, index) => (
        <div key={index} className="card-item">
          <img src={card.image_url} alt={card.card_name} className="card-image" />
          <div className="card-details">
            <h3>{card.card_name}</h3>
            <p>Category: {card.category}</p>
            <p>Vendor: {card.vendor}</p>
            <p>APR: {card.APR}%</p>
            <p>Benefits: {card.benefits.join(", ")}</p>
          </div>
          <div className="card-actions">
            <button onClick={() => onBuy(card)}>Buy</button>
            
          </div>
        </div>
      ))}
    </div>
  );
}

export default CardRecommendations;
