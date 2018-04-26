; Test rotating eofs and then learn how to do it in python
; 4/26/18

;Load functions
load "gsn_code.ncl"
load "gsn_csm.ncl"
load "contributed.ncl"

  vname  = "gph500hPa"               ; variable name
  fname  = "ERAI_z500_monthly_1999-2016.nc"   ; CDC: NCEP Reanalysis

  levP   = 500                 ; desired level

  latS   =  20.                ; N. Hemisphere
  latN   =  90. 

  yrStrt = 1999
  yrLast = 2016

  season = "JFM"               ; choose Jan-Feb-Mar seasonal mean

  neof   =  10                 ; number of standard EOFs to calculate
  optEOF = False      
  optETS = False

indir = "/projects/rsmas/kirtman/rxb826/DATA/ERA-I/gph500hPa_monthly/py_created/"
fin = indir+fname
f = addfile(fin,"r")

  TIME   = f->time
  YYYY   = cd_calendar(TIME,-1)/100                 ; entire file
  iYYYY  = ind(YYYY.ge.yrStrt .and. YYYY.le.yrLast)

  VAR    = f->gph500hPa
  printVarSummary(VAR)                              ; variable overview

  var    = month_to_season (VAR, season)
  nyrs   = dimsizes(var&time)
  printVarSummary(var)
  print(nyrs)

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
  wvar@long_name = "Wgt: "+wvar@long_name

  x      = wvar(lat|:,lon|:,time|:)

  eof    = eofunc_Wrap(x, neof, optEOF) ; optEOF is flase
  print("eof: min="+min(eof)+"   max="+max(eof) )    
  eof_ts = eofunc_ts_Wrap (x, eof, optETS)
  print("eof size")
  print(dimsizes(eof)) 
  print("eof_ts size")
  print(dimsizes(eof_ts))

  eof_rot = eofunc_varimax_Wrap( eof, 1 )
  print("summary of eof_rot")
  printVarSummary( eof_rot )        
  print("eof_rot: min="+min(eof_rot)+"   max="+max(eof_rot) )

  eofunc_varimax_reorder( eof_rot )
  printVarSummary( eof_rot )

;============================================================
; PLOTS
;============================================================

  wks = gsn_open_wks("png","eof")         ; send graphics to PNG file
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

  wks = gsn_open_wks("png","rot_eof")         ; send graphics to PNG file
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
     res@gsnLeftString     = "EOF "+(n+1)
     res@gsnRightString    = sprintf("%5.1f", eof_rot@pcvar_varimax(n)) +"%"
     plot(n)=gsn_csm_contour_map_polar(wks,eof_rot(n,:,:),res)
  end do
                                       ; 
  gsn_panel(wks,plot(0:3),(/2,2/),resP)     ; now draw as one plot
 ;gsn_panel(wks,plot,(/neof/2,2/),resP)


