// src/ChatMessage.js
import React from "react";
import CardList from "./CardList";
import "./ChatMessage.css";

function ChatMessage({ message, onBuy, onCancel }) {
  return (
    <div className={`chat-message ${message.type === "user" ? "user-message" : "bot-message"}`}>
      {message.text && <p>{message.text}</p>}
      {message.cards && <CardList cards={message.cards} onBuy={onBuy} onCancel={onCancel} />}
    </div>
  );
}

export default ChatMessage;
