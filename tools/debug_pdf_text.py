import os
from pypdf import PdfReader

def debug_pdf(pdf_path):
    try:
        reader = PdfReader(pdf_path, strict=False)
        print(f"--- Text from {os.path.basename(pdf_path)} ---")
        for i, page in enumerate(reader.pages):
            text = page.extract_text()
            print(f"--- Page {i+1} ---")
            print(text)
            print("--------------------\n")
    except Exception as e:
        print(f"Error reading {pdf_path}: {e}")

if __name__ == "__main__":
    # 디버깅하고 싶은 PDF 파일 경로를 지정하세요.
    # 사용 가능한 파일 목록을 참고하여 정확한 경로를 입력해야 합니다.
    target_pdf = "assets/pdf/[제9회_전국동시지방선거]_예비후보자_명부[구·시·군의_장선거][경기도][고양시].pdf"
    
    # 프로젝트 루트를 기준으로 파일 경로 구성
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pdf_full_path = os.path.join(project_root, target_pdf)

    if os.path.exists(pdf_full_path):
        debug_pdf(pdf_full_path)
    else:
        print(f"File not found: {pdf_full_path}")
        print("Please check the file path and name.")