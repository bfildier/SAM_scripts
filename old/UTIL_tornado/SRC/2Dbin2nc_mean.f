c
c (C) 2000 Marat Khairoutdinov
c

	implicit none
	include '/usr/local/Cellar/netcdf/4.6.1_2/include/netcdf.inc'

c---------------------------------------------------------------
c variables:

	character(80) filename,filename1,long_name
	character(10) units
	character(8)  name
	character(1)  blank

	integer nmean
	real(4), allocatable :: byte(:)
	real(4), allocatable  :: fld(:,:), fld_mean(:,:)
	real fmax,fmin,dday,day0,time_max, timeskip1,timeskip2
	real dx,dy,x(100000),y(100000),time
	logical condition
	integer nsubs,nsubsx,nsubsy,nx,ny,nz,nx_mean,nfields,nstep
	integer i,j,k,k1,k2,n,l,i0,j0,nx_gl,ny_gl,length,ifields

	integer vdimids(3),start(3),count(3),ndimids,nfile
	integer ncid,err,yid,xid,timeid,ntime,varrr
	integer nrecords

c External functions:

	integer iargc,strlen1
	external iargc,strlen1

	real fldmin, fldmax

	dday=300./86400.
	time_max = 592.
	timeskip1=263.49
	timeskip2=264.00

	nrecords = 1000
c---------------------------------------------------------------
c---------------------------------------------------------------
c
c Read the file-name from the comman line:
c
	i=COMMAND_ARGUMENT_COUNT()
	if(i.le.1) then
	  print*,'Format: 2Dbin2nc_mean nmean input.2Dbin'
	  stop
	end if
	call getarg(1,name)
	read(name,*) nmean
	call getarg(2,filename)
	print*,'nmean=',nmean
c---------------------------------------------------------------
c Read files; merge data from different subdomains;
c save as a netcdf file.
c
	open(1,file=filename,status='old',form='unformatted')


	ntime=1
	nfile=1

      do while(.true.) ! infinit loop 

c
c The output filename:

        condition=mod(ntime-1,nrecords).eq.0
        if(condition) then
 	  filename1=filename
          do i=1,76
            if(filename1(i:i+5).eq.'.2Dbin') then
              if(nfile.lt.10) then
              write(filename1(i+6:i+12),'(a1,i1,a3)') '_',nfile,'.nc'
              else if(nfile.lt.100) then
              write(filename1(i+6:i+13),'(a1,i2,a3)') '_',nfile,'.nc'
              else if(nfile.lt.1000) then
              write(filename1(i+6:i+14),'(a1,i3,a3)') '_',nfile,'.nc'
              end if
	      print*,filename1
	      if(nfile.ne.1) err = NF_CLOSE(ncid)
	      ntime=1
              nfile=nfile+1
	      EXIT
	    else if(i.eq.76) then
	      print*,'filename with a wrong extension!'
	      stop
            endif
          end do
        end if

	read(1,end=3333,err=3333) nstep
	read(1) nx,ny,nz,nsubs,nsubsx,nsubsy,nfields
	read(1) dx
	read(1) dy
	read(1) time

	if(time.gt.time_max) goto 3333

	print*,'nx,ny,nz,nsubs,nsubsx,nsubsy,nfields:'
	print*,nx,ny,nz,nsubs,nsubsx,nsubsy,nfields
	
	nx_gl=nx*nsubsx
	ny_gl=ny*nsubsy
	nx_mean = nx_gl/nmean

	if(condition) then
	 print*,'nx_gl=',nx_gl, '    dx=',dx
	 print*,'nx_mean=',nx_mean, '    dx=',dx*nmean
	 print*,'ny_gl=',ny_gl, '    dy=',dy
	end if

	do i=1,nx_gl/nmean
	 x(i) = dx*nmean*(i-1)
	end do
	do j=1,ny_gl
	 y(j) = dy*(j-1)
	end do

	if(ntime.eq.1.and.nfile.eq.2) then
	  allocate (byte(nx*ny), fld(nx_gl,ny_gl)) 
          allocate (fld_mean(nx_gl/nmean,ny_gl))
        end if
c
c Initialize netcdf stuff, define variables,etc.
c
       if(condition) then



	err = NF_CREATE(filename1, NF_CLOBBER, ncid)
	err = NF_REDEF(ncid)

	err = NF_DEF_DIM(ncid, 'x', nx_mean, xid)
	if(ny_gl.ne.1)err = NF_DEF_DIM(ncid, 'y', ny_gl, yid)
	err = NF_DEF_DIM(ncid, 'time', NF_UNLIMITED, timeid)

        err = NF_DEF_VAR(ncid, 'x', NF_FLOAT, 1, xid, varrr)
	err = NF_PUT_ATT_TEXT(ncid,varrr,'units',1,'m')
	if(ny_gl.ne.1) then
         err = NF_DEF_VAR(ncid, 'y', NF_FLOAT, 1, yid, varrr)
	 err = NF_PUT_ATT_TEXT(ncid,varrr,'units',1,'m')
	endif
        err = NF_DEF_VAR(ncid, 'time', NF_FLOAT, 1, timeid, varrr)
	err = NF_PUT_ATT_TEXT(ncid,varrr,'units',3,'day')
        err = NF_PUT_ATT_TEXT(ncid,varrr,'long_name',4,'time')

	err = NF_ENDDEF(ncid)

	err = NF_INQ_VARID(ncid,'x',varrr)
	err = NF_PUT_VAR_REAL(ncid, varrr, x)
	if(ny_gl.ne.1) then
	err = NF_INQ_VARID(ncid,'y',varrr)
	err = NF_PUT_VAR_REAL(ncid, varrr, y)
	endif

	end if ! condition


	if(ny_gl.ne.1) then
	 ndimids=3
	 vdimids(1) = xid
	 vdimids(2) = yid
	 vdimids(3) = timeid
	 start(1) = 1
         start(2) = 1
         start(3) = ntime 
	 count(1) = nx_mean
         count(2) = ny_gl
         count(3) = 1 
	else
	 ndimids=2
	 vdimids(1) = xid
	 vdimids(2) = timeid
	 start(1) = 1
         start(2) = ntime 
	 count(1) = nx_mean
         count(2) = 1 
	endif

	

	do ifields=1,nfields
	
         read(1) name,blank,long_name,blank,units

	  if(time.ge.timeskip1.and.time.le.timeskip2) then
	    do n=0,nsubs-1
	      read(1)
	    end do
	    cycle
	  end if


	  do n=0,nsubs-1
	  
     	    read(1) byte(1:nx*ny)

	    j0 = n/nsubsx 
	    i0 = n - j0*nsubsx	
	    i0 = i0 * (nx_gl/nsubsx) 
	    j0 = j0 * (ny_gl/nsubsy)  
	    length=0
	     do j=1+j0,ny+j0
	      do i=1+i0,nx+i0
		length=length+1
		fld(i,j)=  byte(length)
	      end do
	     end do

	  end do ! n

	  do j=1,ny
	   do k=1,nx_mean
	     i=1+(k-1)*nmean
	     fld_mean(k,j) = 0.
	     l = 0
	     do n=max(1,i-nmean/2),min(nx_gl,i+nmean/2) 
	        fld_mean(k,j)=fld_mean(k,j)+fld(n,j) 
	        l = l+1
	     end do
	     fld_mean(k,j)=fld_mean(k,j)/float(l)
	   end do
	  end do	

	 if(condition) then
	  err = NF_REDEF(ncid)
          err = NF_DEF_VAR(ncid,name,NF_FLOAT,
     &                           ndimids,vdimids,varrr)
	  err = NF_PUT_ATT_TEXT(ncid,varrr,'long_name',
     &		strlen1(long_name),long_name(1:strlen1(long_name)))
	  err = NF_PUT_ATT_TEXT(ncid,varrr,'units',
     &		strlen1(units),units(1:strlen1(units)))
          if(ifields.eq.1) then
	     name = 'LWNS'
             err = NF_DEF_VAR(ncid,name,NF_FLOAT,
     &                           ndimids,vdimids,varrr)
	     err = NF_PUT_ATT_TEXT(ncid,varrr,'long_name',4,'LWNS')
	     err = NF_PUT_ATT_TEXT(ncid,varrr,'units',4,'W/m2')
	     name = 'SWNS'
             err = NF_DEF_VAR(ncid,name,NF_FLOAT,
     &                           ndimids,vdimids,varrr)
	     err = NF_PUT_ATT_TEXT(ncid,varrr,'long_name',4,'SWNS')
	     err = NF_PUT_ATT_TEXT(ncid,varrr,'units',4,'W/m2')
          end if
	  err = NF_ENDDEF(ncid)
	 end if
	  
	
	 err = NF_INQ_VARID(ncid,name,varrr)
         err = NF_PUT_VARA_REAL(ncid,varrr,start,count,fld_mean)

	end do

	if(time.ge.timeskip1.and.time.le.timeskip2) cycle

	err = NF_INQ_VARID(ncid,'time',varrr)
        err = NF_PUT_VAR1_REAL(ncid,varrr,ntime,time)
        ntime=ntime+1

      end do ! while

 3333	continue


	deallocate (byte, fld, fld_mean)

	err = NF_CLOSE(ncid)

	end
	




	integer function strlen1(str)
	character*(*) str
	strlen1=len(str)
	do i=len(str),1,-1
	  if(str(i:i).ne.' ') then
	    strlen1=i
	    return
	  endif 
	end do
        return
	end
