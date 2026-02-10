# config.py
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate
import re  # Import regex for parsing
import os

# API key from environment variable
openai_api_key = os.environ.get("OPENAI_API_KEY")
llm = ChatOpenAI(openai_api_key=openai_api_key, model_name="gpt-4o-mini")


# Define a prompt template for generating MongoDB queries
template = """
You are a MongoDB query generator. Based on a user's message, create a MongoDB query to search for credit cards.

The credit card data has the following fields:
1. tier (e.g., "bronze", "silver", "gold", "diamond")
2. name (e.g., "Chase Starter Bronze", "Chase Rewards Silver")
3. issuer (e.g., "Chase Bank")
4. annual_fee (number, e.g., 0, 25, 95, 450)
5. interest_rate (number, e.g., 19.99, 17.99, 15.99)
6. credit_limit_min (number, minimum credit limit)
7. credit_limit_max (number, maximum credit limit)
8. rewards.cashback_percentage (number, e.g., 0.5, 1, 2, 3)
9. rewards.bonus_categories (array of objects with "category" and "multiplier", e.g., Travel, Dining, Groceries)
10. benefits (array of strings, e.g., ["Airport lounge access", "Travel insurance", "Concierge service"])
11. features (array of strings, e.g., ["Travel perks", "Premium rewards"])
12. is_active (boolean)
13. min_credit_score (number, minimum credit score required: 300-579 = Poor, 580-669 = Fair, 670-739 = Good, 740-799 = Very Good, 800-850 = Excellent)

Generate a MongoDB query in JSON format based on the user's request, using the following guidelines:
- Always include {{"is_active": true}} in the query.
- Match "tier" if the user mentions a tier level.
- For travel cards, search for "Travel" in rewards.bonus_categories.category or in features/benefits using $regex.
- For credit limit requests, use credit_limit_max with $gte.
- For annual fee preferences, use annual_fee with $lte for "low fee" or $eq: 0 for "no fee".
- For benefits, use "$regex" with "$options": "i" for case-insensitive matching.
- If user mentions their credit score (e.g., "my credit score is 720"), filter cards where min_credit_score is less than or equal to their score using {{"min_credit_score": {{"$lte": 720}}}}.
- Credit score categories: Poor (300-579), Fair (580-669), Good (670-739), Very Good (740-799), Excellent (800-850).
- If user says "poor credit" use 579, "fair credit" use 669, "good credit" use 739, "very good credit" use 799, "excellent credit" use 850.
- If the user request is general (e.g., "recommend a card"), return an empty query {{}} to show all cards.

Respond only with the JSON query format.

Message: {query}
MongoDB Query:
"""
prompt = PromptTemplate(input_variables=["query"], template=template)

# Create a chain using the pipe operator (modern langchain approach)
chain = prompt | llm


# Function to generate MongoDB query using LangChain
def generate_mongo_query(query):
    try:
        # Run the chain with the user query and return the MongoDB query string
        response = chain.invoke({"query": query})
        mongo_query = response.content
        print("Raw OpenAI Response:", mongo_query)  # Log the raw response

        # Use regex to extract only the JSON object between the ``` markers
        match = re.search(r"```json\s*({.*})\s*```", mongo_query, re.DOTALL)
        if match:
            mongo_query = match.group(1)

        print("Final MongoDB Query String:", mongo_query)
        return mongo_query
    except Exception as e:
        print("Error generating MongoDB query:", e)
        return None
