c
c This program rewrite the compressed *.tar file with 3D fields
c generated by the model into the netcdf file.
c
c (C) 1999 Marat Khairoutdinov
c

	implicit none
	include '/usr/local/Cellar/netcdf/4.6.1_2/include/netcdf.inc'

c---------------------------------------------------------------
c variables:

	character(80) filename,long_name
	character(10) units
	character(8)  name
	character(1)  blank

	real(4),allocatable ::  byte(:)
	real(4),allocatable :: fld(:,:,:), fld_mean(:,:,:)
	real(4) fmax,fmin
	real(4) dx,dy,z(500),p(500),x(10000),y(10000),time

	integer nsubs,nsubsx,nsubsy,nx,nx_mean,ny,nz,nfields
	integer i,j,k,m,k1,k2,l,n,i0,j0,nx_gl,ny_gl,count,ifields

	integer vdimids(4), start(4), ndimids
	integer ncid,err,zid,yid,xid,timeid,varid,nmean

c External functions:

	integer iargc,strlen1
	external iargc,strlen1

	real fldmin, fldmax

c---------------------------------------------------------------

c
c Read the file-name from the comman line:
c
	i=COMMAND_ARGUMENT_COUNT()
	if(i.eq.0) then
	  print*,'Format: bin3D2nc_mean nmean  input.bin3D'
	  stop
	end if
        call getarg(1,name)
        read(name,*) nmean
	call getarg(2,filename)

c---------------------------------------------------------------
c Read files; merge data from different subdomains;
c save as a netcdf file.
c
	open(1,file=filename,status='old',form='unformatted')
	read(1) nx,ny,nz,nsubs,nsubsx,nsubsy,nfields
	do k=1,nz
	  read(1) z(k)
	end do
	do k=1,nz
	  read(1) p(k)
	end do
	read(1) dx
	read(1) dy
	read(1) time

	print*,'nx,ny,nz,nsubs,nsubsx,nsubsy,nfields:'
	print*,nx,ny,nz,nsubs,nsubsx,nsubsy,nfields
	
	nx_gl=nx*nsubsx
	ny_gl=ny*nsubsy
	nx_mean = nx_gl/nmean
	print*,'nx_gl=',nx_gl
	print*,'ny_gl=',ny_gl

	do i=1,nx_gl/nmean
	 x(i) = dx*nmean*(i-1)
	end do
	do j=1,ny_gl
	 y(j) = dy*(j-1)
	end do

	  allocate (byte(nx*ny*nz), fld(nx_gl,ny_gl,nz))
          allocate (fld_mean(nx_gl/nmean,ny_gl,nz))

c
c The output filename:

	do i=1,76
	  if(filename(i:i+5).eq.'.bin3D') then
	    filename(i:i+5)='.nc   '
	    EXIT
	  else if(i.eq.76) then
	    print*,'wrong filename extension!'
	    stop
	  endif
	end do

c
c Initialize netcdf stuff, define variables,etc.
c
	err = NF_CREATE(filename, NF_CLOBBER, ncid)
	err = NF_REDEF(ncid)

	err = NF_DEF_DIM(ncid, 'x', nx_mean, xid)
	if(ny_gl.ne.1)err = NF_DEF_DIM(ncid, 'y', ny_gl, yid)
	err = NF_DEF_DIM(ncid, 'z', nz, zid)
	err = NF_DEF_DIM(ncid, 'time', NF_UNLIMITED, timeid)

        err = NF_DEF_VAR(ncid, 'x', NF_FLOAT, 1, xid, varid)
	err = NF_PUT_ATT_TEXT(ncid,varid,'units',1,'m')
	if(ny_gl.ne.1) then
         err = NF_DEF_VAR(ncid, 'y', NF_FLOAT, 1, yid, varid)
	 err = NF_PUT_ATT_TEXT(ncid,varid,'units',1,'m')
	endif
        err = NF_DEF_VAR(ncid, 'z', NF_FLOAT, 1, zid, varid)
	err = NF_PUT_ATT_TEXT(ncid,varid,'units',1,'m')
        err = NF_PUT_ATT_TEXT(ncid,varid,'long_name',6,'height')
        err = NF_DEF_VAR(ncid, 'time', NF_FLOAT, 1, timeid, varid)
	err = NF_PUT_ATT_TEXT(ncid,varid,'units',1,'day')
        err = NF_PUT_ATT_TEXT(ncid,varid,'long_name',4,'time')
        err = NF_DEF_VAR(ncid, 'p', NF_FLOAT, 1, zid,varid)
	err = NF_PUT_ATT_TEXT(ncid,varid,'units',2,'mb')
        err = NF_PUT_ATT_TEXT(ncid,varid,'long_name',8,'pressure')

	err = NF_ENDDEF(ncid)

	err = NF_INQ_VARID(ncid,'x',varid)
	err = NF_PUT_VAR_REAL(ncid, varid, x)
	if(ny_gl.ne.1) then
	err = NF_INQ_VARID(ncid,'y',varid)
	err = NF_PUT_VAR_REAL(ncid, varid, y)
	endif
	err = NF_INQ_VARID(ncid,'z',varid)
	err = NF_PUT_VAR_REAL(ncid, varid, z)
	err = NF_INQ_VARID(ncid,'time',varid)
	err = NF_PUT_VAR1_REAL(ncid, varid, 1,time)
	err = NF_INQ_VARID(ncid,'p',varid)
	err = NF_PUT_VAR_REAL(ncid, varid, p)

	if(ny_gl.ne.1) then
	 ndimids=4
	 vdimids(1) = xid
	 vdimids(2) = yid
	 vdimids(3) = zid
	 vdimids(4) = timeid
	else
	 ndimids=3
	 vdimids(1) = xid
	 vdimids(2) = zid
	 vdimids(3) = timeid
	endif
	
	ifields=0

	do while(ifields.lt.nfields)
	
	  read(1) name,blank,long_name,blank,units
	  print*,long_name
	  do n=0,nsubs-1
	   
     	    read(1) (byte(k),k=1,nx*ny*nz)

	    j0 = n/nsubsx 
	    i0 = n - j0*nsubsx	
	    i0 = i0 * (nx_gl/nsubsx) 
	    j0 = j0 * (ny_gl/nsubsy)  
	    count=0
	    do k=1,nz
	     do j=1+j0,ny+j0
	      do i=1+i0,nx+i0
		count=count+1
		fld(i,j,k)=byte(count)
	      end do
	     end do
	    end do

	  end do ! n

	  do m=1,nz
          do j=1,ny
           do k=1,nx_mean
             i=1+(k-1)*nmean
             fld_mean(k,j,m) = 0.
             l = 0
             do n=max(1,i-nmean/2),min(nx_gl,i+nmean/2)
                fld_mean(k,j,m)=fld_mean(k,j,m)+fld(n,j,m)
                l = l+1
             end do
             fld_mean(k,j,m)=fld_mean(k,j,m)/float(l)
           end do
          end do
	  end do



	  ifields=ifields+1

	  err = NF_REDEF(ncid)
          err = NF_DEF_VAR(ncid,name, NF_FLOAT, ndimids, vdimids, varid)
	  err = NF_PUT_ATT_TEXT(ncid,varid,'long_name',
     &		strlen1(long_name),long_name(1:strlen1(long_name)))
	  err = NF_PUT_ATT_TEXT(ncid,varid,'units',
     &		strlen1(units),units(1:strlen1(units)))
	  err = NF_ENDDEF(ncid)
	  err = NF_PUT_VAR_REAL(ncid, varid, fld_mean)


	end do ! while


	err = NF_CLOSE(ncid)

	end
	




	integer function strlen1(str)
	character*(*) str
	strlen1=len(str)
	do i=1,len(str)
	  if(str(i:i).ne.' ') then
	    strlen1=strlen1-i+1
	    return
	  endif 
	end do
        return
	end
