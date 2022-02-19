directory = getenv('HOME');
%% This class download teh chlorophyll data
%% 1. Class calling
obj=css_oceancolor_diario;
%% Software requirement
%{
SNAP (v. 7.0.0) https://step.esa.int/main/download/snap-download/
GPT paht.
%}
obj.gpt_path='/opt/snap/bin/gpt'; %Not required

%% Global parameters

mission         =   {'MODIS-Aqua','MODIS-Terra','VIIRS-SNPP', 'VIIRS-JPSS1'};
product         =   {'oc' {'chlor_a'}};


%Time (period)
              
start           =   datenum(2019,1,1);
stop            =   datenum(2019,1,1);

%Location

north           =   32.99;
south           =   3;
east            =   -72.00;
west            =   -122;




coordsOrTiles   =   'coords';                   
dayNightBoth    =   'D';                        
variables       =   {'chlor_a'}; 

%%
%Directories for save products


dir_descarga = strcat(directory, '/Downloads');
dir_producto    =   strcat(directory, '/home/roberto/Downloads');


%%
obj.save_files=true;% Not required
obj=obj.download(mission,product,start,stop,north,south,east,west,coordsOrTiles,dayNightBoth,dir_descarga,dir_producto); %Download products functoins

