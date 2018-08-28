function Preprocess,orignalfile,outfile,error=error
  compile_opt idl2
;  envi,/restore_base_save_files
;  envi_batch_init
;  envi_batch_status_window,/on  
  e=call_function('envi',/headless)
  
  ;��ȡԭʼ���������Ϣ
  xmlfile=file_dirname(orignalfile)+path_sep()+file_basename(orignalfile,'.tiff')+'.xml'
  ret=ReadInfo(xmlfile,satellite,sensor,year,month,day,gmt,latitude,longitude,latrange,lonrange,error=error)
  if ret ne 1 then begin
    error='��ȡԭʼ���������Ϣʧ��!---'+error
    print,error
    return,0
  endif
  print,'Satellite:',satellite
  print,'Sensor:',sensor
  print,'Year:',year,'Month:',month,'Day:',day
  print,'Longitude:',longitude
  print,'Latitude:',latitude
  print,'Lonrange:',lonrange
  print,'Latrange:',latrange
  
  currentdir=file_dirname(file_dirname(routine_filepath('Preprocess',/is_function)))+path_sep()
  resourcedir=currentdir+'Resource'+path_sep()
  if ~file_test(resourcedir,/directory) then begin
    error=resourcedir+'�����ļ�·��������!'
    return,0
  endif
  defsysv,'!resourcedir',resourcedir
  tempdir=currentdir+'Temp'+path_sep()
  if ~file_test(tempdir) then file_mkdir,tempdir
  defsysv,'!tempdir',tempdir
    
  ;��ȡ����ϵ��  
  paramfile=currentdir+'Resource'+path_sep()+'Calibration_Parametres.xml'  
  ret=ReadParam(paramfile,year,satellite,sensor,gain,offset,esum,error=error)
  if ret ne 1 then begin
    error='��ȡ����ϵ��ʧ��!---'+error
    print,error
    return,0
  endif
  print,'Gain:',strjoin(strtrim(string(gain),2),',')
  print,'Offset:',strjoin(strtrim(string(offset),2),',')
  print,'Esum:',esum
    
  ;���䶨��
  radfile=!tempdir+file_basename(outfile,'.tiff')+'_Rad.dat'
  ret=Calibrate(year,satellite,sensor,orignalfile,gain,offset,radfile,error=error)  
  if ret ne 1 then begin
    error='���䶨��ʧ��!---'+error
    print,error
    return,0
  endif
    
  ;Flaash����У��  
  ret=Flaash(radfile,satellite,sensor,year,month,day,gmt,latitude,longitude,latrange,lonrange,outfile,error=error)
  if ret ne 1 then begin
    error='Flaash����У��ʧ��!---'+error
    print,error
    return, 0
  endif  
  
  return,1
end


function ReadInfo,xmlfile,satellite,sensor,year,month,day,gmt,latitude,longitude,latrange,lonrange,error=error
  compile_opt idl2
  
  catch,error_status
  if error_status ne 0 then begin
    error=!ERROR_STATE.MSG
    catch,/cancel
    return,0
  endif

  if ~file_test(xmlfile) then begin
    error=xmlfile+'�ļ�������!'
    return,0
  endif

  oDoc=obj_new('IDLffXMLDOMDocument', filename=xmlfile)

  oXmlEle=oDoc->GetDocumentElement()                          ;���ڵ�
  
  oSatellite=oXmlEle->GetElementsByTagName('SatelliteID')
  Satellite_list=oSatellite->item(0)
  satellite=(Satellite_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oSatellite, Satellite_list]
  
  oSensor=oXmlEle->GetElementsByTagName('SensorID')
  Sensor_list=oSensor->item(0)
  sensor=(Sensor_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oSensor, Sensor_list]

  oInt=oXmlEle->GetElementsByTagName('ReceiveTime')
  Int_list=oInt->item(0)
  ReceiveTime=(Int_list->GetFirstChild())->GetNodeValue()
  date_=(strsplit(ReceiveTime,' ',/extract))[0]
  temp=fix(strsplit(date_,'-',/extract))
  year=temp[0] & month=temp[1] & day=temp[2]
  time=(strsplit(ReceiveTime,' ',/extract))[1]
  temp=strsplit(time,':',/extract)
  hour=temp[0] & minute=temp[1] & second=temp[2]
  gmt=float(hour)+float(minute)/60+float(second)/3600
  obj_destroy,[oInt, Int_list]

  oInt=oXmlEle->GetElementsByTagName('TopLeftLatitude')
  Int_list=oInt->item(0)
  TopLeftLatitude=(Int_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oInt, Int_list]
  oInt=oXmlEle->GetElementsByTagName('TopRightLatitude')
  Int_list=oInt->item(0)
  TopRightLatitude=(Int_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oInt, Int_list]
  oInt=oXmlEle->GetElementsByTagName('BottomRightLatitude')
  Int_list=oInt->item(0)
  BottomRightLatitude=(Int_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oInt, Int_list]
  oInt=oXmlEle->GetElementsByTagName('BottomLeftLatitude')
  Int_list=oInt->item(0)
  BottomLeftLatitude=(Int_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oInt, Int_list]
  latitude=(float(TopLeftLatitude)+float(TopRightLatitude)+float(BottomRightLatitude)+float(BottomLeftLatitude))/4
  latrange=[min([BottomRightLatitude,BottomLeftLatitude]),max([TopLeftLatitude,TopRightLatitude])]

  oInt=oXmlEle->GetElementsByTagName('TopLeftLongitude')
  Int_list=oInt->item(0)
  TopLeftLongitude=(Int_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oInt, Int_list]
  oInt=oXmlEle->GetElementsByTagName('TopRightLongitude')
  Int_list=oInt->item(0)
  TopRightLongitude=(Int_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oInt, Int_list]
  oInt=oXmlEle->GetElementsByTagName('BottomRightLongitude')
  Int_list=oInt->item(0)
  BottomRightLongitude=(Int_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oInt, Int_list]
  oInt=oXmlEle->GetElementsByTagName('BottomLeftLongitude')
  Int_list=oInt->item(0)
  BottomLeftLongitude=(Int_list->GetFirstChild())->GetNodeValue()
  obj_destroy,[oInt, Int_list]
  longitude=(float(TopLeftLongitude)+float(TopRightLongitude)+float(BottomRightLongitude)+float(BottomLeftLongitude))/4
  lonrange=[min([TopLeftLongitude,BottomLeftLongitude]),max([TopRightLongitude,BottomRightLongitude])]

  obj_destroy, oDoc  
  return,1
end


function ReadParam,parametresfile,year,satellite,sensor,gain,offset,Esum,error=error
  compile_opt idl2

  catch,error_status
  if error_status ne 0 then begin
    error=!ERROR_STATE.MSG
    catch,/cancel
    return,0
  endif
    
  if ~file_test(parametresfile) then begin
    error=parametresfile+'�����ļ�������!'
    return,0
  endif

  oDoc=obj_new('IDLffXMLDOMDocument', filename=parametresfile)
  oxmlele=oDoc->GetDocumentElement()                                ;���ڵ�
  oyear=oXmlEle->GetElementsByTagName('Year')
  num0=oyear->getlength()
  for i=0, num0-1 do begin                                          ;���
    
    year_=oyear->item(i)
    if year eq year_->GetAttribute('value') then begin
      osatellite=year_->GetElementsByTagName('Satellite')
      num1=osatellite->getlength()
      for j=0, num1-1 do begin                                      ;����
        
        satellite_=osatellite->item(j)
        if satellite eq satellite_->GetAttribute('name') then begin
          osensor=satellite_->GetElementsByTagName('Sensor')
          num2=osensor->getlength()
          for k=0, num2-1 do begin                                  ;������
            
            sensor_=osensor->item(k)
            if sensor eq sensor_->GetAttribute('name') then begin
              oband=sensor_->GetElementsByTagName('Element')
              num3=oband->getlength()
              gain=fltarr(num3)
              offset=fltarr(num3)
              Esum=fltarr(num3)
              for t=0, num3-1 do begin                               ;����
                band_=oband->item(t)
                value=band_->GetAttribute('value')
                gain[t]=float((strsplit(value,',',/extract))[0])
                offset[t]=float((strsplit(value,',',/extract))[1])
                Esum[t]=float((strsplit(value,',',/extract))[2])
              endfor
              obj_destroy, oDoc
              break
            endif
            
          endfor
          break
        endif
        
      endfor
      break
    endif
        
  endfor
  
  if (n_elements(gain) eq 0) or (n_elements(offset) eq 0) or (n_elements(esum) eq 0) then begin
    error='û�з���Ҫ��Ķ���ϵ��,��ȡʧ��!'
    return,0
  endif

  if obj_valid(oDoc) then obj_destroy, oDoc  
  return,1
end


function Calibrate,year,satellite,sensor,inputfile,gain,offset,radfile,error=error
  compile_opt idl2  

  catch,error_status
  if error_status ne 0 then begin
    error=!ERROR_STATE.MSG
    catch,/cancel
    return,0
  endif  

  if ~file_test(inputfile) then return, '���䶨��...ԭʼ���ݲ�����!'
  if n_elements(gain) eq 0 then return, '���䶨��...����ֵδָ��!'
  if n_elements(offset) eq 0 then return, '���䶨��...ƫ��ֵδָ��!'

  ;���䶨��
  call_procedure, 'envi_open_file', inputfile, r_fid=tfid
  call_procedure, 'envi_file_query', tfid, dims=dims, ns=ns, nl=nl, nb=nb
  mapinfo0=call_function('envi_get_map_info',fid=tfid)
  oproj=call_function('envi_get_projection',fid=tfid)
  fidarr=!null & raddata=!null

  tempfiles=!null
  for i=0, nb-1 do begin
    ;��ͬ���,��ͬ����,���깫ʽ��ͬ
    case satellite of
      'GF1':begin
        if year eq '2013' then begin
          if strmid(sensor,0,3) eq 'PMS' then begin
            expstr='b1*('+strtrim(string(gain[i]),2)+')+('+strtrim(string(offset[i]),2)+')'
          endif else if strmid(sensor,0,3) eq 'WFV' then begin
            expstr='(b1-('+strtrim(string(offset[i]),2)+'))/('+strtrim(string(gain[i]),2)+')'
          endif
        endif else if year eq '2014' then begin
          expstr='b1*('+strtrim(string(gain[i]),2)+')'
        endif else begin
          expstr='b1*('+strtrim(string(gain[i]),2)+')+('+strtrim(string(offset[i]),2)+')'
        endelse
      end
      'GF2':expstr='b1*('+strtrim(string(gain[i]),2)+')+('+strtrim(string(offset[i]),2)+')'
      else:
    endcase

    tempfile=!tempdir+file_basename(inputfile,'.tiff')+'_'+strtrim(string(i),2)+'.dat'
    call_procedure, 'envi_doit', 'math_doit', $
      exp=expstr, $
      fid=[tfid], $
      dims=dims, $
      pos=[i], $
      out_name=tempfile, $
      r_fid=rfid
    if rfid eq -1 then begin
      error=strtrim(string(i+1),2)+'���η��䶨��ʧ��!'
      return,0
    endif
    tempfiles=[tempfiles,tempfile]
    call_procedure, 'envi_file_mng', id=rfid, /remove
  endfor

  radfile_=!tempdir+file_basename(radfile,'.dat')+'_.dat'
  openw,lun,radfile_,/get_lun

  for i=0, nb-1 do begin
    call_procedure, 'envi_open_file', tempfiles[i], r_fid=tempfid
    raddata=call_function('envi_get_data',fid=tempfid,dims=dims,pos=[0])
    writeu,lun,temporary(raddata)
    fidarr=[fidarr,tempfid]
  endfor
  free_lun,lun
  
  call_procedure, 'envi_file_query', tempfid, data_type=datatype
  call_procedure, 'envi_setup_head', $
    fname=radfile_, $
    ns=ns,nl=nl,nb=nb, $
    offset=0, $
    interleave=0, $
    data_type=datatype, $
;    map_info=mapinfo, $
    r_fid=rfid, $
    /write
  if rfid eq -1 then begin
    error='�������ʧ��!'
    return,0
  endif
  call_procedure,'envi_file_mng',id=rfid,/remove
  call_procedure,'envi_open_file',radfile_,r_fid=rfid
  call_procedure,'envi_file_query',rfid,dims=dims,ns=ns,nl=nl,nb=nb
  call_procedure,'envi_doit','convert_doit', $
    fid=rfid, $
    dims=dims, $
    pos=indgen(nb), $
    o_interleave=1, $
    out_name=radfile, $
    r_fid=rfid_
  if rfid_ eq -1 then begin
    error='BSQתBILʧ��!'
    return,0
  endif

  for i=0, nb-1 do begin
    call_procedure, 'envi_file_mng', id=fidarr[i], /remove, /delete
  endfor
  call_procedure, 'envi_file_mng', id=tfid, /remove;, /delete
  call_procedure, 'envi_file_mng', id=rfid, /remove, /delete
  call_procedure, 'envi_file_mng', id=rfid_, /remove

  return,1  
end


function Ground_Elevation,demfile,latrange,lonrange,meandem,error=error
  compile_opt idl2
  
  call_procedure, 'envi_open_file', demfile, r_fid=tfid
  if tfid eq '-1' then begin
    error='��ȡĿ�����򺣰�ʱDEM�ļ���ʧ��!'
    return,0
  endif
  call_procedure, 'envi_file_query', tfid, dims=dims, ns=ns, nl=nl, nb=nb
  iproj=call_function('envi_proj_create', /geographic)
  oproj=call_function('envi_get_projection', fid=tfid)
  call_procedure, 'envi_convert_projection_coordinates', $
    lonrange, latrange, iproj, $
    xmap, ymap, oproj
  call_procedure, 'envi_convert_file_coordinates', $
    tfid, xf, yf, xmap, ymap

  sub_dims=[-1, round(xf[0]), round(xf[1]), round(yf[1]), round(yf[0])]
  print, sub_dims
  tempfile=file_dirname(demfile)+path_sep()+'DEM_Subset.dat'
  call_procedure, 'envi_doit', 'resize_doit', $
    fid=tfid, $
    dims=sub_dims, $
    pos=indgen(nb), $
    interp=0, $
    out_name=tempfile, $
    rfact=[1.,1.], $
    r_fid=rfid
  if rfid eq -1 then begin
    error='��ȡĿ������ƽ������ʧ��!'
    return,0
  endif
  
  call_procedure,'envi_file_mng',id=rfid,/remove
  call_procedure,'envi_open_file',tempfile,r_fid=rfid
  call_procedure, 'envi_file_query', rfid, dims=dims, ns=ns, nl=nl, nb=nb
  demdata=call_function('envi_get_data', fid=rfid, dims=dims, pos=[0])
  index=where(demdata ne 0, count)
  if count gt 0 then begin
    meandem=mean(demdata[index])/1000.
  endif else begin
    meandem=0.
  endelse
  demdata=!Null

  call_procedure, 'envi_file_mng', id=tfid, /remove
  call_procedure, 'envi_file_mng', id=rfid, /remove, /delete

  return,1  
end


function Atmosphere_Model,month,latitude,atmos_model,error=error
  compile_opt idl2
  
  ;SAW-0, MLW-1, US.Standard-2, SAS-3, MLS-4, T-5
  atmosphere_models= $
    ; 1&2    3&4    5&6    7&8    9&10   11&12
    [['SAW', 'SAW', 'SAW', 'MLW', 'MLW', 'SAW'], $   ;75~85
    ['SAW', 'SAW', 'MLW', 'MLW', 'MLW', 'SAW'], $   ;65~75
    ['MLW', 'MLW', 'MLW', 'SAS', 'SAS', 'MLW'], $   ;55~65
    ['MLW', 'MLW', 'SAS', 'SAS', 'SAS', 'SAS'], $   ;45~55
    ['SAS', 'SAS', 'SAS', 'MLS', 'MLS', 'SAS'], $   ;35~45
    ['MLS', 'MLS', 'MLS', 'T',   'T',   'MLS'], $   ;25~35
    ['T',   'T',   'T',   'T',   'T',   'T'  ], $   ;15~25
    ['T',   'T',   'T',   'T',   'T',   'T'  ], $   ;05~15
    ['T',   'T',   'T',   'T',   'T',   'T'  ], $   ;-05~05
    ['T',   'T',   'T',   'T',   'T',   'T'  ], $   ;-15~-05
    ['T',   'T',   'T',   'MLS', 'MLS', 'T'  ], $   ;-25~-15
    ['MLS', 'MLS', 'MLS', 'MLS', 'MLS', 'MLS'], $   ;-35~-25
    ['SAS', 'SAS', 'SAS', 'SAS', 'SAS', 'SAS'], $   ;-45~-35
    ['SAS', 'SAS', 'SAS', 'MLW', 'MLW', 'SAS'], $   ;-55~-45
    ['MLW', 'MLW', 'MLW', 'MLW', 'MLW', 'MLW'], $   ;-65~-55
    ['MLW', 'MLW', 'MLW', 'MLW', 'MLW', 'MLW'], $   ;-75~-65
    ['MLW', 'MLW', 'MLW', 'MLW', 'MLW', 'MLW'] ]

  if fix(month) mod 2 eq 1 then sam=(fix(month)+1)/2-1 else sam=fix(month)/2-1
  ;8 7 6 5 4 3 2 1 0 -1 -2 -3 -4 -5 -6 -7 -8
  ;0 1 2 3 4 5 6 7 8 9  10 11 12 13 14 15 16
  if latitude-fix(latitude/10)*10 ge 5 then lin=8-(fix(latitude)/10+1) else lin=8-(fix(latitude)/10)
  case atmosphere_models[sam, lin] of
    'SAW': atmos_model=0
    'MLW': atmos_model=1
    'US':  atmos_model=2
    'SAS': atmos_model=3
    'MLS': atmos_model=4
    'T':   atmos_model=5
  endcase
  
  return,1    
end


function Readfwhm,fwhmfile,satellite,sensor,wavelength,fwhm,error=error
  compile_opt idl2
  
  if ~file_test(fwhmfile) then begin
    error=fwhmfile+'�ļ�������!'
    return,0
  endif
  
  oDoc=obj_new('IDLffXMLDOMDocument', filename=fwhmfile)
  oxmlele=oDoc->GetDocumentElement()                            ;���ڵ�
  osatellite=oxmlele->GetElementsByTagName('Satellite')
  num1=osatellite->getlength()
  for j=0, num1-1 do begin                                      ;����
    satellite_=osatellite->item(j)
    if satellite eq satellite_->GetAttribute('name') then begin
      osensor=satellite_->GetElementsByTagName('Sensor')
      num2=osensor->getlength()
      for k=0, num2-1 do begin                                  ;������
        sensor_=osensor->item(k)
        if sensor eq sensor_->GetAttribute('name') then begin
          oband=sensor_->GetElementsByTagName('Element')
          num3=oband->getlength()
          wavelength=fltarr(num3)
          fwhm=fltarr(num3)
          for t=0, num3-1 do begin                               ;����
            band_=oband->item(t)
            value=band_->GetAttribute('value')
            wavelength[t]=float((strsplit(value,',',/extract))[0])
            fwhm[t]=float((strsplit(value,',',/extract))[1])
          endfor
          obj_destroy, oDoc
          break
        endif
      endfor
      break
    endif
  endfor

  if obj_valid(oDoc) then obj_destroy, oDoc

  return,1   
end


function Flaash,radfile,satellite,sensor,year,month,day,gmt,latitude,longitude,latrange,lonrange,reffile,error=error
  compile_opt idl2

  catch,error_status
  if error_status ne 0 then begin
    error=!ERROR_STATE.MSG
    catch,/cancel
    return,0
  endif  
  
  call_procedure,'envi_open_file',radfile,r_fid=tfid
  if tfid eq -1 then begin
    error=radfile+'��ʧ��!'
    return,0
  endif
  call_procedure,'envi_file_query',tfid,dims=dims,ns=nspatial,nl=nlines,data_type=data_type

  reffile_=!tempdir+file_basename(reffile,'.tiff')+'_.dat'

  ;���·��
  modtran_directory=file_dirname(reffile)+path_sep()

  ;������Ӧ����
  filter_func_filename=!resourcedir+'Filter'+path_sep()+satellite+'_'+sensor+'_'+'SpectralResponsivity.sli'
  if ~file_test(filter_func_filename) then begin
    error=filter_func_filename+'������Ӧ����������!'
    return,0
  endif

  ;��ȡXML�ļ���ȡӰ��ʱ�����Ϣ
;  ret=self->ObtainInfo(year,month,day,gmt,latitude,longitude,latrange,lonrange)

  ;���Ǹ߶Ⱥ�Ӱ��ֱ���
  case satellite of
    'GF1':begin
      if strmid(sensor,0,3) eq 'PMS' then pixel_size=8. else pixel_size=16.
      sensor_altitude=645.0
      sensor_name='GF-1'
      filter_func_file_index=0  ;????????????
    end
    'GF2':begin
      pixel_size=4.
      sensor_altitude=631.0
      sensor_name='GF-2'
      filter_func_file_index=0
    end
    else:begin
      error='satellite����!'+satellite
      return,0
    endelse
  endcase

  ;�о���ƽ�����θ߶�
  demfile=!resourcedir+'GMTED2010.jp2'
  res=Ground_Elevation(demfile,latrange,lonrange,elevation,error=error)
  if res ne 1 then begin
    error='ͳ��ƽ�����θ߶�ʧ��!'+error
    return,0  
  endif
  ground_elevation=elevation

  ;����ģ�ͣ�0-SAW;1-MLW;2-U.S. Standard;3-SAS;4-MLS;5-T
  res=Atmosphere_Model(month,latitude,atmosphere,error=error)
  if res ne 1 then begin
    error='����ģ��ѡȡʧ��!'+error
    return,0
  endif
  atmosphere_model=atmosphere

  ;���ܽ�ģ�ͣ�0-No Aerosol;1-Rural;2-Maritime;3-Urban;4-Tropospheric
  aerosol_model=1

  ;���������Ϣ
  wavelength_units='micron'
  fwhmfile=!resourcedir+'FWHM_Parametres.xml'
  if ~file_test(fwhmfile) then begin
    error=fwhmfile+'�ļ�������!'
    return,0
  endif
  ret=Readfwhm(fwhmfile,satellite,sensor,wavelength,fwhm,error=error)
  if ret ne 1 then begin
    error='��ȡFWHMʧ��!'+error
    return,0
  endif

  ;�������ȵ�λת��ϵ��
  input_scale=make_array(4,value=10.0,/double)

  flaash_obj=obj_new('flaash_batch', /anc_delete)

  ;���ô������������
  flaash_obj->SetProperty, $
    hyper = 0, $                     ;����Ϊ1����ʾ�߹��ף�����Ϊ0����ʾ�����
    radiance_file = radfile, $
    reflect_file = reffile_, $
    filter_func_filename = filter_func_filename, $
    filter_func_file_index = filter_func_file_index, $
    water_band_choice = 1.13, $
    red_channel = 3, $               ;0��ʾundefined��LC8�첨��Ϊ��4����
    green_channel = 2, $             ;0��ʾundefined��LC8�̲���Ϊ��3����
    blue_channel = 0, $              ;0��ʾundefined��LC8������Ϊ��2����
    water_retrieval = 0, $           ;Water Retrieval������0��ʾNo��1��ʾYes
    water_abs_channel = 0, $
    water_ref_channel = 0, $
    kt_upper_channel = 0, $          ;���ö̲�����2��SWIR 2��
    kt_lower_channel = 3, $          ;���ú첨�Σ�Red��
    kt_cutoff = 0.08, $              ;Maximum Upper Channel Reflectance
    kt_ratio = 0.500, $              ;Reflectance Ratio
    cirrus_channel = 0, $            ;0��ʾundefined
    modtran_directory = modtran_directory, $
    visvalue = 40.0000, $            ;�ܼ��ȣ�Ĭ��40km
    f_resolution = 5.0000, $
    day = day, $
    month = month, $
    year = year, $
    gmt = gmt, $
    latitude = latitude, $
    longitude = longitude, $
    sensor_altitude = sensor_altitude, $   ;�������߶�
    ground_elevation = ground_elevation, $ ;ƽ�����Σ���λkm
    view_zenith_angle = 180, $
    view_azimuth = 0, $
    atmosphere_model = atmosphere_model, $       ;����ģ�ͣ�0-SAW;1-MLW;2-U.S. Standard;3-SAS;4-MLS;5-T
    aerosol_model = aerosol_model, $             ;���ܽ�ģ�ͣ�0-No Aerosol;1-Rural;2-Maritime;3-Urban;4-Tropospheric
    multiscatter_model = 2, $
    disort_streams = 8, $
    co2mix = 390.0000, $
    water_column_multiplier = 1.0000, $
    nspatial = nspatial, $
    nlines = nlines, $
    data_type = data_type, $
    margin1 = 0, $
    margin2 = 0, $
    nskip = 0, $
    pixel_size = pixel_size, $
;    sensor_name=sensor_name, $
    sensor_name='UNKNOWN-MSI', $
    aerosol_scaleht = 1.5000, $
    use_adjacency = 1, $             ;�и߷ֱ�������Ϊ1���ͷֱ��ʣ���Modis������Ϊ0
    output_scale = 10000.0000, $     ;����������ϵ��
    polishing_res = 0, $             ;��Ӧ Width (number of bands) ���������������0���ɡ�
    aerosol_retrieval = 0, $         ;0 ��ʾ None��1 ��ʾ 2-Band (K-T)��2 ��ʾ 2-Band Over Water
    calc_wl_correction = 0, $        ;��ӦFLAASH����е� Wavelength Recalibration�������һ��Ϊ0
    reuse_modtran_calcs = 0, $
    use_square_slit_function = 0, $
    convolution_method = 'fft', $
    use_tiling = 1, $                ;��ӦAdvanced Setting�е� Use Tiled Processing 1-Yes;0-No
    tile_size = 400.0, $
    wavelength_units = 'micron', $
    lambda = wavelength, $
    fwhm = fwhm, $
    input_scale = input_scale

  ;��ʼִ��FLAASH
  flaash_obj->processImage

  call_procedure, 'envi_file_mng', id=tfid, /remove, /delete
  obj_destroy, flaash_obj
  if ~file_test(reffile_) then begin
    error='Flaash����У��ʧ��!'
    return,0
  endif

  call_procedure, 'envi_open_file', reffile_, r_fid=tfid
  call_procedure, 'envi_file_query', tfid, dims=dims, ns=ns, nl=nl, nb=nb
  call_procedure, 'envi_output_to_external_format', $
    fid=tfid, $
    dims=dims, $
    pos=indgen(nb), $
    out_name=reffile, $
    /tiff
  call_procedure,'envi_file_mng', id=tfid, /remove, /delete
  if ~file_test(reffile) then begin
    error='����У�����תTIFF��ʽʧ��!'
    return,0
  endif
  
  return,1
end