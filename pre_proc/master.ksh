#!/bin/ksh
# Get gph500hPa data from NCEP
# source activate rot-eof-dev
# 5/2/18

ddir=ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/pressure/
fname=hgt

getdata=0
extractregion=0
createmonthly=0
createfilewithallmons=1

lonw=0.0
lone=360.0
lats=20.0
latn=90.0
regionname=NH

if [[ ${getdata} -eq 1 ]];then
    mkdir -p raw_files
    cd raw_files
    mkdir -p batch_files
    mkdir -p logs
    rm batch_files/*
    rm logs/*

    # counter
    fileref=0
    # Do in two chunks as file download limit is 30
    for year in {1950..1975}; do
    #for year in {1976..2000}; do
    #for year in {1950..2000}; do
        rm -rf batch_files/file_${fileref}.ksh
        echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
        chmod u+x batch_files/file_${fileref}.ksh
        echo "wget ${ddir}${fname}.${year}.nc" >> batch_files/file_${fileref}.ksh
        # Extract pressure level of interest
        echo "ncks -O -d level,5 ${fname}.${year}.nc ${fname}.${year}.nc" >> batch_files/file_${fileref}.ksh
        echo "ncwa -O -a level ${fname}.${year}.nc ${fname}.${year}.nc" >> batch_files/file_${fileref}.ksh

        # Submit script
        rm -rf batch_files/file_${fileref}_submit.sh
        echo "#BSUB -o logs/file_${fileref}.out" > batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -e logs/file_${fileref}.err" >> batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -W 1:00" >> batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -q general" >> batch_files/file_${fileref}_submit.sh
        echo "#BSUB -n 1" >> batch_files/file_${fileref}_submit.sh   
        echo "#" >> batch_files/file_${fileref}_submit.sh
        echo "batch_files/file_${fileref}.ksh" >> batch_files/file_${fileref}_submit.sh

        # Check that the file hasn't been created
        if [[ ! -f ${fname}.${year}.nc ]]; then
        echo "creating file ${fname}.${year}.nc"
            bsub < batch_files/file_${fileref}_submit.sh
            let fileref=$fileref+1
        else
            echo "file ${fname}.${year}.nc exists"
        fi 
    done
fi


if [[ ${extractregion} -eq 1 ]];then
    mkdir -p Regional
    cd Regional
    mkdir -p batch_files
    mkdir -p logs
    rm batch_files/*
    rm logs/*
    # counter
    fileref=0
    for year in {1950..2000}; do
        rm -rf batch_files/file_${fileref}.ksh
        echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
        chmod u+x batch_files/file_${fileref}.ksh
        # Extract region
        echo "ncks -O -d lon,${lonw},${lone} -d lat,${lats},${latn} ../raw_files/${fname}.${year}.nc ${fname}.${year}_${regionname}.nc" >> batch_files/file_${fileref}.ksh

        # Submit script
        rm -rf batch_files/file_${fileref}_submit.sh
        echo "#BSUB -o logs/file_${fileref}.out" > batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -e logs/file_${fileref}.err" >> batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -W 0:10" >> batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -q general" >> batch_files/file_${fileref}_submit.sh
        echo "#BSUB -n 1" >> batch_files/file_${fileref}_submit.sh   
        echo "#" >> batch_files/file_${fileref}_submit.sh
        echo "batch_files/file_${fileref}.ksh" >> batch_files/file_${fileref}_submit.sh

        # Check that the file hasn't been created
        if [[ ! -f ${fname}.${year}_${regionname}.nc ]]; then
            echo "creating file ${fname}.${year}_${regionname}.nc"
            bsub < batch_files/file_${fileref}_submit.sh
            let fileref=$fileref+1
        else
            echo "file ${fname}.${year}_${regionname}.nc exists"
        fi
    done 
fi


if [[ ${createmonthly} -eq 1 ]];then
    mkdir -p Regional_monthly
    cd Regional_monthly
    mkdir -p batch_files
    mkdir -p logs
    rm batch_files/*
    rm logs/*
    # counter
    fileref=0
    for year in {1950..2000}; do
        rm -rf batch_files/file_${fileref}.ksh
        echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
        chmod u+x batch_files/file_${fileref}.ksh
        # Resample to monthly data
        rm -rf batch_files/file_${fileref}.py
cat > batch_files/file_${fileref}.py << EOF
import xarray as xr
ds = xr.open_dataset('../Regional/${fname}.${year}_${regionname}.nc', engine='h5netcdf')
da = ds['hgt']
da_mon = da.resample(freq='M', dim='time', how='mean')
da_mon.to_netcdf(path='${fname}.${year}_${regionname}.nc', mode='w')
EOF

        echo "python batch_files/file_${fileref}.py" >> batch_files/file_${fileref}.ksh

        # Submit script
        rm -rf batch_files/file_${fileref}_submit.sh
        echo "#BSUB -o logs/file_${fileref}.out" > batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -e logs/file_${fileref}.err" >> batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -W 0:01" >> batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -q general" >> batch_files/file_${fileref}_submit.sh
        echo "#BSUB -n 1" >> batch_files/file_${fileref}_submit.sh   
        echo "#" >> batch_files/file_${fileref}_submit.sh
        echo "batch_files/file_${fileref}.ksh" >> batch_files/file_${fileref}_submit.sh

        # Check that the file hasn't been created
        if [[ ! -f ${fname}.${year}_${regionname}.nc ]]; then
            echo "creating file ${fname}.${year}_${regionname}.nc"
            bsub < batch_files/file_${fileref}_submit.sh
            let fileref=$fileref+1
        else
            echo "file ${fname}.${year}_${regionname}.nc exists"
        fi
    done 
fi

if [[ ${createfilewithallmons} -eq 1 ]];then
    mkdir -p pycreated
    cd pycreated
    mkdir -p batch_files
    mkdir -p logs
    rm batch_files/*
    rm logs/*
        
    # counter
    fileref=0
    rm -rf batch_files/file_${fileref}.ksh
    echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
    chmod u+x batch_files/file_${fileref}.ksh
    rm -rf batch_files/file_${fileref}.py
cat > batch_files/file_${fileref}.py << EOF
import xarray as xr
da = xr.open_mfdataset('../Regional_monthly/*NH.nc')
da.to_netcdf('NCEP_z500_monthly_1950-2000.nc')
EOF

    echo "python batch_files/file_${fileref}.py" >> batch_files/file_${fileref}.ksh

    # Submit script
    rm -rf batch_files/file_${fileref}_submit.sh
    echo "#BSUB -o logs/file_${fileref}.out" > batch_files/file_${fileref}_submit.sh 
    echo "#BSUB -e logs/file_${fileref}.err" >> batch_files/file_${fileref}_submit.sh 
    echo "#BSUB -W 0:01" >> batch_files/file_${fileref}_submit.sh 
    echo "#BSUB -q general" >> batch_files/file_${fileref}_submit.sh
    echo "#BSUB -n 1" >> batch_files/file_${fileref}_submit.sh   
    echo "#" >> batch_files/file_${fileref}_submit.sh
    echo "batch_files/file_${fileref}.ksh" >> batch_files/file_${fileref}_submit.sh

    if [[ ! -f NCEP_z500_monthly_1950-2000.nc ]]; then
        echo "creating file NCEP_z500_monthly_1950-2000.nc"
        bsub < batch_files/file_${fileref}_submit.sh
    else
        echo "file NCEP_z500_monthly_1950-2000.nc exists"
    fi
fi
