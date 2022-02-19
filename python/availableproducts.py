import json
import os
os.system('clear')
try:
    print("Reading file config.json")
    with open('config.json') as f:
        data = json.load(f)
    print("Getting of available MODAPS products")

    for p in data['products']:
        print("\n\n +++++++ Looking for {} products collections {} ++++++\n".format(p["name"], p["collections"]))        
        query = 'wget -e robots=off -m -np -R .html,.tmp -nH --header "X-Requested-With: XMLHttpRequest"  --header "Authorization: Bearer '+data["token"]+'" --cut-dirs=3 "http://ladsweb.modaps.eosdis.nasa.gov/api/v2/content/archives?products='+p["name"]+'&temporalRanges='+data["datestart"]+'..'+data["dateend"]+'&regions=[BBOX]W'+str(data["W"])+' N'+str(data["N"])+' E'+str(data["E"])+' S'+str(data["S"])+'&collections='+str(p["collections"])+'&formats=json&illuminations='+data["illuminations"]+'" -O '+p["name"]+'.json'
        print(query)
        os.system(query)
except FileNotFoundError:
    print("Error -> The config.json file no exist in the directory\n\n")
