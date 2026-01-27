# db.py
from pymongo import MongoClient

# Hard-coded MongoDB URI
mongo_uri = "mongodb://localhost:27017"  # Adjust as needed for your MongoDB setup
client = MongoClient(mongo_uri)
db = client.creditCardDB  # Database name

# Collection for cards
cards_collection = db.cards
