
import os
from pypdf import PdfReader

def main():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    # 분석할 특정 파일 지정
    pdf_file_name = '[제9회_전국동시지방선거]_예비후보자_명부[시·도지사선거][전북특별자치도].pdf'
    pdf_path = os.path.join(project_root, pdf_file_name)

    if not os.path.exists(pdf_path):
        print(f"File not found: {pdf_path}")
        return

    print(f"--- Analyzing raw text from: {pdf_file_name} ---")

    try:
        reader = PdfReader(pdf_path)
        full_text = ""
        for i, page in enumerate(reader.pages):
            text = page.extract_text() or ""
            full_text += f"\n--- Page {i+1} ---\n{text}"
        
        # 가공하지 않은 전체 텍스트를 그대로 출력
        print(full_text)

    except Exception as e:
        print(f"Error processing {pdf_path}: {e}")

if __name__ == '__main__':
    main()