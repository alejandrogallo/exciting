





! Copyright (C) 2007 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: findsymcrys
! !INTERFACE:


subroutine findsymcrys
! !USES:
use modinput
use modmain
#ifdef XS
use modxs
#endif
! !DESCRIPTION:
!   Finds the complete set of symmetries which leave the crystal structure
!   (including the magnetic fields) invariant. A crystal symmetry is of the
!   form $\{\alpha_S|\alpha_R|{\bf t}\}$, where ${\bf t}$ is a translation
!   vector, $\alpha_R$ is a spatial rotation operation and $\alpha_S$ is a
!   global spin rotation. Note that the order of operations is important and
!   defined to be from right to left, i.e. translation followed by spatial
!   rotation followed by spin rotation. In the case of spin-orbit coupling
!   $\alpha_S=\alpha_R$. In order to determine the translation vectors, the
!   entire atomic basis is shifted so that the first atom in the smallest set of
!   atoms of the same species is at the origin. Then all displacement vectors
!   between atoms in this set are checked as possible symmetry translations. If
!   the global variable {\tt tshift} is set to {\tt .false.} then the shift is
!   not performed. See L. M. Sandratskii and P. G. Guletskii, {\it J. Phys. F:
!   Met. Phys.} {\bf 16}, L43 (1986) and the routine {\tt findsym}.
!
! !REVISION HISTORY:
!   Created April 2007 (JKD)
!EOP
!BOC
implicit none
! local variables
integer::ia, ja, is, js, i, n
integer::isym, nsym, iv(3)
integer::lspl(48), lspn(48)
real(8)::v(3), t1
real(8)::apl(3, maxatoms, maxspecies), aplt(3, maxatoms, maxspecies)

! allocatable arrays
integer, allocatable :: iea(:, :, :)
real(8), allocatable :: vtl(:, :)
! allocate local array
allocate(iea(natmmax, nspecies, 48))
! allocate equivalent atom arrays
if (allocated(ieqatom)) deallocate(ieqatom)
allocate(ieqatom(natmmax, nspecies, maxsymcrys))
if (allocated(eqatoms)) deallocate(eqatoms)
allocate(eqatoms(natmmax, natmmax, nspecies))
! find the smallest set of atoms
is=1
do js=1, nspecies
  if (natoms(js).lt.natoms(is)) is=js
end do
if ((input%structure%tshift).and.(natmtot.gt.0)) then
! shift basis so that the first atom in the smallest atom set is at the origin
  v(:)=input%structure%speciesarray(is)%species%atomarray(1)%atom%coord(:)
  do js=1, nspecies
    do ia=1, natoms(js)
! shift atom
      input%structure%speciesarray(js)%species%atomarray(ia)%atom%coord(:) =&
    &input%structure%speciesarray(js)%species%atomarray(ia)%atom%coord(:) - v(:)
! map lattice coordinates back to [0,1)
      call r3frac(input%structure%epslat, input%structure%speciesarray(js)%species%atomarray(ia)%atom%coord(:), iv)
! determine the new Cartesian coordinates
      call r3mv(input%structure%crystal%basevect, &
    &input%structure%speciesarray(js)%species%atomarray(ia)%atom%coord(:), atposc(:, ia, js))
    end do
  end do
end if
! determine possible translation vectors from smallest set of atoms
n=max(natoms(is)*natoms(is), 1)
allocate(vtl(3, n))
n=1
vtl(:, 1)=0.d0
do ia=1, natoms(is)
  do ja=2, natoms(is)
    v(:) = input%structure%speciesarray(is)%species%atomarray(ia)%atom%coord(:) -&
    &input%structure%speciesarray(is)%species%atomarray(ja)%atom%coord(:)
    call r3frac(input%structure%epslat, v, iv)
    do i=1, n
      t1=abs(vtl(1, i)-v(1))+abs(vtl(2, i)-v(2))+abs(vtl(3, i)-v(3))
      if (t1.lt.input%structure%epslat) goto 10
    end do
    n=n+1
    vtl(:, n)=v(:)
10 continue
  end do
end do
eqatoms(:, :, :)=.false.
nsymcrys=0
! loop over all possible translations
do i=1, n
! construct new array with translated positions
  do is=1, nspecies
    do ia=1, natoms(is)
      apl(:, ia, is) = input%structure%speciesarray(is)%species%atomarray(ia)%atom%coord(:) + vtl(:, i)
      aplt(:, ia, is)=input%structure%speciesarray(is)%species%atomarray(ia)%atom%coord(:)
    end do
  end do
! find the symmetries for current translation
  call findsym(aplt, apl, nsym, lspl, lspn, iea)
  do isym=1, nsym
#ifdef XS
     ! exclude non-zero translations
     if(associated(input%xs))then
     if (input%xs%symmorph.and.(sum(abs(vtl(:, i))).gt.input%structure%epslat)) goto 20
     endif
#endif
    nsymcrys=nsymcrys+1
    if (nsymcrys.gt.maxsymcrys) then
      write(*, *)
      write(*, '("Error(findsymcrys): too many symmetries")')
      write(*, '(" Adjust maxsymcrys in modmain and recompile code")')
      write(*, *)
      stop
    end if
    vtlsymc(:, nsymcrys)=vtl(:, i)
    lsplsymc(nsymcrys)=lspl(isym)
    lspnsymc(nsymcrys)=lspn(isym)
    do is=1, nspecies
      do ia=1, natoms(is)
	ja=iea(ia, is, isym)
	ieqatom(ia, is, nsymcrys)=ja
	eqatoms(ia, ja, is)=.true.
	eqatoms(ja, ia, is)=.true.
      end do
    end do
#ifdef XS
20  continue
#endif
  end do
end do
deallocate(iea, vtl)
return
end subroutine
!EOC
