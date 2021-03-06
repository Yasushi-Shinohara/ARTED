!
!  Ab-initio Real-Time Electron Dynamics Simulator, ARTED
!  Copyright (C) 2016  ARTED developers
!
!  This file is part of Occupation_Redistribution.f90.
!
!  Occupation_Redistribution.f90 is free software: you can redistribute it and/or modify
!  it under the terms of the GNU General Public License as published by
!  the Free Software Foundation, either version 3 of the License, or
!  (at your option) any later version.
!
!  Occupation_Redistribution.f90 is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!
!  You should have received a copy of the GNU General Public License
!  along with Occupation_Redistribution.f90.  If not, see <http://www.gnu.org/licenses/>.
!
!This file is "Occupation_Redistribution.f90"
!This file contain a subroutine.
!Subroutine Occupation_Redistribution
!--------10--------20--------30--------40--------50--------60--------70--------80--------90--------100-------110-------120--------130
Subroutine Occupation_Redistribution
  use Global_Variables
  implicit none
  integer,parameter :: NFSset=100,Nvc_min=1 !Nvc_min:number of primitive cell in our orthorhombic unit cell
  integer :: i,j,k,ib,ik
  real(8) :: EFermi_min,EFermi_max,EFermi
  integer :: Nv,Nc,Nv_above,Nc_below
  integer,allocatable :: kv(:),kc(:),bv(:),bc(:)
  real(8),allocatable :: espv(:),espc(:)

  if(Myrank == 0) then
    write(*,*) '-----------------------------------------------'
    write(*,*) '-----------------------------------------------'
    write(*,*) 'occupation redistribution is called'
    write(*,*) 'Bottom of VB',minval(esp_vb_min(:))
    write(*,*) 'Top of VB',maxval(esp_vb_max(:))
    write(*,*) 'Bottom of CB',minval(esp_cb_min(:))
    write(*,*) 'Top of CB',maxval(esp_cb_max(:))
    write(*,*) 'The Bandgap',minval(esp_cb_min(:))-maxval(esp_vb_max(:))
    write(*,*) 'BG between same k-point',minval(esp_cb_min(:)-esp_vb_max(:))
    write(*,*) 'Physicaly upper bound of CB for DOS',minval(esp_cb_max(:))
    write(*,*) 'Physicaly upper bound of CB for eps(omega)',minval(esp_cb_max(:)-esp_vb_min(:))
    write(*,*) '-----------------------------------------------'
    write(*,*) '-----------------------------------------------'
  end if
!Counting unphysical orbitals
  Nv=0; Nc=0
  EFermi_min=minval(esp_cb_min(:)); EFermi_max=maxval(esp_vb_max(:))
  do ik=1,NK
    do ib=1,NBocc(ik)
      if(esp(ib,ik) > EFermi_min) then
        Nv=Nv+1
      end if
    end do
    do ib=NBocc(ik)+1,NB
      if(esp(ib,ik) < EFermi_max) then
        Nc=Nc+1
      end if
    end do
  end do
  if(Myrank == 0) then
    write(*,*) '# of valence electron above EFermi_min',Nv
    write(*,*) '# of conduction electron below EFermi_max',Nc
  end if
!When cubic cell contain Nvc_min primitive cell,eigenvalues should be Nvc_min-fold degeneracy.
  if(Nv < Nvc_min .or. Nc < Nvc_min) then
    if(Myrank == 0) then
      write(*,*) '=============================================================='
      write(*,*) 'occupation redistribution is not needed for too small Nv or Nc'
      write(*,*) '=============================================================='
    end if
    return
  end if

  allocate(kv(Nv),kc(Nc),bv(Nv),bc(Nc),espv(Nv),espc(Nc))
!Storing information(ib,ik,esp(ib,ik)) for the unphysical orbitals
  i=0;j=0
  do ik=1,NK
    do ib=1,NBocc(ik)
      if (esp(ib,ik) > EFermi_min) then
        i=i+1
        kv(i)=ik; bv(i)=ib; espv(i)=esp(ib,ik)
      end if
    end do
    do ib=NBocc(ik)+1,NB
      if (esp(ib,ik) < EFermi_max) then
        j=j+1
        kc(j)=ik; bc(j)=ib; espc(j)=esp(ib,ik)
      end if
    end do
  end do
  if((i/=Nv).or.(j/=Nc))  call err_finalize('Ccc. Redis. error')
!Finding Fermi energy(EFermi)
  do k=1,NFSset
    EFermi=0.5d0*(EFermi_min+EFermi_max)
    Nv_above=0; Nc_below=0
    do i=1,Nv
      if (espv(i)>EFermi) Nv_above=Nv_above+nint(wk(kv(i)))
    end do
    do i=1,Nc
      if (espc(i)<EFermi) Nc_below=Nc_below+nint(wk(kc(i)))
    end do
    if(Myrank == 0) then
      write(*,*)'Nv_above,Nc_below =',Nv_above,Nc_below
    end if
    if(Nv_above==Nc_below) then
      go to 10
    else if(Nv_above > Nc_below) then
      EFermi_min=EFermi
    else if(Nv_above < Nc_below) then
      EFermi_max=EFermi
    end if
  end do
  call err_finalize('too long calcualtion')

!Changing occupation distribution
10 if (Myrank==0) write(*,*) 'EFermi =',EFermi
  do i=1,Nv
    if (espv(i)>EFermi) then
      NBocc(kv(i))=NBocc(kv(i))-1
    end if
  end do
  do i=1,Nc
    if (espc(i)<EFermi) then
      NBocc(kc(i))=NBocc(kc(i))+1
    end if
  end do
  do ik=1,NK
    occ(1:NBocc(ik),ik)=2.d0/NKxyz*wk(ik)
    occ(NBocc(ik)+1:NB,ik)=0.d0
  end do
  NBoccmax=maxval(NBocc(:))
  if (Myrank==0) then
    if (2*nint(sum(NBocc(:)*wk(:)))/=Nelec*NKxyz) call err_finalize('NBocc(ik) are inconsistent')
    write(*,*) 'NBoccmax became ',NBoccmax
    write(*,*) 'Ne_tot =',sum(occ)
  end if
  deallocate(kv,kc,bv,bc,espv,espc)

  deallocate(zu)
  allocate(zu(NL,NBoccmax,NK_s:NK_e))
  deallocate(ik_table,ib_table)
  NKB=(NK_e-NK_s+1)*NBoccmax ! sato
  allocate(ik_table(NKB),ib_table(NKB)) ! sato
! make ik-ib table ! sato
  i=0
  do ik=NK_s,NK_e
    do ib=1,NBoccmax
      i=i+1
      ik_table(i)=ik
      ib_table(i)=ib
    end do
  end do

  return
End Subroutine Occupation_Redistribution
