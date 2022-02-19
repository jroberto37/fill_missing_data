classdef css_oceancolor_diario
    %{
css_oceancolor_diario: descarga de datos L2 en la base de datos de
OceanColor. Es necesario contar con un usuario registrado en Earthdata (https://urs.earthdata.nasa.gov/).
La aplicacion de descarga esta realizada para ejecutar en equipos con
sistema operativo LINUX.
El archivo donde se almacenan los datos de usuario y password se almacenan
el la ruta de HOME (variable de entorno). la variable de entorno continue
la ruta donde se busca/crea el archivo oculto "netrc" que almacena los
datos del usuario.
Si el programa no encuentra el archivo oculto "netrc" solicitara el usuario
y password para crearlo de manera automatica.
    %}
    
    properties
        api='https://modwebsrv.modaps.eosdis.nasa.gov/axis2/services/MODAPSservices/'
        ids
        gpt_path='/opt/snap/bin/gpt'
    end
    properties
        products
        collection
        products1
        dir_out
        filesep_
        path_home
        save_files=true;
        save_files_mosaico=true;
        save_files_merge=true;
        sensor1
        dir_out_end
        settings
        getvarinfo=true
    end
    
    methods
        function this=css_oceancolor_diario
            global error_download
            error_download=[];            
            this.filesep_=filesep;
            this.path_home=getenv('HOME');
            if isempty(this.path_home)
                error('Es necesario contar con la variable de entorno HOME')
            end
            if exist([this.path_home '/.netrc'],'file')~=2
                fprintf('WARNING: Please make authentication file\n')
                prompt = {'Enter username:','Enter userpassword:'};
                dlg_title = 'netrc file';
                num_lines = 1;
                def = {'user','pass'};
                answer = inputdlg(prompt,dlg_title,num_lines,def);
                if isempty(answer)
                    return
                end
                this=this.make_auth_file(answer{1,1},answer{2,1});
            end
        end
        function this=download(this,sensor1,products2,start,stop,north,south,east,west,coordsOrTiles,dayNightBoth,dir_out1,dir_out2)
            %{
            if exist(this.gpt_path,'file')==0
                error('Please check your snap gpt file')
            end
            %}
            this.dir_out=dir_out1;
            this.dir_out_end=dir_out2;
            validStrings={'MODIS-Aqua','MODIS-Terra','VIIRS-JPSS1','VIIRS-SNPP'};
            if ischar(sensor1)
                sensor1={sensor1};
            end
            sensor1=sensor1(:);
            for i=1:size(sensor1,1)
                for jj=1:size(products2,1)
                    products1=products2{jj,1};
                    variables=products2{jj,2};
                    aa1=tic;
                    this.settings=struct;
                    if ischar(variables)
                        variables={variables};
                    else
                        variables=variables(:);
                    end
                    this.settings.variables=variables;
                    this.settings.sensor = validatestring(sensor1{i,1},validStrings);
                    
                    switch this.settings.sensor
                        case 'MODIS-Aqua'
                            this.settings.productsGEO='MYD03';
                            this.settings.collection='61';
                            this.settings.product = validatestring(products1,{'OC','IOP','SST','SST4'});
                        case 'MODIS-Terra'
                            this.settings.productsGEO='MOD03';
                            this.settings.collection='61';
                            this.settings.product = validatestring(products1,{'OC','IOP','SST','SST4'});
                        case 'VIIRS-JPSS1'
                            this.settings.productsGEO='VJ103DNB';
                            this.settings.collection='5200';
                            this.settings.product = validatestring(products1,{'OC','IOP'});
                        case 'VIIRS-SNPP'
                            this.settings.productsGEO='VNP03DNB';
                            this.settings.collection='5110';
                            this.settings.product = validatestring(products1,{'OC','IOP','SST','SST4'});
                    end
                    this.getvarinfo=true;
                    this.settings.north=north;
                    this.settings.south=south;
                    this.settings.east=east;
                    this.settings.west=west;
                    this=this.consulta(start,stop,coordsOrTiles,dayNightBoth);
                    fprintf([this.settings.sensor ' time: %0.4f\n'],toc(aa1))
                end
            end
        end

        function out=parse1(this,data)
            switch this.settings.sensor
                case 'MODIS-Aqua'
                    out=[str2double(data(8:11)) str2double(data(12:14)) str2double(data(16:17)) str2double(data(18:19))];
                case 'MODIS-Terra'
                    out=[str2double(data(8:11)) str2double(data(12:14)) str2double(data(16:17)) str2double(data(18:19))];
                case 'VIIRS-JPSS1'
                    out=[str2double(data(11:14)) str2double(data(15:17)) str2double(data(19:20)) str2double(data(21:22))];
                case 'VIIRS-SNPP'
                    out=[str2double(data(11:14)) str2double(data(15:17)) str2double(data(19:20)) str2double(data(21:22))];
            end
        end
        function lista=parse2(this,data)
            switch this.settings.sensor
                case 'MODIS-Aqua'
                    switch this.settings.product
                        case 'OC'
                            lista=sprintf('--post-data="sensor=aqua&results_as_file=1&addurl=1&search=A%d%03d%02d%02d*L2_LAC_OC*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4));
                        case 'IOP'
                            lista=sprintf('--post-data="sensor=aqua&results_as_file=1&addurl=1&search=A%d%03d%02d%02d*L2_LAC_IOP*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4));
                        case 'SST'
                            dd=datevec(datenum(data(1),1,0)+data(2));
                            lista=sprintf('--post-data="sensor=aqua&results_as_file=1&addurl=1&search=AQUA_MODIS.%d%02d%02dT%02d%02d*L2.SST.nc*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',dd(1),dd(2),dd(3),data(3),data(4));
                        case 'SST4'
                            dd=datevec(datenum(data(1),1,0)+data(2));
                            lista=sprintf('--post-data="sensor=aqua&results_as_file=1&addurl=1&search=AQUA_MODIS.%d%02d%02dT%02d%02d*L2.SST4*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',dd(1),dd(2),dd(3),data(3),data(4));
                    end
                case 'MODIS-Terra'
                    switch this.settings.product
                        case 'OC'
                            lista=sprintf('--post-data="sensor=terra&results_as_file=1&addurl=1&search=T%d%03d%02d%02d*L2_LAC_OC*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4));
                        case 'IOP'
                            lista=sprintf('--post-data="sensor=terra&results_as_file=1&addurl=1&search=T%d%03d%02d%02d*L2_LAC_IOP*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4));
                        case 'SST'
                            dd=datevec(datenum(data(1),1,0)+data(2));
                            lista=sprintf('--post-data="sensor=terra&results_as_file=1&addurl=1&search=TERRA_MODIS.%d%02d%02dT%02d%02d*L2.SST.nc*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',dd(1),dd(2),dd(3),data(3),data(4));
                        case 'SST4'
                            dd=datevec(datenum(data(1),1,0)+data(2));
                            lista=sprintf('--post-data="sensor=terra&results_as_file=1&addurl=1&search=TERRA_MODIS.%d%02d%02dT%02d%02d*L2.SST4*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',dd(1),dd(2),dd(3),data(3),data(4));
                    end
                case 'VIIRS-JPSS1'
                    switch this.settings.product
                        case 'OC'
                            lista=sprintf('--post-data="sensor=viirsj1&results_as_file=1&addurl=1&search=V%d%03d%02d%02d*L2_JPSS1_OC*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4));
                        case 'IOP'
                            lista=sprintf('--post-data="sensor=viirsj1&results_as_file=1&addurl=1&search=V%d%03d%02d%02d*L2_JPSS1_IOP*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4));
                        case 'SST'
                            dd=datevec(datenum(data(1),1,0)+data(2));
                            lista=sprintf('--post-data="sensor=viirsj1&results_as_file=1&addurl=1&search=SNPP_VIIRS.%d%02d%02dT%02d%02d*L2.SST.nc*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',dd(1),dd(2),dd(3),data(3),data(4));
                        case 'SST4'
                            dd=datevec(datenum(data(1),1,0)+data(2));
                            lista=sprintf('--post-data="sensor=viirsj1&results_as_file=1&addurl=1&search=SNPP_VIIRS.%d%02d%02dT%02d%02d*L2.SST3*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',dd(1),dd(2),dd(3),data(3),data(4));
                    end
                case 'VIIRS-SNPP'
                    switch this.settings.product
                        case 'OC'
                            lista=sprintf('--post-data="sensor=viirs&results_as_file=1&addurl=1&search=V%d%03d%02d%02d*L2_SNPP_OC*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4));
                        case 'IOP'
                            lista=sprintf('--post-data="sensor=viirs&results_as_file=1&addurl=1&search=V%d%03d%02d%02d*L2_SNPP_IOP*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4));
                        case 'SST'
                            dd=datevec(datenum(data(1),1,0)+data(2));
                            lista=sprintf('--post-data="sensor=viirs&results_as_file=1&addurl=1&search=SNPP_VIIRS.%d%02d%02dT%02d%02d*L2.SST.nc*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',dd(1),dd(2),dd(3),data(3),data(4));
                        case 'SST4'
                            dd=datevec(datenum(data(1),1,0)+data(2));
                            lista=sprintf('--post-data="sensor=viirs&results_as_file=1&addurl=1&search=SNPP_VIIRS.%d%02d%02dT%02d%02d*L2.SST3*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',dd(1),dd(2),dd(3),data(3),data(4));
                    end
            end
        end
        function out=search_aqua(this,data,state)
            switch state
                case 1
                    out=[str2double(data(8:11)) str2double(data(12:14)) str2double(data(16:17)) str2double(data(18:19))];
                case 2
                    lista=sprintf('--post-data="sensor=aqua&results_as_file=1&addurl=1&search=A%d%03d%02d%02d*L2_LAC_%s*" https://oceandata.sci.gsfc.nasa.gov/api/file_search',data(1),data(2),data(3),data(4),this.settings.product);
                    out=this.search_download(lista);
            end
        end
        function out=search_download(this,lista)
            global error_download
            a=tic;
            out=[];
            commando=['wget --load-cookies ' this.path_home '/.urs_cookies ',...
                '--save-cookies ' this.path_home '/.urs_cookies --auth-no-challenge=on -O dummy.xml ',...
                lista];
            [status,cmdout]= system(commando);
            if status~=0
                disp(cmdout)
                out=[];
                return
            end
            fprintf(['Buscando Archivos: '  ' %0.4f\n'],toc(a))
            fileID=fopen('dummy.xml');
            ddd=textscan(fileID,'%s');
            fclose(fileID);
            delete dummy.xml
            
            if ~isempty(ddd{1})
                dummy_ind=strfind(ddd{1}{1,1},'/');
                file=ddd{1}{1,1}(dummy_ind(end)+1:end);
                out_file=[this.dir_out this.filesep_ file];
                if exist(out_file,'file')==0
                    a=tic;
                    commando=['wget --load-cookies ' this.path_home '/.urs_cookies ',...
                        '--save-cookies ' this.path_home '/.urs_cookies --auth-no-challenge=on ',...
                        '--output-document=' out_file ' ',...
                        '--tries=5 --timeout=10 --random-wait ',...
                        '--content-disposition ' ddd{1}{1,1}];
                    [status,cmdout]= system(commando);
                    if status~=0
                        disp(cmdout)
                        error('Revisar las descarga')
                    end
                    fprintf('Descargando: %s. Time:  %0.4f\n',ddd{1}{1,1},toc(a))
                    try
                        ncid=netcdf.open(out_file);
                        netcdf.close(ncid);
                    catch me
                        error('Error al leer los datos')
                    end
                    out=out_file;
                else
                    try
                        ncid=netcdf.open(out_file);
                        netcdf.close(ncid);
                        out=out_file;
                    catch me
                        delete(out_file)
                        error_download=[error_download;{commando}];
                        disp(['Error al leer los datos:' out_file])
                        out=out_file;
                    end
                    
                end
            else
                fprintf('Archivo no se encentra en OCEANCOLOR: %s\n',lista)
            end
        end
        function this=consulta(this,start,stop,coordsOrTiles,dayNightBoth)
            this.ids=[];
            for ii=1:size(this.settings.north,1)
                aa1=tic;
                lista=['"https://modwebsrv.modaps.eosdis.nasa.gov/axis2/services/MODAPSservices/searchForFiles?',...
                    'products=' this.settings.productsGEO '&collection=' this.settings.collection '&start=' datestr(start,'yyyy-mm-dd') '&stop=' datestr(stop,'yyyy-mm-dd'),...
                    '&north=' sprintf('%0.8f',this.settings.north(ii,1)) '&south= ' sprintf('%0.8f',this.settings.south(ii,1))  '&east=' sprintf('%0.8f',this.settings.east(ii,1)) '&west=' sprintf('%0.8f',this.settings.west(ii,1)) '&coordsOrTiles=' coordsOrTiles,...
                    '&dayNightBoth=' dayNightBoth '"'];
                commando=['wget --load-cookies ' this.path_home '/.urs_cookies ',...
                    '--save-cookies ' this.path_home '/.urs_cookies --auth-no-challenge=on -O dummy.xml ',...
                    lista];
                [status,cmdout]= system(commando);
                if status~=0
                    disp(cmdout)
                    return
                end
                fprintf('Buscando id files : %0.4f\n',toc(aa1))
                docNode = xmlread('dummy.xml');
                nodos=docNode.getElementsByTagName('return');
                ids1=cell(nodos.getLength,6);
                for i=1:nodos.getLength
                    dummy=nodos.item(i-1);
                    dummy2=dummy.getChildNodes;
                    dummy3=dummy2.item(0);
                    ids1{i,1}=char(dummy3.getNodeValue);
                    ids1{i,2}=ii;
                end
                delete dummy.xml
                this.ids=[this.ids;ids1];
            end
            [C,ia,ic]=unique(this.ids(:,1));
            tabladescarga=this.ids(ia,:);
            %https://modwebsrv.modaps.eosdis.nasa.gov/axis2/services/MODAPSservices/getFileProperties?fileIds=204846513,204718831
            if numel(ia)>100
                ind=fix(linspace(1,numel(ia),ceil(numel(ia)/100)));
                ind=[ind(1:end-1);ind(2:end)-1];
                ind(end)=numel(ia);
            else
                ind=[1;numel(ia)];
            end
            for jj=1:size(ind,2)
                id=[];
                for i=ind(1,jj):ind(2,jj)
                    id=[id this.ids{ia(i),1} ','];
                end
                id(end)=[];
                aa1=tic;
                lista=['https://modwebsrv.modaps.eosdis.nasa.gov/axis2/services/MODAPSservices/getFileProperties?fileIds=' id];
                commando=['wget --load-cookies ' this.path_home '/.urs_cookies ',...
                    '--save-cookies ' this.path_home '/.urs_cookies --auth-no-challenge=on -O dummy.xml ',...
                    lista];
                [status,cmdout]= system(commando);
                if status~=0
                    disp(cmdout)
                    return
                end
                fprintf('Recuperando informacion de id files : %0.4f\n',toc(aa1))
                docNode = xmlread('dummy.xml');
                nodos=docNode.getElementsByTagName('mws:fileName');
                nodos1=docNode.getElementsByTagName('mws:fileId');
                for i=1:nodos.getLength
                    dummy=nodos.item(i-1);
                    dummy2=dummy.getChildNodes;
                    dummy3=dummy2.item(0);
                    out=this.parse1(char(dummy3.getNodeValue));
                    dummy=nodos1.item(i-1);
                    dummy2=dummy.getChildNodes;
                    dummy3=dummy2.item(0);
                    clave=char(dummy3.getNodeValue);
                    tabladescarga(strcmpi(clave,tabladescarga(:,1)),4)={out};
                    tabladescarga{strcmpi(clave,tabladescarga(:,1)),6}=datenum(out(1),1,1)+out(2)-1;
                end
                delete dummy.xml
            end
            %% descargo
            for i=1:size(tabladescarga,1)
                tabladescarga{i,3}=this.search_download(this.parse2(tabladescarga{i,4}));
            end
            this.ids(:,4)=tabladescarga(ic,3);
            this.ids(:,5)=tabladescarga(ic,4);
            this.ids(:,6)=tabladescarga(ic,6);
        end
        function this=make_auth_file(this,user,pass)
            this.path_home=getenv('HOME');
            [status,cmdout]= system(sprintf(['echo "machine urs.earthdata.nasa.gov login %s password %s" > ' this.path_home '/.netrc; > ' this.path_home '/.urs_cookies'],user,pass));
            if status~=0
                fprintf([cmdout '\n'])
            end
            [status,cmdout]= system(['chmod  0600 ' this.path_home '/.netrc']);
            if status~=0
                fprintf([cmdout '\n'])
            end
        end
  
    end
    methods(Static)
        
        
    end
end
