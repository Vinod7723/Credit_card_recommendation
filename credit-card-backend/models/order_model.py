# models/order_model.py
from pymongo import MongoClient

# Connect to MongoDB
client = MongoClient("mongodb://localhost:27017/")
db = client["creditCardDB"]
orders_collection = db["orders"]


# Insert a new order into the orders collection
def create_order(order_data):
    orders_collection.insert_one(order_data)


# Delete an order from the orders collection by order number
def cancel_order(order_number):
    result = orders_collection.delete_one({"order_number": order_number})
    return result.deleted_count > 0  # Returns True if an order was deleted
