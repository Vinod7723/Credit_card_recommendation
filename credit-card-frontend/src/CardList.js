// src/CardList.js
import React from "react";
import "./CardList.css";

function CardList({ cards, onBuy, onCancel }) {
  return (
    <div className="card-list">
      {cards.map((card, index) => (
        <div key={index} className="card-item">
          <div className={`card-tier-banner tier-${card.tier}`}>
            {card.tier?.toUpperCase()}
          </div>
          <div className="card-details">
            <h3>{card.name}</h3>
            <p className="card-issuer">{card.issuer}</p>
            <p className="card-description">{card.description}</p>
            <div className="card-info-grid">
              <div className="card-info-item">
                <span className="info-label">Annual Fee</span>
                <span className="info-value">${card.annual_fee}</span>
              </div>
              <div className="card-info-item">
                <span className="info-label">APR</span>
                <span className="info-value">{card.interest_rate}%</span>
              </div>
              <div className="card-info-item">
                <span className="info-label">Credit Limit</span>
                <span className="info-value">${card.credit_limit_min?.toLocaleString()} - ${card.credit_limit_max?.toLocaleString()}</span>
              </div>
              <div className="card-info-item">
                <span className="info-label">Cashback</span>
                <span className="info-value">{card.rewards?.cashback_percentage}%</span>
              </div>
            </div>
            {card.rewards?.bonus_categories?.length > 0 && (
              <div className="card-bonus">
                <span className="info-label">Bonus Categories: </span>
                {card.rewards.bonus_categories.map((cat, i) => (
                  <span key={i} className="bonus-badge">{cat.category} {cat.multiplier}x</span>
                ))}
              </div>
            )}
            <div className="card-benefits">
              <span className="info-label">Key Benefits:</span>
              <ul>
                {card.benefits?.slice(0, 4).map((benefit, i) => (
                  <li key={i}>{benefit}</li>
                ))}
              </ul>
            </div>
          </div>
          <div className="card-actions">
            <button onClick={() => onBuy(card)}>Apply Now</button>
          </div>
        </div>
      ))}
    </div>
  );
}

export default CardList;
