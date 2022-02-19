# fill_missing_data how to use it

## Matlab Code

To use download matlab code just open main_download_chlora.m and adjust the global parameters and click on run button in the editor tab

## Python code 

First of all, you need generate a token profile on https://ladsweb.modaps.eosdis.nasa.gov/ and put in to json config file, select the time, location and products
Second, execute availableproducts.py file, this action generate a json file per product
Third, execute downloader.py for download the available products

Note: The products are saved in the archives folder
