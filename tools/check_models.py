import os
import google.generativeai as genai

# Gemini API 키 직접 설정
GEMINI_API_KEY = "AIzaSyBudkuFMQkOdnhvU0NiEvVR2cHcN5Yabdc"
if GEMINI_API_KEY == "YOUR_GEMINI_API_KEY":
    print("Error: Please replace 'YOUR_GEMINI_API_KEY' with your actual API key.")
else:
    genai.configure(api_key=GEMINI_API_KEY)

    # 사용 가능한 모델 목록 출력
    print("Available Gemini Models:")
    try:
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                print(m.name)
    except Exception as e:
        print(f"An error occurred while listing models: {e}")