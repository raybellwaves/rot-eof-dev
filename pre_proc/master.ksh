#!/bin/ksh
# /projects/rsmas/kirtman/rxb826/DATA/ERA-I/gph500hPa_monthly/master.ksh
# bsub < master_submit.sh
# 7/20/17

# First get the ERA-I monthly mean data from Reading or the ECWMF api

var=gph500hPa
res=1deg

if [[ ${res} == 1deg ]];then
    convertto360181=0
fi
extractregion=1
globalseasonalaverage=0
seasonalaverage=0

# Region 
#lonw=260.0
#lone=30.0
#lats=0.0
#latn=80.0
#regionname=NAtl
#lonw=280.0
#lone=40.0
#lats=20.0
#latn=90.0
#regionname=NAO_region
lonw=0.0
lone=360.0
lats=20.0
latn=90.0
regionname=NH

# Seasonalaverage
savgname=DJFmean

if [[ ${convertto360181} -eq 1 ]];then
    mkdir -p files_${res}
    cd files_${res}
    mkdir -p batch_files
    mkdir -p logs
    rm batch_files/*
    rm logs/*

if [ ! -f batch_files/mygrid_1deg ];then
cat > batch_files/mygrid_1deg << EOF
gridtype = lonlat
xsize    = 360
ysize    = 181
xfirst   = 0.0
xinc     = 1
yfirst   = -90.0
yinc     = 1
EOF
fi

    # counter
    fileref=0
    for year in {1999..2016}; do
        for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
            rm -rf batch_files/file_${fileref}.ksh
            echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
            chmod u+x batch_files/file_${fileref}.ksh
            # Interpolate from to 181x360
            echo "cdo remapbil,batch_files/mygrid_1deg ../raw_files/${var}_${year}${month}.nc ${var}_${year}${month}.nc" >> batch_files/file_${fileref}.ksh

            # Submit script
            rm -rf batch_files/file_${fileref}_submit.sh
            echo "#BSUB -o logs/file_${fileref}.out" > batch_files/file_${fileref}_submit.sh 
            echo "#BSUB -e logs/file_${fileref}.err" >> batch_files/file_${fileref}_submit.sh 
            echo "#BSUB -W 0:02" >> batch_files/file_${fileref}_submit.sh 
            echo "#BSUB -q general" >> batch_files/file_${fileref}_submit.sh
            echo "#BSUB -n 1" >> batch_files/file_${fileref}_submit.sh   
            echo "#" >> batch_files/file_${fileref}_submit.sh
            echo "batch_files/file_${fileref}.ksh" >> batch_files/file_${fileref}_submit.sh

            # Check that the file hasn't been created
            if [[ ! -f ${var}_${year}${month}.nc ]]; then
                echo "creating file ${var}_${year}${month}.nc"
                bsub < batch_files/file_${fileref}_submit.sh
                let fileref=$fileref+1
            else
                echo "file ${var}_${year}${month}.nc exists"
            fi
        # End month loop
        done
    # End year loop
    done 
fi

if [[ ${extractregion} -eq 1 ]];then
    mkdir -p Regional_${res}
    cd Regional_${res}
    mkdir -p batch_files
    mkdir -p logs
    rm batch_files/*
    rm logs/*
    # counter
    fileref=0
    for year in {1999..2016}; do
        for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
            rm -rf batch_files/file_${fileref}.ksh
            echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
            chmod u+x batch_files/file_${fileref}.ksh
            # Extract region
            echo "ncks -O -d lon,${lonw},${lone} -d lat,${lats},${latn} ../files_${res}/${var}_${year}${month}.nc ${var}_${year}${month}_${regionname}.nc" >> batch_files/file_${fileref}.ksh

            # Submit script
            rm -rf batch_files/file_${fileref}_submit.sh
            echo "#BSUB -o logs/file_${fileref}.out" > batch_files/file_${fileref}_submit.sh 
            echo "#BSUB -e logs/file_${fileref}.err" >> batch_files/file_${fileref}_submit.sh 
            echo "#BSUB -W 0:02" >> batch_files/file_${fileref}_submit.sh 
            echo "#BSUB -q general" >> batch_files/file_${fileref}_submit.sh
            echo "#BSUB -n 1" >> batch_files/file_${fileref}_submit.sh   
            echo "#" >> batch_files/file_${fileref}_submit.sh
            echo "batch_files/file_${fileref}.ksh" >> batch_files/file_${fileref}_submit.sh

            # Check that the file hasn't been created
            if [[ ! -f ${var}_${year}${month}_${regionname}.nc ]]; then
                echo "creating file ${var}_${year}${month}_${regionname}.nc"
                bsub < batch_files/file_${fileref}_submit.sh
                let fileref=$fileref+1
            else
                echo "file ${var}_${year}${month}_${regionname}.nc exists"
            fi
        # End month loop
        done
    # End year loop
    done 
fi

if [[ ${globalseasonalaverage} -eq 1 ]];then
    mkdir -p Global_${res}_seasonal
    cd Global_${res}_seasonal
    mkdir -p batch_files
    mkdir -p logs
    rm batch_files/*
    rm logs/*

    # counter
    fileref=0
    for year in {1994..2010}; do
        year2=`expr $year + 1`
        rm -rf batch_files/file_${fileref}.ksh
        echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
        chmod u+x batch_files/file_${fileref}.ksh
        # Concat and avearge
        if [[ ${savgname} == DJFmean ]];then
            echo "ncrcat -O ../files_${res}/${var}_${year}12.nc ../files_${res}/${var}_${year2}01.nc ../files_${res}/${var}_${year2}02.nc ${var}_${year}-${year2}_DJF.nc" >> batch_files/file_${fileref}.ksh
            echo "ncra -O ${var}_${year}-${year2}_DJF.nc ${var}_${year}-${year2}_${savgname}.nc" >> batch_files/file_${fileref}.ksh
        fi

        # Submit script
        rm -rf batch_files/file_${fileref}_submit.sh
        echo "#BSUB -o logs/file_${fileref}.out" > batch_files/file_${fileref}_submit.sh
        echo "#BSUB -e logs/file_${fileref}.err" >> batch_files/file_${fileref}_submit.sh
        echo "#BSUB -W 0:02" >> batch_files/file_${fileref}_submit.sh
        echo "#BSUB -q general" >> batch_files/file_${fileref}_submit.sh
        echo "#BSUB -n 1" >> batch_files/file_${fileref}_submit.sh
        echo "#" >> batch_files/file_${fileref}_submit.sh
        echo "batch_files/file_${fileref}.ksh" >> batch_files/file_${fileref}_submit.sh

        # Check that the file hasn't been created
        if [[ ! -f ${var}_${year}-${year2}_${savgname}.nc ]]; then
            echo "creating file ${var}_${year}-${year2}_${savgname}.nc"
            bsub < batch_files/file_${fileref}_submit.sh
            let fileref=$fileref+1
        else
            echo "file ${var}_${year}-${year2}_${savgname}.nc exists"
        fi
    # End year loop
    done
fi

if [[ ${seasonalaverage} -eq 1 ]];then
    mkdir -p Regional_${res}_seasonal
    cd Regional_${res}_seasonal
    mkdir -p batch_files
    mkdir -p logs
    rm batch_files/*
    rm logs/*
    # counter
    fileref=0
    for year in {1994..2010}; do
        year2=`expr $year + 1`
        rm -rf batch_files/file_${fileref}.ksh
        echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
        chmod u+x batch_files/file_${fileref}.ksh
        # Concat and avearge
        if [[ ${savgname} == DJFmean ]];then
            echo "ncrcat -O ../Regional_${res}/${var}_${year}12_${regionname}.nc ../Regional_${res}/${var}_${year2}01_${regionname}.nc ../Regional_${res}/${var}_${year2}02_${regionname}.nc ${var}_${year}-${year2}_DJF_${regionname}.nc" >> batch_files/file_${fileref}.ksh
            echo "ncra -O ${var}_${year}-${year2}_DJF_${regionname}.nc ${var}_${year}-${year2}_${savgname}_${regionname}.nc" >> batch_files/file_${fileref}.ksh
        fi

        # Submit script
        rm -rf batch_files/file_${fileref}_submit.sh
        echo "#BSUB -o logs/file_${fileref}.out" > batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -e logs/file_${fileref}.err" >> batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -W 0:02" >> batch_files/file_${fileref}_submit.sh 
        echo "#BSUB -q general" >> batch_files/file_${fileref}_submit.sh
        echo "#BSUB -n 1" >> batch_files/file_${fileref}_submit.sh   
        echo "#" >> batch_files/file_${fileref}_submit.sh
        echo "batch_files/file_${fileref}.ksh" >> batch_files/file_${fileref}_submit.sh

        # Check that the file hasn't been created
        if [[ ! -f ${var}_${year}-${year2}_${savgname}_${regionname}.nc ]]; then
            echo "creating file ${var}_${year}-${year2}_${savgname}_${regionname}.nc"
            bsub < batch_files/file_${fileref}_submit.sh
            let fileref=$fileref+1
        else
            echo "file ${var}_${year}-${year2}_${savgname}_${regionname}.nc exists"
        fi      
    # End year loop
    done 
fi

