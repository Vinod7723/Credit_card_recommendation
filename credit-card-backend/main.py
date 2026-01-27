from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
import traceback
import os
from config import generate_mongo_query
from models.card_model import find_cards_by_query
from order_agent import (
    create_order_with_openai,
    cancel_order_with_openai,
    find_order_by_number,
)
from defect_agent import report_defect, track_defect_status
from fraud_agent import report_fraud, track_fraud_status
import json

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# OpenAI API setup
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))


def detect_intent(message):
    """Uses OpenAI's GPT-4 chat model to detect the specific intent of the message."""
    try:
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": "You are an assistant that categorizes customer inquiries into one of the following intents: 'greeting', 'track order', 'cancel order', 'report defect', 'track defect', 'report fraud transaction', 'track fraud status', or 'other'. Classify general greetings like hi, hello, hey, good morning, good evening, etc. as 'greeting'. Classify messages about checking or tracking a defect report status as 'track defect'.",
                },
                {
                    "role": "user",
                    "content": f"Please categorize this message into 'greeting', 'track order', 'cancel order', 'report defect', 'track defect', 'report fraud transaction', 'track fraud status', or 'other': '{message}'.",
                },
            ],
        )

        intent_response = response.choices[0].message.content.strip().lower()
        print("Detected intent response:", intent_response)  # For debugging

        if "greeting" in intent_response:
            return "greeting_intent"
        elif "track defect" in intent_response:
            return "track_defect_intent"
        elif "track order" in intent_response:
            return "track_intent"
        elif "cancel order" in intent_response:
            return "cancel_intent"
        elif "report defect" in intent_response:
            return "report_defect_intent"
        elif "report fraud transaction" in intent_response:
            return "report_fraud_intent"
        elif "track fraud status" in intent_response:
            return "track_fraud_intent"
        else:
            return "other"
    except Exception as e:
        print("Error detecting intent:", e)
        return "error"


@app.route("/api/recommend", methods=["POST"])
def recommend():
    data = request.get_json()
    message = data.get("message")
    user_id = data.get("user_id", request.remote_addr)

    try:
        intent = detect_intent(message)

        # Handle specific intents
        if intent == "greeting_intent":
            return (
                jsonify(
                    {
                        "message": "Hello! Welcome to the Credit Card Recommendation System. I can help you with:\n- Recommending credit cards\n- Creating or canceling orders\n- Reporting defects or fraud\nHow can I assist you today?"
                    }
                ),
                200,
            )
        elif intent == "track_intent":
            return jsonify({"message": "track_intent"}), 200
        elif intent == "cancel_intent":
            return jsonify({"message": "cancel_intent"}), 200
        elif intent == "track_defect_intent":
            return jsonify({"message": "track_defect_intent"}), 200
        elif intent == "report_defect_intent":
            return jsonify({"message": "report_defect_intent"}), 200
        elif intent == "report_fraud_intent":
            return jsonify({"message": "report_fraud_intent"}), 200
        elif intent == "track_fraud_intent":
            return jsonify({"message": "track_fraud_intent"}), 200

        # Default recommendation intent
        mongo_query_str = generate_mongo_query(message)
        mongo_query = json.loads(mongo_query_str)
        recommended_cards = find_cards_by_query(mongo_query)

        if recommended_cards:
            return jsonify(recommended_cards), 200
        else:
            return jsonify({"message": "No matching cards found."}), 404
    except Exception as e:
        print("Error processing recommendation:", e)
        traceback.print_exc()  # Print detailed stack trace for debugging
        return jsonify({"message": "Error processing the recommendation request"}), 500


# Order creation endpoint
@app.route("/api/create_order", methods=["POST"])
def create_order_route():
    data = request.get_json()
    user_id = data.get("user_id", request.remote_addr)

    details = {
        "name": data.get("name"),
        "address": data.get("address"),
        "mobile": data.get("mobile"),
        "card_name": data.get("card_name"),
        "user_id": user_id,
    }

    try:
        order_number = create_order_with_openai(details)
        if order_number:
            return jsonify(
                {
                    "message": f"Order created successfully with order number {order_number}."
                }
            )
        else:
            return jsonify({"message": "Failed to create order."}), 500
    except Exception as e:
        print("Error in create_order_route:", e)
        return jsonify({"message": "Error processing the order request"}), 500


@app.route("/api/cancel_order", methods=["POST"])
def cancel_order_route():
    data = request.get_json()
    order_number = data.get("order_number")

    if not order_number:
        return jsonify({"message": "Please provide your order number to cancel."}), 400

    try:
        if cancel_order_with_openai(order_number):
            return jsonify(
                {"message": f"Order {order_number} has been successfully canceled."}
            )
        else:
            return jsonify({"message": f"Order {order_number} not found."}), 404
    except Exception as e:
        print("Error in cancel_order_route:", e)
        return jsonify({"message": "Error processing the cancellation request"}), 500


@app.route("/api/track_order/<order_number>", methods=["GET"])
def track_order_route(order_number):
    """Endpoint to track the status of an order based on the order number."""
    try:
        order_info = find_order_by_number(order_number)
        if order_info:
            return jsonify(order_info), 200
        else:
            return jsonify({"message": "Order not found"}), 404
    except Exception as e:
        print("Error in track_order_route:", e)
        return jsonify({"message": "Error tracking the order"}), 500


@app.route("/api/report_defect", methods=["POST"])
def report_defect_route():
    description = request.form.get("description")
    order_id = request.form.get("orderId")
    image = request.files.get("image")

    try:
        tracking_id = report_defect(description, order_id, image)
        return jsonify({"trackingId": tracking_id}), 200
    except Exception as e:
        print("Error in report_defect_route:", e)
        return jsonify({"message": "Error processing the defect report"}), 500


@app.route("/api/track_defect/<tracking_id>", methods=["GET"])
def track_defect_route(tracking_id):
    try:
        defect_info = track_defect_status(tracking_id)
        if defect_info:
            return jsonify(defect_info), 200
        else:
            return jsonify({"message": "Tracking ID not found"}), 404
    except Exception as e:
        print("Error in track_defect_route:", e)
        return jsonify({"message": "Error tracking the defect status"}), 500


@app.route("/api/report_fraud", methods=["POST"])
def report_fraud_route():
    """Endpoint for reporting a fraudulent transaction with OCR image and transaction details."""
    try:
        transaction_details = request.form.get("transaction_details")
        ocr_image = request.files.get("ocr_image")

        if not transaction_details or not ocr_image:
            return (
                jsonify({"message": "Transaction details and OCR image are required"}),
                400,
            )

        tracking_id = report_fraud(transaction_details, ocr_image)

        return jsonify({"trackingId": tracking_id}), 200

    except Exception as e:
        print("Error processing fraud report:", e)
        return jsonify({"message": "Error processing the fraud report"}), 500


@app.route("/api/track_fraud/<tracking_id>", methods=["GET"])
def track_fraud_route(tracking_id):
    """Endpoint to track the status of a fraud report based on the tracking ID."""
    try:
        fraud_report = track_fraud_status(tracking_id)
        if fraud_report:
            return jsonify(fraud_report), 200
        else:
            return jsonify({"message": "Tracking ID not found"}), 404
    except Exception as e:
        print("Error tracking fraud report:", e)
        return jsonify({"message": "Error tracking the fraud report"}), 500


@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint for container orchestration."""
    return jsonify({"status": "healthy", "service": "credit-card-backend"}), 200


if __name__ == "__main__":
    app.run(port=5001, debug=True)
