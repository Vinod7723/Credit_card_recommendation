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
1. category (e.g., cashback, foodies, travel, lifestyle)
2. credit_limit (an array of credit limits available for the card, e.g., [500, 1000, 2000, 3000])
3. benefits (an array of benefits, e.g., ["no annual fee", "cashback on groceries"])
4. vendor (e.g., Chase, Discover, Bank of America, Wells Fargo)

Generate a MongoDB query in JSON format based on the user's request, using the following guidelines:
- Match the "category" field if specified.
- Match the "vendor" field if specified.
- For "credit_limit", use $elemMatch to check if any of the values in the array are greater than or equal to the requested limit.
- For "benefits", use "$and" with separate "$regex" patterns for each requested benefit, as MongoDB does not allow $regex inside $all.

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
        match = re.search(r'```json\s*({.*})\s*```', mongo_query, re.DOTALL)
        if match:
            mongo_query = match.group(1)

        print("Final MongoDB Query String:", mongo_query)
        return mongo_query
    except Exception as e:
        print("Error generating MongoDB query:", e)
        return None
