#!/usr/bin/env python3
"""
후보자 이미지 일괄 리사이즈 스크립트.
assets/images/candidates/ 내부의 수많은 PNG 파일들을
최대 가로/세로 150px로 줄이고 압축하여 
assets/images/compressed_candidates/에 저장합니다.
"""

import os
from pathlib import Path
from PIL import Image
import concurrent.futures

def process_image(src_path, dst_path):
    try:
        if os.path.exists(dst_path):
            return 1 # already processed
            
        with Image.open(src_path) as img:
            # 리사이즈
            img.thumbnail((150, 150), Image.Resampling.LANCZOS)
            
            # P 모드(팔레트) 256색으로 변환하여 PNG 용량을 획기적으로 줄임
            img = img.convert("P", palette=Image.ADAPTIVE, colors=256)
            
            # 저장
            img.save(dst_path, format="PNG", optimize=True)
            return 0
    except Exception as e:
        print(f"Error processing {src_path.name}: {e}")
        return -1

def main():
    root_dir = Path(__file__).parent.parent
    src_dir = root_dir / 'assets' / 'images' / 'candidates'
    dst_dir = root_dir / 'assets' / 'images' / 'compressed_candidates'
    
    dst_dir.mkdir(parents=True, exist_ok=True)
    
    png_files = list(src_dir.glob('*.png'))
    total = len(png_files)
    print(f"총 {total}개의 이미지를 리사이징 및 압축합니다...")
    
    tasks = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as executor:
        for p in png_files:
            tasks.append(
                executor.submit(process_image, p, dst_dir / p.name)
            )
            
        done_count = 0
        for future in concurrent.futures.as_completed(tasks):
            res = future.result()
            if res == 0 or res == 1:
                done_count += 1
            if done_count % 1000 == 0:
                print(f"진행 상황: {done_count} / {total} 완료")
                
    print("모든 이미지 압축 완료!")
    
    # 용량 확인
    import subprocess
    subprocess.run(['du', '-sh', str(dst_dir)])

if __name__ == "__main__":
    main()
