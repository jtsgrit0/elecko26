import pandas as pd
import sys
import json

filename = sys.argv[1]
xl = pd.ExcelFile(filename)
df = xl.parse('구·시·군의장', header=None, nrows=20)
print(df.to_json(orient='records', force_ascii=False))
