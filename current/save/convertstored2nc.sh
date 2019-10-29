#! /bin/csh -f

# run this script to convert compressed files (extension .2Dcom, default format since files can be quite large)
# and binary (extension .2Dbin) to NETCDF files using 2Dcom2nc and 2Dbin2nc, and gcp to archive

#set liste =(  \
# SAM6103_301_RCE01  SAM6103_303_RCE01  SAM6103_305_RCE01 )
set liste =( \
 SAM6113_RCE_SST301d0p0r0 SAM6113_RCE_SST305d0p0r0 )

 set if3dfiles  = 0

echo "  "  ; echo " List of directories = " $liste ; echo " " 

foreach dirname ($liste)

 echo "dir $dirname : CONVERT OUTPUTS TO NETCDF"
 setenv OutputDirNameOnStore $dirname.0



# ---------------------------------------------------------------------------
# ----------------- you dont need to edit below this line -------------------
# ---------------------------------------------------------------------------
 # specify utility directory
 setenv UTIL_DIR $CCCSTOREDIR/../gen10314/UTIL6.11.3
 cd $CCCSTOREDIR/../gen10314/$OutputDirNameOnStore


 # convert 1D file
 cd OUT_STAT
 foreach file_name (./*.stat)
   echo "*** file $file_name ***"
   $UTIL_DIR/stat2nc $file_name
 end
 mv *.nc ../
 cd ..

 #convert 2D files
 cd OUT_2D
 foreach file_name (./*.2Dcom)
   echo "*** file $file_name ***"
   $UTIL_DIR/2Dcom2nc $file_name
 end
 mv *.nc ../
 cd ..

# #convert 3D files
 if ( $if3dfiles == 1 ) then
   cd OUT_3D 
   foreach file_name (./*.com3D)
     echo "*** file $file_name ***"
     $UTIL_DIR/com3D2nc $file_name
     set filename3d = $file_name
   end
   ncrcat *.nc $filename3d.alltimes.nc
   #ncrcat -v W,TABS,QV,QP,QN *.nc $filename3d.alltimes.nc #only extract those vars to make file lighter
   mv *.alltimes.nc ../
   cd ..
 endif



# # specify GFDL directory
# setenv GFDL_DIR /archive/cjm/SAMOutputs/$OutputDirNameOnArchive/
#
# gcp *.nc gfdl:$GFDL_DIR

 if !(-d NETCDF_files)           mkdir NETCDF_files
# if !(-d OUT_FILES_converted)    mkdir OUT_FILES_converted

 mv *.nc NETCDF_files/
# mv OUT_STAT/* OUT_FILES_converted/
# rm -rf OUT_STAT
# mv OUT_2D/* OUT_FILES_converted/
# rm -rf OUT_2D
# if ( $if3dfiles == 1  ) mv OUT_3D/* OUT_FILES_converted/
# if ( $if3dfiles == 1  ) rm -rf OUT_3D 
 cd ..  

end



