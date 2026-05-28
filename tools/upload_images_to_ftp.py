#!/usr/bin/env python3
"""
압축된 후보자 이미지를 Dothome FTP 서버에 멀티스레드로 업로드합니다.
"""

import os
import ftplib
import concurrent.futures
from pathlib import Path
from queue import Queue

FTP_HOST = "112.175.185.131"
FTP_USER = "jtsgrit0"
FTP_PASS = "Ggdrecon3534@!"
FTP_DIR = "/html/images/candidates"
MAX_WORKERS = 5  # Dothome FTP 동시 접속 제한 고려

def upload_worker(file_queue, progress_queue):
    # 각 스레드마다 독립적인 FTP 연결 생성
    ftp = ftplib.FTP()
    try:
        ftp.connect(FTP_HOST, 21, timeout=30)
        ftp.login(FTP_USER, FTP_PASS)
        # 패시브 모드 강제
        ftp.set_pasv(True)
        # 대상 폴더로 이동 (없으면 에러가 날 수 있으므로 주의, 메인에서 미리 생성함)
        ftp.cwd(FTP_DIR)
        
        while not file_queue.empty():
            try:
                file_path = file_queue.get_nowait()
            except Exception:
                break
                
            filename = file_path.name
            
            # 파일이 이미 존재하는지 확인하려면 ftp.size()를 쓸 수 있으나 느림
            # 그냥 무조건 덮어쓰기 업로드
            try:
                with open(file_path, 'rb') as f:
                    ftp.storbinary(f'STOR {filename}', f, blocksize=8192)
                progress_queue.put(1) # 성공
            except Exception as e:
                # 에러 발생 시 큐에 다시 넣지 않고 무시하거나 기록
                progress_queue.put(f"Error uploading {filename}: {e}")
                
            file_queue.task_done()
            
    except Exception as e:
        progress_queue.put(f"Worker connection error: {e}")
    finally:
        try:
            ftp.quit()
        except:
            ftp.close()

def ensure_ftp_directory():
    ftp = ftplib.FTP(FTP_HOST, FTP_USER, FTP_PASS)
    ftp.set_pasv(True)
    
    # /html 디렉토리로 이동
    ftp.cwd("/html")
    
    # images 폴더 확인 및 생성
    if "images" not in ftp.nlst():
        ftp.mkd("images")
    ftp.cwd("images")
    
    # candidates 폴더 확인 및 생성
    if "candidates" not in ftp.nlst():
        ftp.mkd("candidates")
        
    ftp.quit()
    print("FTP 디렉토리 확인 및 생성 완료: /html/images/candidates")

import json

def main():
    root_dir = Path(__file__).parent.parent
    src_dir = root_dir / 'assets' / 'images' / 'compressed_candidates'
    json_path = root_dir / 'assets' / 'data' / 'election_candidates.json'
    
    if not src_dir.exists():
        print(f"소스 디렉토리가 없습니다: {src_dir}")
        return
        
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    required_files = set()
    for c in data:
        url = c.get('imageUrl')
        if url:
            filename = url.split('/')[-1]
            required_files.add(filename)
            
    print(f"JSON에 등록된 이미지 수: {len(required_files)}")
    
    files = []
    for f in src_dir.glob('*.png'):
        if f.name in required_files:
            files.append(f)
            
    total_files = len(files)
    
    if total_files == 0:
        print("업로드할 파일이 없습니다.")
        return
        
    print(f"총 {total_files}개의 파일 업로드 준비 중...")
    
    try:
        ensure_ftp_directory()
    except Exception as e:
        print(f"FTP 디렉토리 생성 실패: {e}")
        return
        
    # Queue 설정
    file_queue = Queue()
    for f in files:
        file_queue.put(f)
        
    progress_queue = Queue()
    
    # 스레드 풀 실행
    print(f"{MAX_WORKERS}개의 워커로 FTP 업로드 시작...")
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = [executor.submit(upload_worker, file_queue, progress_queue) for _ in range(MAX_WORKERS)]
        
        uploaded = 0
        errors = 0
        
        # 진행 상황 모니터링
        while uploaded + errors < total_files:
            try:
                res = progress_queue.get(timeout=5)
                if res == 1:
                    uploaded += 1
                    if uploaded % 500 == 0:
                        print(f"진행: {uploaded}/{total_files} (에러: {errors})")
                else:
                    errors += 1
                    print(res)
            except Exception:
                # 큐가 비어있고 timeout 발생 시 스레드가 죽었는지 확인
                if all(f.done() for f in futures):
                    break
                    
    print(f"\n업로드 완료! 성공: {uploaded}, 실패: {errors}")

if __name__ == "__main__":
    main()
