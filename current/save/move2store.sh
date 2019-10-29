#! /bin/csh -f

#----- README: 
#----- run this script to copy outputs from scratch ($SCRATCHDIR) to store (CCCSTOREDIR)
#----- Each time it is executed, a new output directory is created with the most recent scratch output folder.

#set liste =(  \
# SAM6103_301_RCE01  SAM6103_303_RCE01  SAM6103_305_RCE01 )

set liste =( \
 SAM6113_RCE_SST301d0p0r0 SAM6113_RCE_SST305d0p0r0 )

cd $CCCSTOREDIR/../gen10314

foreach dirname ($liste)

  echo  " dir $dirname "
 setenv OutputDirName $dirname


#--------------------------------------------------------#
#------ You dont need to edit below this line -----------# 
        echo "  **************************  "
        echo "  Bonjour from move2store.sh:   "
        set nrestart = 0
           while ( (-d $OutputDirName.$nrestart) != 0 ) 
           echo "  $nrestart th dir $OutputDirName.$nrestart exists"
           @ nrestart = $nrestart + 1
           end 
        echo "  **************************  "
        mkdir   $OutputDirName.$nrestart
        foreach subdir ( OUT_STAT OUT_2D OUT_3D OUT_MOMENTS OUT_MOVIES RESTART )
            cp -r $CCCSCRATCHDIR/../gen10314/$OutputDirName/$subdir $OutputDirName.$nrestart
        end 
        echo "  $OutputDirName.$nrestart did not exist, I created it."
        echo "  **************************  "

end



 
