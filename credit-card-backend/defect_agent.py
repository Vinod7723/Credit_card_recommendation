from PIL import Image
from openai import OpenAI
from pymongo import MongoClient
from langchain_core.prompts import PromptTemplate
from langchain_openai import ChatOpenAI
import uuid
import os

# MongoDB setup
mongo_client = MongoClient("mongodb://localhost:27017/")
db = mongo_client["customer_support"]
defects_collection = db["defective_products"]

# OpenAI API setup
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
openai_client = OpenAI(api_key=OPENAI_API_KEY)

# LangChain LLM setup
llm = ChatOpenAI(openai_api_key=OPENAI_API_KEY, model_name="gpt-4")  # GPT-4 model

# LangChain Prompt for interpreting image analysis
decision_prompt = PromptTemplate(
    input_variables=["image_analysis", "description"],
    template="""
    A customer has reported a defect with the following details:
    
    Image Analysis: {image_analysis}
    Description: {description}
    
    Based on the image analysis and description, decide the appropriate action:
    Options are:
    - "Replacement Approved" for minor scratches or small damages.
    - "Refund Approved" for significant issues like completely damaged or broken parts.
    - "Escalate to Human" if the defect cannot be clearly identified or needs further review.

    Respond with the decision and a concise message for the customer.
    """
)

def report_defect(description, order_id, image):
    """Processes the defect report by analyzing the image and making a decision using GPT-4 vision and LangChain."""
    pil_image = Image.open(image).convert("RGB")
    image_analysis = analyze_defect_image(pil_image)  # Get image analysis from GPT-4
    decision, message = get_decision_with_llm(description, image_analysis)  # Decision by LangChain LLM

    # Generate a tracking ID for the defect report
    tracking_id = str(uuid.uuid4().int)[:8]

    # Store the defect report in MongoDB
    defect_record = {
        "trackingId": tracking_id,
        "description": description,
        "orderId": order_id,
        "decision": decision,
        "message": message
    }
    defects_collection.insert_one(defect_record)

    return tracking_id

def analyze_defect_image(image):
    """Uses OpenAI's GPT-4 with vision capabilities to analyze the defect image and return a description."""
    try:
        # Save the image temporarily
        temp_image_path = "temp_image.png"
        image.save(temp_image_path, format="PNG")
        
        with open(temp_image_path, "rb") as f:
            # Send image to GPT-4 and get response
            response = openai.Image.create(
                file=f,
                model="gpt-4-vision"
            )

        # Print the raw response from OpenAI for debugging
        print("Raw OpenAI Image Analysis Response:", response)

        # Extract textual analysis from GPT-4's response
        image_analysis = response['data'][0]['text']

        # Clean up temporary image file
        os.remove(temp_image_path)

        return image_analysis

    except Exception as e:
        print("Error analyzing defect image:", e)
        return "Image analysis failed. Please review the image manually."

def get_decision_with_llm(description, image_analysis):
    """Uses LangChain LLM to make a decision based on image analysis and description."""
    # Set up LangChain LLM chain with the decision prompt
    decision_chain = decision_prompt | llm

    # Run the prompt with image analysis and description
    result = decision_chain.invoke({"image_analysis": image_analysis, "description": description})
    response = result.content.strip()

    # Determine the decision and message from the LLM response
    if "Replacement Approved" in response:
        decision = "Replacement Approved"
    elif "Refund Approved" in response:
        decision = "Refund Approved"
    else:
        decision = "Escalate to Human"

    message = response  # Use the response as the message for the customer
    return decision, message

def track_defect_status(tracking_id):
    """Retrieves the defect status based on the tracking ID."""
    defect = defects_collection.find_one({"trackingId": tracking_id})
    if defect:
        return {
            "description": defect["description"],
            "orderId": defect["orderId"],
            "decision": defect["decision"],
            "message": defect["message"]
        }
    else:
        return None
