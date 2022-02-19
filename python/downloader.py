import json
import os
os.system('clear')

print("\nDownloading products!")

try:
    print("\nReading file config.json!")
    with open('config.json') as f:
        data = json.load(f)
    
    print("Reading json products file and starting download !\n")
    for p in data['products']:
        file =  p["name"]+'.json'
        print("Reading file {}".format(file))
        with open(file) as f:
            products = json.load(f)
        for ptd in products['content']:
            print("----------------------------------------------")
            print("Product name {}".format(ptd["name"]))
            print("*Checking the file {} with size {}".format(ptd["name"], ptd["size"]))
            while True: 
                fail = False                   
                try:
                    file_ = 'archives/'+ptd["name"]
                    exist = os.path.isfile(file_)
                    size = os.path.getsize(file_)
                    if exist and size == ptd["size"]:
                        print("**File downloaded successfully")  
                        break                          
                    elif exist:
                        print("**File with wrong size, removing !")
                        os.remove(file)
                        fail = True
                    else:
                        fail = True

                except FileNotFoundError:
                    fail = True
                    print("**Error file not found!")

                if fail:
                    print("**Starting the file download\n\n")
                    queryptd = 'wget -e robots=off -m -np -R .html,.tmp -nH --header "X-Requested-With: XMLHttpRequest"  --header "Authorization: Bearer '+data["token"]+'" --cut-dirs=3 "https://ladsweb.modaps.eosdis.nasa.gov'+ptd['downloadsLink']+'" -P .'
                    print(queryptd)
                    os.system(queryptd)

                print("----------------------------------------------")
        print("\n\n")
except FileNotFoundError:
    print("Error -> The product json file no exist in the directory\n\n")
            
