import json
import os
import pathlib
from collections import OrderedDict
import re
from sklearn.pipeline import Pipeline, FunctionTransformer

PATH = pathlib.Path.cwd() # directory from which file is called
PATH_TO_RAW_DATA = pathlib.Path(str(PATH) + "/data/raw") # raw data directory
PATH_TO_CLEAN_DATA = pathlib.Path(str(PATH) + "/data/clean") # clean data directory

def remove_white_spaces(dictionary):
    # removes white spaces at the beginning and end of a string
    # e trasforma la stinga in lowercase
    # rimuove i punti duplicati
    for linea, fermate in dictionary.items():
        dictionary[linea] = [fer.strip().lower().replace(" . ", "")  for fer in fermate]
    
    return dictionary

def remove_na(dictionary):
    for linea, fermate in dictionary.items():
        dictionary[linea] = [fer for fer in fermate if str(fer) != "nan" and fer != "."]
    
    return dictionary

def remove_duplicates_from_list(dictionary):
    # rimuove valori duplicati
    for linea, fermate in dictionary.items():
        dictionary[linea] = list(OrderedDict.fromkeys(fermate))
    
    return dictionary

def remove_numbers(dictionary):
    number_regex = r'\d+\.\d+'
    for linea, fermate in dictionary.items():
        dictionary[linea] = [re.sub(number_regex, "", fer) for fer in fermate]
    
    return dictionary

def correct_abbreviations(dictionary, orari_urbani = False):
    # standardizing text across all files
    dizionario_riferimento = {
        "austazione padova": "padova autostazione ",
        "v.": " via ",
        "v": "via ",
        "riv.": "riv ",
        "riviera": "riv ",
        "p.le": "piazzale ",
        "p.te": "ponte",
        "p.": "piazzale ",
        "p.zza": "piazza ",
        "p.ta ": "porta ",
        "s.": "san ",
        "v.le": "viale ",
        "staz fs": "stazione fs",
        "staz. fs": "stazione fs",
        "ist": " istituto ",
        "ist.": " istituto ",
        "s.p": "strada provinciale",
        "v.le": "viale",
        "vle": "viale"
    }
    for linea, fermate in dictionary.items():
        for i in range(len(fermate)):
            for el in dizionario_riferimento.keys():
                fermate[i] = re.sub(rf"\b{el}\b", dizionario_riferimento[el], fermate[i])
    
    # aggiungi padova davanti ai nomi delle vie per render uguali a quelli degli orari extraurbani
    if orari_urbani:
        for linea, fermate in dictionary.items():
            dictionary[linea] = ["padova " + fer if not fer.startswith("padova") and fer != "limena" else fer for fer in fermate]
    
    return dictionary

def clean_after_number_removal(dictionary):
    for linea, fermate in dictionary.items():
        dictionary[linea] = [fer.rstrip(".").rstrip(".. ").rstrip() for fer in fermate]
    
    return dictionary

def create_complete_edge_list(output_file, *args):
    output_file.write("Source, Target, Label\n")
    for dic in args:
        for linea, fermate in dic.items():
            for i in range(1, len(fermate)):
                output_file.write(f"{fermate[i-1]}, {fermate[i]}, {linea}\n")

if __name__ == "__main__":
    data_list = []
    for filename in os.listdir(PATH_TO_RAW_DATA):
        if filename.endswith(".json"):
            with open(f"{PATH_TO_RAW_DATA}/{filename}", "r") as f:
                data_list.append(json.load(f))
    
    urbani, extraurbani = data_list

    white_space_remover = FunctionTransformer(remove_white_spaces)
    na_remover = FunctionTransformer(remove_na)
    duplicate_remover = FunctionTransformer(remove_duplicates_from_list)
    number_remover = FunctionTransformer(remove_numbers)
    cleaner_after_number_removal = FunctionTransformer(clean_after_number_removal)
    abbv_correcter_extr = FunctionTransformer(correct_abbreviations, kw_args={"orari_urbani": False})
    abbv_correcter_urb = FunctionTransformer(correct_abbreviations, kw_args={"orari_urbani": True})

    pipe_urb = Pipeline(steps = [
        ("na", na_remover),
        ("spaces, lowercase", white_space_remover),
        ("remove duplicates", duplicate_remover),
        ("remove numbers", number_remover),
        ("clean after number remove", cleaner_after_number_removal),
        ("abbreviations", abbv_correcter_urb)
    ])

    pipe_extr = Pipeline(steps = [
        ("na", na_remover),
        ("spaces, lowercase", white_space_remover),
        ("remove duplicates", duplicate_remover),
        ("remove numbers", number_remover),
        ("clean after number remove", cleaner_after_number_removal),
        ("abbreviations", abbv_correcter_extr)
    ])

    urbani_clean = pipe_urb.transform(urbani)
    extraurbani_clean = pipe_extr.transform(extraurbani)

    with open(f"{PATH_TO_CLEAN_DATA}/urbani_clean.json", "w") as f:
        json.dump(urbani_clean, f)
    
    with open(f"{PATH_TO_CLEAN_DATA}/extraurbani_clean.json", "w") as f:
        json.dump(extraurbani_clean, f)
    
    # create edge list
    with open(f"{PATH_TO_CLEAN_DATA}/edge_list.csv", "w") as f:
        create_complete_edge_list(f, urbani_clean, extraurbani_clean)