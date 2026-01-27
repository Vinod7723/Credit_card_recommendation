# models/card_model.py
from pymongo import MongoClient
import os

# Connect to MongoDB - use service name in Kubernetes, localhost for local dev
mongo_host = os.environ.get("MONGO_HOST", "localhost")
client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = client["credit_card_assistant"]
cards_collection = db["creditcards"]


# Function to execute MongoDB query
def find_cards_by_query(query):
    try:
        # Execute the query and exclude _id
        return list(cards_collection.find(query, {"_id": 0}))
    except Exception as e:
        print("Error executing query:", e)
        return []
