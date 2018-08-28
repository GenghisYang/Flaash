pro Example_56
  compile_opt idl2
  
  infile='G:\GF\GF-1\Beijing\GF1_WFV4_E116.9_N40.1_20180312_L1A0003056074\GF1_WFV4_E116.9_N40.1_20180312_L1A0003056074.tiff'
  reffile='F:\Flaash\Results\GF1_WFV4_E116.9_N40.1_20180312_L1A0003056074_Reflectance.tiff'
  ndvifile='F:\Flaash\Results\GF1_WFV4_E116.9_N40.1_20180312_L1A0003056074_NDVI.tiff'
  
  print,'Start time:',systime()
  
  ret=Preprocess(infile,reffile,error=error)
  if ret ne 1 then begin
    print,'����У��ʧ��!'
    return
  endif else begin
    print,'����У�����!'
  endelse  
  
  ret=GetNDVI(reffile,ndvifile,error=error)
  if ret ne 1 then begin
    print,'����NDVIʧ��!'
    return
  endif else begin
    print,'NDVI�������!'
  endelse
  
  print,'End time:',systime()
    
end