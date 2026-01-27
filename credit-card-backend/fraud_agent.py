# fraud_agent.py
import uuid
import os
from PIL import Image
import pytesseract
from pymongo import MongoClient
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate

# MongoDB setup - use service name in Kubernetes, localhost for local dev
mongo_host = os.environ.get("MONGO_HOST", "localhost")
client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = client["credit_card_assistant"]
fraud_reports_collection = db["fraud_reports"]

# Set up OpenAI model with LangChain
llm = ChatOpenAI(openai_api_key=os.environ.get("OPENAI_API_KEY"), model_name="gpt-4")


# Define LangChain prompt templates for fraud report and fraud track
fraud_report_prompt = PromptTemplate(
    input_variables=["ocr_text", "transaction_details"],
    template="""
    A customer reported a potentially fraudulent transaction on their credit card.
    OCR Data: "{ocr_text}"
    Transaction Details: "{transaction_details}"

    Decide the appropriate action:
    - "Refund" if unauthorized or incorrect.
    - "Decline" if it's valid.
    - "Escalate to Human-Agent" if unclear.

    Respond with one option only.
    """,
)

fraud_track_prompt = PromptTemplate(
    input_variables=["tracking_id", "transaction_details"],
    template="""
    A customer is checking the status of a previously reported fraudulent transaction.
    Tracking ID: "{tracking_id}"
    Transaction Details: "{transaction_details}"

    Retrieve the decision made on this report and provide it to the customer.
    """,
)


def extract_text_from_image(image_file):
    """Extracts text from an OCR image using Tesseract."""
    image = Image.open(image_file)
    ocr_text = pytesseract.image_to_string(image)
    return ocr_text


def analyze_fraudulent_transaction(ocr_text, transaction_details):
    """Uses LangChain LLM chain to analyze OCR text and transaction details."""
    fraud_chain = fraud_report_prompt | llm
    result = fraud_chain.invoke(
        {"ocr_text": ocr_text, "transaction_details": transaction_details}
    )
    decision = result.content.strip()
    return decision


def report_fraud(transaction_details, ocr_image):
    """Processes fraud report with OCR and LangChain-based AI decision-making."""
    ocr_text = extract_text_from_image(ocr_image)
    decision = analyze_fraudulent_transaction(ocr_text, transaction_details)

    tracking_id = str(uuid.uuid4().int)[:8]
    fraud_report = {
        "trackingId": tracking_id,
        "transactionDetails": transaction_details,
        "ocrText": ocr_text,
        "decision": decision,
    }
    fraud_reports_collection.insert_one(fraud_report)

    return tracking_id


def track_fraud_status(tracking_id):
    """Retrieves fraud report details by tracking ID."""
    fraud_report = fraud_reports_collection.find_one({"trackingId": tracking_id})
    if fraud_report:
        decision = fraud_report["decision"]
        transaction_details = fraud_report["transactionDetails"]

        # Use the fraud_track_prompt to construct a response
        fraud_track_chain = fraud_track_prompt | llm
        result = fraud_track_chain.invoke(
            {"tracking_id": tracking_id, "transaction_details": transaction_details}
        )
        response = result.content.strip()

        return {
            "transactionDetails": transaction_details,
            "ocrText": fraud_report["ocrText"],
            "decision": decision,
            "response": response,
        }
    return None
