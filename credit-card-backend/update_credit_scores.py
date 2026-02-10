# update_credit_scores.py
# Script to add min_credit_score field to existing credit cards in MongoDB
from pymongo import MongoClient
import os

# Connect to MongoDB
mongo_host = os.environ.get("MONGO_HOST", "localhost")
client = MongoClient(f"mongodb://{mongo_host}:27017/")
db = client["credit_card_assistant"]
cards_collection = db["creditcards"]

# Credit score requirements by tier
# Bronze: Poor to Fair credit (300-669) -> min 300
# Silver: Fair to Good credit (580-739) -> min 580
# Gold: Good to Very Good credit (670-799) -> min 670
# Diamond: Very Good to Excellent credit (740-850) -> min 740

tier_credit_scores = {
    "bronze": 300,   # Poor credit acceptable
    "silver": 580,   # Fair credit required
    "gold": 670,     # Good credit required
    "diamond": 740,  # Very Good credit required
}

def update_credit_scores():
    """Update all cards with min_credit_score based on their tier"""
    print("Starting credit score update...")

    # Get all cards
    cards = list(cards_collection.find({}))
    print(f"Found {len(cards)} cards to update")

    updated_count = 0
    for card in cards:
        tier = card.get("tier", "bronze").lower()
        min_score = tier_credit_scores.get(tier, 580)

        # Update the card with min_credit_score
        result = cards_collection.update_one(
            {"_id": card["_id"]},
            {"$set": {"min_credit_score": min_score}}
        )

        if result.modified_count > 0:
            updated_count += 1
            print(f"Updated {card.get('name', 'Unknown')} ({tier}) -> min_credit_score: {min_score}")

    print(f"\nUpdate complete! {updated_count} cards updated with credit score requirements.")

    # Verify the update
    print("\nVerification - Cards with credit scores:")
    for card in cards_collection.find({}, {"name": 1, "tier": 1, "min_credit_score": 1}):
        print(f"  {card.get('name')}: {card.get('tier')} tier, min score: {card.get('min_credit_score')}")

if __name__ == "__main__":
    update_credit_scores()
