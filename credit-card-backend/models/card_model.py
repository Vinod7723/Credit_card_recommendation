# models/card_model.py
from pymongo import MongoClient

# Connect to MongoDB
client = MongoClient("mongodb://localhost:27017/")
db = client["credit_card_assistant"]
cards_collection = db["credit_cards"]


# Function to execute MongoDB query
def find_cards_by_query(query):
    try:
        # Execute the query and exclude _id
        return list(cards_collection.find(query, {"_id": 0}))
    except Exception as e:
        print("Error executing query:", e)
        return []
