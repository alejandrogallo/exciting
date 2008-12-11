
! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: poteff
! !INTERFACE:
subroutine poteff
! !USES:
use modmain
! !DESCRIPTION:
!   Computes the effective potential by adding together the Coulomb and
!   exchange-correlation potentials. See routines {\tt potcoul} and {\tt potxc}.
!
! !REVISION HISTORY:
!   Created April 2003 (JKD)
!EOP
!BOC
implicit none
! local variables
integer is,ia,ias,ir,lm,lmmax
real(8) ts0,ts1
call timesec(ts0)
! compute the Coulomb potential
call potcoul

write(500+iscl,'(i8,g18.10)') (ir,vclir(ir),ir=1,ngrtot)
write(600+iscl,'(i8,g18.10)') (ir,vclir(igfft(ir)),ir=1,ngrtot)

! compute the exchange-correlation potential
call potxc
! add Coulomb and exchange-correlation potentials together
! muffin-tin part
do is=1,nspecies
  do ia=1,natoms(is)
    ias=idxas(ia,is)
    lmmax=lmmaxinr
    do ir=1,nrmt(is)
      if (ir.gt.nrmtinr(is)) lmmax=lmmaxvr
      do lm=1,lmmax
        veffmt(lm,ir,ias)=vclmt(lm,ir,ias)+vxcmt(lm,ir,ias)
      end do
      do lm=lmmax+1,lmmaxvr
        veffmt(lm,ir,ias)=0.d0
      end do
    end do
  end do
end do
! interstitial part
veffir(:)=vclir(:)+vxcir(:)
call timesec(ts1)
timepot=timepot+ts1-ts0
return
end subroutine
!EOC
