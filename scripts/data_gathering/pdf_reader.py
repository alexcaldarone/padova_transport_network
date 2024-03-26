import pathlib
import re
import tabula
import json
import os
import warnings

warnings.simplefilter('ignore')

# global variables
PATH = pathlib.Path.cwd()
PATH_TO_RAW_DATA = pathlib.Path(str(PATH) + "/data/raw") # raw data directory
PATH_TO_PDF_DATA = pathlib.Path(str(PATH_TO_RAW_DATA) + "/extraurbani_pdf")

SPECIAL_FORMAT_FILES = set(["E001_9", "E006", "E012-E013_V", "E013_2", "E019_1", "E021_8", "E024", "E031", "E035_2", "E038",
                           "E038_2", "E042", "E044", "E045", "E046", "E046_1", "E047", "E060_1", "E071_6",
                           "E073_1", "E098_2", "E098_3", "E098_4", "E101", "E103", "E105", "E192", "E066-E066Z"])
NUMBER_REGEX = r'\d+\.\d+'

def read_special_format(file_path):
    df = tabula.read_pdf(file_path, stream = True)[0]
    
    #print(file_path)
    #print(df)
    #print(df.columns)

    for col in df.columns:
        if "LINEA" in col or "Linea" in col or "Vettore" in col:
            fermate_col = col
            break
    
    #print(df[[fermate_col]])
    fermate_list = []
    for i, row in df[[fermate_col]].iterrows():
        if i > 2 and row[0] is not None:
            clean_row = re.sub(NUMBER_REGEX, "", row[0]).replace(".", "")
            fermate_list.append(clean_row)
    
    return fermate_list

def read_normal_format(file_path):
    if "LineaE035" in file_path: # problematic file
        df = tabula.read_pdf(file_path, stream = True, pages="2")[0]
    else:
        df = tabula.read_pdf(file_path, stream = True)[0]
    
    print(file_path)
    fermate_list = []
    for i in range(len(df.iloc[:, 0])):
        if i > 2:
            fermate_list.append(df.iloc[i, 0])
    
    return fermate_list

if __name__ == "__main__":
    dizionario_extraurbani = dict()

    for filename in os.listdir(PATH_TO_PDF_DATA):
        if filename[5:-4] in SPECIAL_FORMAT_FILES:
            dizionario_extraurbani[filename[:-4]] = read_special_format(f"{PATH_TO_PDF_DATA}/{filename}")
        else:
            dizionario_extraurbani[filename[:-4]] = read_normal_format(f"{PATH_TO_PDF_DATA}/{filename}")
    
    with open(f"{PATH_TO_RAW_DATA}/linee_extraurbane.json", "w") as f:
        json.dump(dizionario_extraurbani, f)