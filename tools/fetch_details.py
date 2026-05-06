
import asyncio
import os
from playwright.async_api import async_playwright, TimeoutError as PlaywrightTimeoutError

async def main():
    pdf_output_dir = "nec_pdfs"
    os.makedirs(pdf_output_dir, exist_ok=True)
    print(f"Playwright를 사용하여 'PDF 다운' 버튼을 클릭해 파일을 저장합니다. (저장 폴더: {pdf_output_dir})")

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()

        try:
            # 1. 사용자가 알려준 정확한 URL로 접속
            url = "https://info.nec.go.kr/electioninfo/electionInfo_report.xhtml"
            await page.goto(url, timeout=60000)
            print(f"올바른 시작 주소({url})로 접속했습니다.")

            # 2. 선거 종류 선택
            election_select_selector = "#electionId"
            await page.wait_for_selector(election_select_selector, timeout=20000)
            election_options = await page.query_selector_all(f"{election_select_selector} > option")
            
            election_info_list = []
            for option in election_options:
                value = await option.get_attribute("value")
                text = (await option.inner_text()).strip()
                if value and value not in ["", "0"]:
                    election_info_list.append({'value': value, 'name': text})

            print(f"{len(election_info_list)}개의 선거 종류를 발견했습니다.")

            for election_info in election_info_list:
                election_name = election_info['name']
                election_value = election_info['value']
                
                print(f"\n{'='*20}\n선거 종류: '{election_name}' 처리 시작\n{'='*20}")
                await page.select_option(election_select_selector, election_value)
                await page.wait_for_timeout(1000) # 시/도 목록 변경 대기

                # 3. 시/도 선택
                city_select_selector = "#cityCode"
                await page.wait_for_selector(city_select_selector, timeout=20000)
                city_options = await page.query_selector_all(f"{city_select_selector} > option")
                
                city_info_list = []
                for option in city_options:
                    value = await option.get_attribute("value")
                    text = (await option.inner_text()).strip()
                    if value and value != "0":
                        city_info_list.append({'value': value, 'name': text})
                
                if not city_info_list:
                    print(f"  '{election_name}' 선거에는 선택할 시/도가 없습니다. 건너뜁니다.")
                    continue

                for city_info in city_info_list:
                    city_name = city_info['name']
                    city_value = city_info['value']
                    
                    print(f"--- '{city_name}' 지역의 PDF를 다운로드합니다. ---")
                    await page.select_option(city_select_selector, city_value)
                    await page.wait_for_timeout(500)

                    # 4. 검색 버튼 클릭
                    await page.click("#searchBtn")
                    await page.wait_for_load_state("networkidle", timeout=30000)
                    await page.wait_for_timeout(2000) # 결과 테이블 렌더링 대기

                    try:
                        # 5. "PDF 다운" 버튼 클릭 및 파일 저장
                        pdf_button_selector = 'text="PDF 다운"'
                        await page.wait_for_selector(pdf_button_selector, timeout=10000)

                        async with page.expect_download() as download_info:
                            await page.click(pdf_button_selector)
                        
                        download = await download_info.value
                        
                        safe_election_name = election_name.replace('/', '_')
                        safe_city_name = city_name.replace('/', '_')
                        pdf_filename = os.path.join(pdf_output_dir, f"{safe_election_name}_{safe_city_name}.pdf")
                        
                        await download.save_as(pdf_filename)
                        print(f"  [성공] '{pdf_filename}' 파일로 저장했습니다.")

                    except PlaywrightTimeoutError:
                        print(f"  [정보] '{city_name}' 지역에는 'PDF 다운' 버튼이 없거나 조회할 데이터가 없습니다.")
                    except Exception as e:
                        print(f"  [실패] PDF 다운로드 중 오류 발생: {e}")

            print(f"\n\n모든 작업 완료. PDF 파일들이 '{pdf_output_dir}' 폴더에 저장되었습니다.")

        except Exception as e:
            print(f"스크립트 실행 중 치명적인 오류가 발생했습니다: {e}")
        finally:
            await browser.close()
            print("작업이 완료되어 브라우저를 닫았습니다.")

if __name__ == '__main__':
    asyncio.run(main())