PROGRAM sra2nc
  !-------------------------------------------------------------------
  !  This is the main interface for the f90 preprocessor designed to
  !  deal with .SRA files that are the "dat" component of PlaSim. This
  !  program will read an input file with specifications for the file 
  !  to preprocess and convert from .SRA to .NC.
  !
  !  USES:
  !        IOmod -> input/output subroutines module (uses netcdf).
  !        CODEmat -> big array w var attributes and latlon array
  !
  !  Created: Mateo Duque Villegas
  !  Last updated: 16-Nov-2017
  !
  !-------------------------------------------------------------------
  USE IOmod
  USE CODEmat

  IMPLICIT NONE

  CHARACTER(LEN=100) :: root    ! Dir where .SRA is
  CHARACTER(LEN=100) :: sra     ! .SRA file name
  CHARACTER(LEN=100) :: srafile ! .SRA whole file name
  CHARACTER(LEN=100) :: inpnml  ! Input file name
  CHARACTER(LEN=100) :: ncfile  ! Output nc file
  INTEGER(KIND=4)    :: kcode   ! ECHAM code
  INTEGER(KIND=4)    :: unit    ! Namelist unit
  INTEGER(KIND=4)    :: nmon    ! Number of months in file
  INTEGER(KIND=4)    :: nlon    ! Number of longitudes
  INTEGER(KIND=4)    :: nlat    ! Number of latitudes
  INTEGER(KIND=4)    :: hcols   ! Number of cols in hdr
  INTEGER(KIND=4)    :: dcols   ! Number of cols in data matrix
  INTEGER(KIND=4)    :: operr   ! Open error variable
  INTEGER(KIND=4)    :: rderr   ! Read error variable
  INTEGER(KIND=4), ALLOCATABLE, DIMENSION(:,:)   :: ihead ! headrs arr
  INTEGER(KIND=4), ALLOCATABLE, DIMENSION(:)     :: vtime ! times arr
  REAL(KIND=8),    ALLOCATABLE, DIMENSION(:,:,:) :: data  ! data arr
  REAL(KIND=8),    ALLOCATABLE, DIMENSION(:)     :: lat   ! lats arr
  REAL(KIND=8),    ALLOCATABLE, DIMENSION(:)     :: lon   ! longs arr
  
  NAMELIST /INPUT_INFO/ root, sra, kcode, nlat, nlon, hcols, dcols,&
       & nmon 

  ! Read namelist file name with input variables from command line
  CALL GET_COMMAND_ARGUMENT(1, inpnml)

  ! Open namelist file to get variables and check for error
  OPEN (unit=1, file=TRIM(inpnml),status='old',iostat=operr)
  IF(operr>0) THEN
     WRITE(*,'(A)') "sra2nc: error: could not open namelist file."
     CALL EXIT(0)
  END iF
  
  READ (1,nml=INPUT_INFO,iostat=rderr)
  ! Read namelist file and check for error
  IF(rderr>0) THEN
     WRITE(*,'(A)') "sra2nc: error: could not read namelist file."
     CALL EXIT(0)
  END IF
  
  ! Allocate memory
  ALLOCATE(lat(nlat))
  ALLOCATE(lon(nlon))  
  ALLOCATE(ihead(hcols,nmon))
  ALLOCATE(data(nlon,nlat,nmon))
  ALLOCATE(vtime(nmon))

  ! .SRA file name.
  srafile = TRIM(ADJUSTL(root))//"/"//TRIM(ADJUSTL(sra))
  
  ! Read info in .SRA and save in ihead and data
  CALL sraReader(srafile,nmon,nlon,nlat,hcols,dcols,ihead,data)

  ! Create time vector
  IF (nmon == 1) THEN
     vtime = (/0/)
  ELSE
     vtime = (/-1,0,1,2,3,4,5,6,7,8,9,10,11,12/)
  END IF
  
  ! Get lats and lons (fixed, not computed)
  IF (nlat == 32) THEN
     CALL latlons32(nlat,nlon,lat,lon)
  ELSE IF (nlat == 64) THEN
     CALL latlons64(nlat,nlon,lat,lon)
  ELSE
     WRITE(*,'(A)') "sra2nc: error: unsopported latitude/longitude."
     CALL exit(0)
  END IF
  
  ! .SRA file name plus .NC extension.
  ncfile = "./"//TRIM(ADJUSTL(sra))//".nc"

  ! Create ncfile using ncgen from IOmod
  CALL ncgen(ncfile,kcode,vtime,lon,lat,data,nmon,nlon,nlat)     
          
  DEALLOCATE(lon)
  DEALLOCATE(lat)
  DEALLOCATE(data)
  DEALLOCATE(ihead)
  DEALLOCATE(vtime)  

END PROGRAM sra2nc
