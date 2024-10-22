; Test rotating eofs and then learn how to do it in python
; 4/26/18

;Load functions
load "gsn_code.ncl"
load "gsn_csm.ncl"
load "contributed.ncl"

indir = "/projects/rsmas/kirtman/rxb826/DATA/NCEP/gph500hPa_monthly/raw_monthly_files/"

  vname  = "hgt"               ; variable name
  fname  = "NCEP_z500_monthly_1950-2000_NH.nc"

  levP   = 500                 ; desired level

  latS   =  20.                ; N. Hemisphere
  latN   =  90. 

  yrStrt = 1950
  yrLast = 2000

  season = "NDJ"               

  neof   =  10                 ; number of standard EOFs to calculate
  optEOF = False      
  optETS = False

fin = indir+fname
f = addfile(fin,"r")

  TIME   = f->time
  YYYY   = cd_calendar(TIME,-1)/100                 ; entire file
  iYYYY  = ind(YYYY.ge.yrStrt .and. YYYY.le.yrLast)

  VAR    = f->hgt
  printVarSummary(VAR)                              ; variable overview

  var    = month_to_season (VAR, season)
  printVarSummary(var)
  nyrs   = dimsizes(var&time)

  ; Calculated standardized anomalies although may not need to do that...
  var_std = dim_standardize_n_Wrap(var,1,0)
  print("var std")
  printVarSummary(var_std)
  printMinMax(var_std,True)
  
  rad    = 4.0*atan(1.0)/180.0
  clat   = cos(rad*var_std&lat)           
  clat   = where(clat.lt.0, 0.0, clat)  ; avoid a potential numerical issue at pole
  clat   = sqrt( clat )  ; avoid a potential numerical issue at pole

  wvar   = var_std                                   ; copy meta data
  wvar   = var_std*conform(var_std, clat, 1)
  ;wvar@long_name = "Wgt: "+wvar@long_name

  x      = wvar(lat|:,lon|:,time|:) ; wants time as right most
  printVarSummary(x)
  printMinMax(x,True)
  ;print(x)

  eof    = eofunc_Wrap(x, neof, optEOF) ; optEOF is flase
  printVarSummary( eof )
  print("eof: min="+min(eof)+"   max="+max(eof) )    
  eof_ts = eofunc_ts_Wrap (x, eof, optETS)
  print("eof size")
  print(dimsizes(eof)) 
  print("eof_ts size")
  print(dimsizes(eof_ts))

  eof_rot = eofunc_varimax_Wrap( eof, 1 )

  eofunc_varimax_reorder( eof_rot )
  printVarSummary( eof_rot )
  print("eof_rot: min="+min(eof_rot)+"   max="+max(eof_rot) )

  ; Get the location of maximum and minum of reof1 and reof2
  reof2 = eof_rot(1,:,:)
  ;printVarSummary( reof2 )
  ;printMinMax(reof2,True)
  ;print(dim_max(reof2))
  ;print(maxind(dim_max(reof2)))
  print(var_std&lat(maxind(dim_max(reof2))))
  print(var_std&lat(minind(dim_min(reof2))))

  print(var_std&lon(maxind(dim_max_n(reof2, 0))))
  print(var_std&lon(minind(dim_min_n(reof2, 0))))

;============================================================
; PLOTS
;============================================================

  wks = gsn_open_wks("png",season+"_eof")         ; send graphics to PNG file
  plot = new(neof,graphic)                ; create graphic array
                                          ; only needed if paneling
; EOF patterns

  res                      = True         
  res@gsnDraw              = False        ; don't draw yet
  res@gsnFrame             = False        ; don't advance frame yet
  res@gsnPolar             = "NH"

  res@mpFillOn             = False        ; turn off map fill
  res@mpMinLatF            = latS         ; zoom in on map
  res@mpMaxLatF            = latN

  res@cnFillOn             = True         ; turn on color fill
  res@cnFillPalette        = "BlWhRe"     ; choose colormap
  res@cnLinesOn            = False        ; True is default
  res@cnLineLabelsOn       = False        ; True is default
  res@lbLabelBarOn         = False        ; turn off individual lb's

                                          ; set symmetric plot min/max
  symMinMaxPlt(eof, 16, False, res)       ; contributed.ncl

; panel plot only resources
  resP                     = True         ; modify the panel plot
  resP@gsnMaximize         = True         ; large format
  resP@gsnPanelLabelBar    = True         ; add common colorbar

  resP@gsnPanelMainString  = "Classic EOFs: "+vname+": "+season+": "+1999+"-"+2016

;*******************************************
; Plot standard patterns
;*******************************************
  do n=0,neof-1
     res@gsnLeftString  = "EOF "+(n+1)
     res@gsnRightString = sprintf("%5.1f", eof@pcvar(n)) +"%"
     plot(n)=gsn_csm_contour_map_polar(wks,eof(n,:,:),res)
  end do
  gsn_panel(wks,plot(0:3),(/2,2/),resP)     ; only plot the 1st four
 ;gsn_panel(wks,plot,(/neof/2,2/),resP)     ; now draw as one plot

  wks = gsn_open_wks("png",season+"_rot_eof")         ; send graphics to PNG file
  plot = new(neof,graphic)                ; create graphic array
                                          ; only needed if paneling
; EOF patterns

  res                      = True         
  res@gsnDraw              = False        ; don't draw yet
  res@gsnFrame             = False        ; don't advance frame yet
  res@gsnPolar             = "NH"

  res@mpFillOn             = False        ; turn off map fill
  res@mpMinLatF            = latS         ; zoom in on map
  res@mpMaxLatF            = latN

  res@cnFillOn             = True         ; turn on color fill
  res@cnFillPalette        = "BlWhRe"     ; choose colormap
  res@cnLinesOn            = False        ; True is default
  res@cnLineLabelsOn       = False        ; True is default
  res@lbLabelBarOn         = False        ; turn off individual lb's

                                          ; set symmetric plot min/max
  symMinMaxPlt(eof, 16, False, res)       ; contributed.ncl

; panel plot only resources
  resP                     = True         ; modify the panel plot
  resP@gsnMaximize         = True         ; large format
  resP@gsnPanelLabelBar    = True         ; add common colorbar

;*******************************************
; Plot rotated patterns
;*******************************************
  resP@gsnPanelMainString  = "Varimax EOFs: "+vname+": "+season+": "+1999+"-"+2016
  do n=0,neof-1
     ; get location of max and min
     res@gsnLeftString     = "EOF "+(n+1)
     res@gsnRightString    = sprintf("%5.1f", eof_rot@pcvar_varimax(n)) +"%"
     plot(n)=gsn_csm_contour_map_polar(wks,eof_rot(n,:,:),res)
  end do

  ; Plot location of reof2
   ;latmaxloc = var_std&lat(maxind(dim_max(eof_rot(1,:,:))))
   ;latminloc = var_std&lat(minind(dim_min(eof_rot(1,:,:))))
   ;lonmaxloc = var_std&lon(maxind(dim_max_n(eof_rot(1,:,:), 0)))
   ;latminloc = var_std&lon(minind(dim_min_n(eof_rot(1,:,:), 0)))
   ;gsn_polymarker(wks,plot(1),lonmaxloc,latmaxloc,res)
                                       ; 
  gsn_panel(wks,plot(0:3),(/2,2/),resP)     ; now draw as one plot
 ;gsn_panel(wks,plot,(/neof/2,2/),resP)


