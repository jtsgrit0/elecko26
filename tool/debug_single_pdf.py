#!/usr/bin/env python3
from pathlib import Path
from PyPDF2 import PdfReader
import os

def main():
    pdf_dir = Path("../assets/elec_pdf")
    pdf_files = list(pdf_dir.glob("*.pdf"))
    
    if not pdf_files:
        print("No PDF files found")
        return
    
    # 첫 번째 PDF 파일 선택
    first_pdf = pdf_files[0]
    print(f"Analyzing first PDF file: {first_pdf.name}")
    print("-" * 80)
    
    try:
        reader = PdfReader(first_pdf)
        print(f"Total pages: {len(reader.pages)}")
        print("-" * 80)
        
        # 첫 3페이지의 텍스트만 출력하여 형식 확인
        for page_num, page in enumerate(reader.pages[:3]):
            print(f"\n--- Page {page_num + 1} ---")
            text = page.extract_text()
            if text:
                print(text)
            else:
                print("(No text extracted from this page)")
    
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()