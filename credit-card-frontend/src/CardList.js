// src/CardList.js
import React from "react";
import "./CardList.css";

function CardList({ cards, onBuy, onCancel }) {
  return (
    <div className="card-list">
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

export default CardList;
