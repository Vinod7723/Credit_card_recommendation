# order_agent.py
from pymongo import MongoClient
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate
import uuid
import json
import os

# MongoDB setup
client = MongoClient("mongodb://localhost:27017/")
db = client["credit_card_db"]
orders_collection_name = "orders"

# OpenAI setup
openai_api_key = os.environ.get("OPENAI_API_KEY")
llm = ChatOpenAI(openai_api_key=openai_api_key, model_name="gpt-4")

# Define LangChain Prompt for Inserting Order
insert_prompt = PromptTemplate(
    input_variables=["name", "address", "mobile", "card_name", "order_number"],
    template="""
Given the following order details:
- Name: {name}
- Address: {address}
- Mobile: {mobile}
- Card Name: {card_name}
- Order Number: {order_number}

Generate a MongoDB insert query to add these details to the `orders` collection.
Ensure the query is formatted as valid JSON in a dictionary format, like this:
{{
    "name": "{name}",
    "address": "{address}",
    "mobile": "{mobile}",
    "card_name": "{card_name}",
    "order_number": "{order_number}"
}}
Only output the JSON dictionary without any additional text.
"""
)

# Define LangChain Prompt for Cancelling Order
cancel_prompt = PromptTemplate(
    input_variables=["order_number"],
    template="""
Given the following order number:
- Order Number: {order_number}

Generate a MongoDB delete query to remove the order with this order number from the `orders` collection.
Ensure the query is formatted as valid JSON in a dictionary format, using the exact field name "order_number" like this:
{{
    "order_number": "{order_number}"
}}
Only output the JSON dictionary without any additional text.
"""
)

def ensure_collection_exists():
    """Ensure the orders collection exists in MongoDB."""
    if orders_collection_name not in db.list_collection_names():
        print("Orders collection does not exist. Creating it now...")
        db.create_collection(orders_collection_name)
        print("Orders collection created successfully.")

def create_order_with_openai(details):
    """Generate a MongoDB insert query using OpenAI and execute it."""
    ensure_collection_exists()  # Check and create the collection if needed

    order_number = str(uuid.uuid4().int)[:8]  # Generate a unique order number
    details["order_number"] = order_number

    # Use LangChain modern chain approach
    insert_chain = insert_prompt | llm

    # Generate MongoDB insert query with OpenAI
    response = insert_chain.invoke({
        "name": details["name"],
        "address": details["address"],
        "mobile": details["mobile"],
        "card_name": details["card_name"],
        "order_number": order_number
    })
    response = response.content
    
    # Print the response for debugging
    print("Generated Response from OpenAI for Insertion:", response)

    try:
        # Parse response as JSON
        mongo_query = json.loads(response)
        print("Generated MongoDB Insert Query:", mongo_query)
        
        # Execute the insert query
        result = db[orders_collection_name].insert_one(mongo_query)
        
        if result.inserted_id:
            print("Order successfully inserted into MongoDB:", mongo_query)
            return order_number
        else:
            print("Failed to insert order into MongoDB.")
            return None
    except json.JSONDecodeError as e:
        print("JSON decode error in generated query:", e)
        return None
    except Exception as e:
        print("Error generating or executing MongoDB query:", e)
        return None

def find_order_by_number(order_number):
    """Check if an order exists in MongoDB by order number and return it."""
    order = db[orders_collection_name].find_one({"order_number": order_number})
    if order:
        print(f"Order found: {order}")
    else:
        print(f"No order found with order number: {order_number}")
    return order

def cancel_order_with_openai(order_number):
    """Generate a MongoDB delete query using OpenAI and execute it."""
    # Check if the order exists before attempting to delete it
    if not find_order_by_number(order_number):
        print(f"Order {order_number} not found. Cancellation aborted.")
        return False
    else:
        print(f"Order {order_number} found.")
    
    # Use LangChain modern chain approach
    cancel_chain = cancel_prompt | llm

    # Generate MongoDB delete query with OpenAI
    response = cancel_chain.invoke({"order_number": order_number})
    response = response.content
    print("Generated Response for Cancellation from OpenAI:", response)

    try:
        # Parse response as JSON
        mongo_query = json.loads(response)
        print("Initial Generated MongoDB Delete Query:", mongo_query)
        
        # Check if the query has a top-level "$query" key and extract its content
        if "$query" in mongo_query:
            mongo_query = mongo_query["$query"]

        # Ensure the field name is "order_number" in the generated query
        if "Order Number" in mongo_query:
            mongo_query["order_number"] = mongo_query.pop("Order Number")
        elif "orderNumber" in mongo_query:
            mongo_query["order_number"] = mongo_query.pop("orderNumber")

        # Ensure `order_number` is a string to match MongoDB's stored data type
        mongo_query["order_number"] = str(mongo_query["order_number"])
        
        print("Corrected MongoDB Delete Query:", mongo_query)
        
        # Execute the delete query
        result = db[orders_collection_name].delete_one(mongo_query)
        
        if result.deleted_count > 0:
            print(f"Order {order_number} successfully deleted from MongoDB.")
            return True
        else:
            print(f"Order {order_number} not found in MongoDB.")
            return False
    except json.JSONDecodeError as e:
        print("JSON decode error in generated delete query:", e)
        return False
    except Exception as e:
        print("Error generating or executing MongoDB delete query:", e)
        return False
