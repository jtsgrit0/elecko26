import pandas as pd
import sys
import json

filename = sys.argv[1]
try:
    xl = pd.ExcelFile(filename)
    print(f"Sheet names: {xl.sheet_names}")
    for sheet in xl.sheet_names[:2]: # Check first 2 sheets
        df = xl.parse(sheet, nrows=10)
        print(f"--- Sheet: {sheet} ---")
        print(df.head())
except Exception as e:
    print(f"Error: {e}")
