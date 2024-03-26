import requests
from bs4 import BeautifulSoup
import json
import pathlib

PATH = pathlib.Path.cwd() # directory from which file is called
PATH_TO_RAW_DATA = pathlib.Path(str(PATH) + "/data/raw") # raw data directory

def fermate_urbane():
    web = requests.get("https://www.fsbusitalia.it/content/fsbusitalia/it/veneto/orari-e-linee/urbani-padova-e-linee-colli-dal-13-settembre-2023.html")
    soup = BeautifulSoup(web.text, "html.parser")

    tabella = soup.find("div", {"class": "contentable"})
    righe = tabella.find_all("tr")
    dizionario_fermate = dict()
    for row in range(1, len(righe)-1):
        content = righe[row].find_all("td")
        linea = content[0].text

        # gestisce tutti i casi tranne la linea 25
        fermate_tag = content[1].find("p")
        if fermate_tag is None:
            fermate_tag = content[1].find("b")

        fermate = fermate_tag.get_text().split(":")[1][1:]

        # edge case della linea 25
        if linea == "Linea 25":
            fermate = content[1].get_text().split(":")[1][1:]
        
        lista_fermate = fermate.split("-")

        for i in range(len(lista_fermate)):
            if " – " in lista_fermate[i]:
                new_list = lista_fermate[i].split(" – ")
                if len(lista_fermate) == 1:
                    lista_fermate = new_list
                else:
                    lista_fermate = lista_fermate[:i] + new_list + lista_fermate[i+1:]
        
        dizionario_fermate[linea] = lista_fermate
    
    with open(f"{PATH_TO_RAW_DATA}/linee_urbane.json", "w", encoding="utf-8") as f:
        json.dump(dizionario_fermate, f)

def scarica_pdf_extraurbani():
    web = requests.get("https://www.fsbusitalia.it/content/fsbusitalia/it/veneto/orari-e-linee/extraurbani-padova-dal-13-settembre-2023.html")
    soup = BeautifulSoup(web.text, "html.parser")

    tabella = soup.find("div", {"class": "contentable"})
    righe = tabella.find_all("tr")

    for i in range(1, len(righe)):
        info = righe[i].find("a", href=True)
        linea = info.text.replace(" ", "").replace("/", "-")
        link_orari = "https://www.fsbusitalia.it/" + info["href"]

        pagina_pdf = requests.get(link_orari)

        with open(f"{PATH_TO_RAW_DATA}/extraurbani_pdf/{linea}.pdf", "wb") as f:
            f.write(pagina_pdf.content)

if __name__ == "__main__":
    fermate_urbane()
    scarica_pdf_extraurbani()