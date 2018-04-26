# Don't forget:
# source activate rot-eof-dev
#
# Read and write Z500 for https://github.com/raybellwaves/rot-eof-dev
# 4/23/18

import xarray as xr


## Monthly data
#z500dir = '/projects/rsmas/kirtman/rxb826/DATA/ERA-I/gph500hPa_monthly/Regional_1deg/'
#da = xr.open_mfdataset(z500dir+'*NH.nc')
#da.to_netcdf('/projects/rsmas/kirtman/rxb826/DATA/ERA-I/gph500hPa_monthly/py_created/ERAI_z500_monthly_1999-2016.nc')
# Test opening
#da = xr.open_dataarray('/projects/rsmas/kirtman/rxb826/DATA/ERA-I/gph500hPa_monthly/py_created/ERAI_z500_monthly_1999-2016.nc')

## daily data
z500dir = '/projects/rsmas/kirtman/rxb826/DATA/ERA-I/gph500hPa_daily/Regional_1deg/'
da = xr.open_mfdataset(z500dir+'*NH.nc')
da.to_netcdf('/projects/rsmas/kirtman/rxb826/DATA/ERA-I/gph500hPa_monthly/py_created/ERAI_z500_daily_1999-2016.nc')
