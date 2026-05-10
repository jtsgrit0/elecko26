import os
import fitz  # PyMuPDF
import json
from PIL import Image
import io

def extract_images_from_pdfs():
    pdf_dir = 'assets/pdf'
    output_dir = 'assets/images/candidates'
    mapping_file = 'assets/pdf/pdf_filename_mapping.json'

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    with open(mapping_file, 'r', encoding='utf-8') as f:
        filename_mapping = json.load(f)

    # Create a reverse mapping from new filename to original filename
    reverse_mapping = {v: k for k, v in filename_mapping.items()}

    for pdf_file in os.listdir(pdf_dir):
        if pdf_file.endswith('.pdf'):
            try:
                # Get original filename from reverse mapping
                original_filename = reverse_mapping.get(pdf_file)
                if not original_filename:
                    print(f"Warning: No mapping found for {pdf_file}")
                    continue

                # Extract candidate ID from the original filename
                candidate_id = os.path.splitext(original_filename)[0]

                pdf_path = os.path.join(pdf_dir, pdf_file)
                doc = fitz.open(pdf_path)

                # Look for the largest image on the first page, likely the candidate's photo
                max_image_size = 0
                best_image_info = None

                for img_info in doc.get_page_images(0):
                    xref = img_info[0]
                    base_image = doc.extract_image(xref)
                    image_bytes = base_image["image"]
                    
                    # Check image size
                    image = Image.open(io.BytesIO(image_bytes))
                    width, height = image.size
                    image_size = width * height

                    if image_size > max_image_size:
                        max_image_size = image_size
                        best_image_info = base_image

                if best_image_info:
                    image_bytes = best_image_info["image"]
                    image_ext = best_image_info["ext"]
                    output_filename = f"{candidate_id}.{image_ext}"
                    output_path = os.path.join(output_dir, output_filename)

                    with open(output_path, "wb") as img_file:
                        img_file.write(image_bytes)
                    print(f"Extracted image for {candidate_id} to {output_path}")

                doc.close()

            except Exception as e:
                print(f"Error processing {pdf_file}: {e}")

if __name__ == "__main__":
    extract_images_from_pdfs()