#!/bin/ksh
# /projects/rsmas/kirtman/rxb826/DATA/ERA-I/gph500hPa_daily/_master.ksh
# bsub < _master_submit.sh
# 4/24/18

var=gph500hPa
res=1deg

if [[ ${res} == 1deg ]];then
    convertto360181=0
fi
extractregion=1

lonw=0.0
lone=360.0
lats=20.0
latn=90.0
regionname=NH

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

# Start date
year=1999
month=01
day=01

endyear=2017

# Counter
fileref=0

while [[ $year -lt ${endyear} ]]; do

   export date=${year}${month}${day}
   #echo "date is ${date}"

   rm -rf batch_files/file_${fileref}.ksh
   echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
   chmod u+x batch_files/file_${fileref}.ksh
   # Interpolate from to 181x360
   echo "cdo remapbil,batch_files/mygrid_1deg ../${var}_${date}.nc ${var}_${date}.nc" >> batch_files/file_${fileref}.ksh   

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
   if [[ ! -f ${var}_${date}.nc ]];then
       echo "creating file ${var}_${date}.nc"
       bsub < batch_files/file_${fileref}_submit.sh
       let fileref=$fileref+1
   else
       echo "file ${var}_${date}.nc exists"
   fi
   # Add one day
   datetmp=`date -d "${year}-${month}-${day} 1 days" +%Y-%m-%d`
   year=`echo $datetmp | awk -F'-' '{print $1}'`
   month=`echo $datetmp | awk -F'-' '{print $2}'`
   day=`echo $datetmp | awk -F'-' '{print $3}'`

# End loop over dates
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

    #start date
    year=1999
    month=01
    day=01

    endyear=2017
while [[ $year -lt ${endyear} ]]; do

   export date=${year}${month}${day}
   #echo "date is ${date}"

   rm -rf batch_files/file_${fileref}.ksh
   echo "#!/bin/ksh" > batch_files/file_${fileref}.ksh
   chmod u+x batch_files/file_${fileref}.ksh
   # Extract region
   echo "ncks -O -d lon,${lonw},${lone} -d lat,${lats},${latn} ../files_${res}/${var}_${date}.nc ${var}_${date}_${regionname}.nc" >> batch_files/file_${fileref}.ksh

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
   if [[ ! -f ${var}_${date}_${regionname}.nc ]];then
       echo "creating file ${var}_${date}_${regionname}.nc"
       bsub < batch_files/file_${fileref}_submit.sh
       let fileref=$fileref+1
   else
       echo "file ${var}_${date}_${regionname}.nc exists"
   fi
   # Add one day
   datetmp=`date -d "${year}-${month}-${day} 1 days" +%Y-%m-%d`
   year=`echo $datetmp | awk -F'-' '{print $1}'`
   month=`echo $datetmp | awk -F'-' '{print $2}'`
   day=`echo $datetmp | awk -F'-' '{print $3}'`
done
fi
