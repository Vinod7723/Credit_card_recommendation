# models/order_model.py
from pymongo import MongoClient
import os

# Connect to MongoDB - use service name in Kubernetes, localhost for local dev
mongo_host = os.environ.get("MONGO_HOST", "localhost")
client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = client["credit_card_assistant"]
orders_collection = db["orders"]


# Insert a new order into the orders collection
def create_order(order_data):
    orders_collection.insert_one(order_data)


# Delete an order from the orders collection by order number
def cancel_order(order_number):
    result = orders_collection.delete_one({"order_number": order_number})
    return result.deleted_count > 0  # Returns True if an order was deleted
