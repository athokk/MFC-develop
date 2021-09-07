!! This file only does 1D cases! Careful.
!!
!!
!!
!!
!!       __  _______________
!!      /  |/  / ____/ ____/
!!     / /|_/ / /_  / /
!!    / /  / / __/ / /___
!!   /_/  /_/_/    \____/
!!
!!  This file is part of MFC.
!!
!!  MFC is the legal property of its developers, whose names
!!  are listed in the copyright file included with this source
!!  distribution.
!!
!!  MFC is free software: you can redistribute it and/or modify
!!  it under the terms of the GNU General Public License as published
!!  by the Free Software Foundation, either version 3 of the license
!!  or any later version.
!!
!!  MFC is distributed in the hope that it will be useful,
!!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!!  GNU General Public License for more details.
!!
!!  You should have received a copy of the GNU General Public License
!!  along with MFC (LICENSE).
!!  If not, see <http://www.gnu.org/licenses/>.

!>
!! @file m_weno.f90
!! @brief Contains module m_weno
!! @author S. Bryngelson, K. Schimdmayer, V. Coralic, J. Meng, K. Maeda, T. Colonius
!! @version 1.0
!! @date JUNE 06 2019

!> @brief  Weighted essentially non-oscillatory (WENO) reconstruction scheme
!!              that is supplemented with monotonicity preserving bounds (MPWENO)
!!              and a mapping function that boosts the accuracy of the non-linear
!!              weights (WENOM). MPWENO, see Balsara and Shu (2000), prevents the
!!              reconstructed values to lay outside the range set by the stencil,
!!              while WENOM, see Henrick et al. (2005), recovers the formal order
!!              of accuracy of the reconstruction at critical points. Please note
!!              that the basic WENO approach is implemented according to the work
!!              of Jiang and Shu (1996).
module m_weno

    ! Dependencies =============================================================
    use m_derived_types        !< Definitions of the derived types

    use m_global_parameters    !< Definitions of the global parameters

    use m_variables_conversion !< State variables type conversion procedures

    use openacc

    use m_mpi_proxy
    ! ==========================================================================

    ! implicit none

    private; public :: s_initialize_weno_module, &
                       s_finalize_weno_module, s_weno_alt, &
                       s_weno

    type(vector_field), allocatable, dimension(:) :: v_rs_wsL
    !$acc declare create(v_rs_wsL)

    type(scalar_field), allocatable, dimension(:) :: vL_vf, vR_vf
    !$acc declare create(vL_vf, vR_vf)

    real(kind(0d0)), target, allocatable, dimension(:, :, :) :: poly_coef_L
    real(kind(0d0)), target, allocatable, dimension(:, :, :) :: poly_coef_R
    !$acc declare create (poly_coef_L,poly_coef_R)

    real(kind(0d0)), target, allocatable, dimension(:, :) :: d_L
    real(kind(0d0)), target, allocatable, dimension(:, :) :: d_R
    !$acc declare create (d_L,d_R)

    real(kind(0d0)), target, allocatable, dimension(:, :, :) :: beta_coef
    !$acc declare create (beta_coef)

    real(kind(0d0)), target, allocatable, dimension(:,:,:,:) :: v_flat
    real(kind(0d0)), target, allocatable, dimension(:,:,:,:) :: vL_vf_flat, vR_vf_flat

    ! These are variables that are only on GPU
    real(kind(0d0)), target, allocatable, dimension(:,:,:,:,:) :: v_rs_wsL_flat
    !$acc declare create (v_rs_wsL_flat)

contains

    !>  The computation of parameters, the allocation of memory,
        !!      the association of pointers and/or the execution of any
        !!      other procedures that are necessary to setup the module.
    subroutine s_initialize_weno_module() ! --------------------------------

        type(bounds_info) :: ix, iy, iz !< Indical bounds in the x-, y- and z-directions
        integer :: i
        integer :: ixb_full, ixe_full
        ix%beg = -buff_size + weno_polyn; ix%end = m - ix%beg

        ! Allocating WENO-stencil for the variables to be WENO-reconstructed
        allocate (v_rs_wsL(-weno_polyn:weno_polyn))

        do i = -weno_polyn, weno_polyn
            allocate (v_rs_wsL(i)%vf(1:sys_size) )
            !$acc enter data create(v_rs_wsL(i)%vf)
        end do

        ! Populate variable buffers at each point (for full stencil)
        do i = -weno_polyn, weno_polyn
            do j = 1, sys_size
                allocate (v_rs_wsL(i)%vf(j)%sf(ix%beg:ix%end, &
                                               iy%beg:iy%end, &
                                              iz%beg:iz%end))
                !$acc enter data create(v_rs_wsL(i)%vf(j)%sf)
           end do
        end do

        ! Allocating/Computing WENO Coefficients in x-direction ============
        allocate (poly_coef_L(0:weno_polyn, &
                              0:weno_polyn - 1, &
                              ix%beg:ix%end))
        allocate (poly_coef_R(0:weno_polyn, &
                              0:weno_polyn - 1, &
                              ix%beg:ix%end))

        allocate (d_L(0:weno_polyn, ix%beg:ix%end))
        allocate (d_R(0:weno_polyn, ix%beg:ix%end))

        allocate (beta_coef(0:weno_polyn, &
                            0:2*(weno_polyn - 1), &
                            ix%beg:ix%end))


        allocate(v_rs_wsL_flat( ix%beg:ix%end, iy%beg:iy%end, iz%beg:iz%end, -weno_polyn:weno_polyn, 1:sys_size))

        ixb_full = -buff_size; ixe_full = m + buff_size
        ! print*, 'buff_size: ', buff_size

        allocate(v_flat(ixb_full:ixe_full, iy%beg:iy%end, iz%beg:iz%end, 1:sys_size))

        allocate(vL_vf_flat(ixb_full:ixe_full, iy%beg:iy%end, iz%beg:iz%end, 1:sys_size))
        allocate(vR_vf_flat(ixb_full:ixe_full, iy%beg:iy%end, iz%beg:iz%end, 1:sys_size))

        call s_compute_weno_coefficients(ix)

    end subroutine s_initialize_weno_module ! ------------------------------



    subroutine s_weno_alt(v_vf, vL_vf, vR_vf, weno_dir_dummy, ix, iy, iz)

        type(scalar_field), dimension(:), intent(IN) :: v_vf
        type(scalar_field), dimension(:), intent(INOUT) :: vL_vf, vR_vf
        integer, intent(IN) :: weno_dir_dummy
        type(bounds_info), intent(IN) :: ix, iy, iz

        real(kind(0d0)), dimension(-2:1) :: dvd 
        real(kind(0d0)), dimension(0:2) ::  poly
        real(kind(0d0)), dimension(0:2) :: alpha
        real(kind(0d0)), dimension(0:2) :: omega
        real(kind(0d0)), dimension(0:2) :: beta 
        real(kind(0d0)), pointer :: beta_p(:)

        integer :: i, j, k, l, r, s
        integer :: ixb, ixe
        
        integer :: t1, t2, c_rate, c_max

        ! MP_WENO
        real(kind(0d0)), dimension(-1:1) :: d

        real(kind(0d0)) :: d_MD, d_LC

        real(kind(0d0)) :: vL_UL, vR_UL
        real(kind(0d0)) :: vL_MD, vR_MD
        real(kind(0d0)) :: vL_LC, vR_LC
        real(kind(0d0)) :: vL_min, vR_min
        real(kind(0d0)) :: vL_max, vR_max

        real(kind(0d0)), parameter :: alpha_mp = 2d0
        real(kind(0d0)), parameter :: beta_mp = 4d0/3d0

        ! v_weno_global_var%vf(i)%sf(j,k,l) = v_vf(i)%sf(j,k,l)
        !! call acc_map_data? 

        ixb = ix%beg
        ixe = ix%end

        do j = 1,sys_size
            v_flat(:,:,:,j) = v_vf(j)%sf(:,:,:)
        end do


        k = 0; l = 0

        !$acc data copyin(v_flat) copyout(vL_vf_flat,vR_vf_flat) present(v_rs_wsL_flat, poly_coef_L, poly_coef_R, D_L, D_R, beta_coef)

! -- Test --

!        !$acc enter data copyin(v_flat)

!        !$acc enter data create(v_rs_wsL_flat)
!        !$acc enter data create(vL_vf_flat, vR_vf_flat)
!        !$acc enter data create(poly_coef_L, poly_coef_R, D_L, D_R, beta_coef)

! ----------

        !$acc parallel loop collapse(3)
        do s = -weno_polyn, weno_polyn
            do i = 1, sys_size
                do j = ixb, ixe
                    v_rs_wsL_flat(j, k, l, s, i) = &
                       v_flat(s + j, k, l, i)
                end do
            end do
        end do
        !$acc end parallel loop
!print*, 'marker 1a'
        !$acc parallel loop gang vector private(dvd, poly, beta, alpha, omega)
        do j = ixb, ixe
            do i = 1, sys_size

                !!! L Reconstruction
                dvd(1) = v_rs_wsL_flat(j, k, l, 2, i) &
                         - v_rs_wsL_flat(j, k, l, 1, i)
                dvd(0) = v_rs_wsL_flat(j, k, l, 1, i) &
                        - v_rs_wsL_flat(j, k, l, 0, i)
                dvd(-1) = v_rs_wsL_flat(j, k, l, 0, i) &
                        - v_rs_wsL_flat(j, k, l, -1, i)
                dvd(-2) = v_rs_wsL_flat(j, k, l, -1, i) &
                        - v_rs_wsL_flat(j, k, l, -2, i)

                poly(0) = v_rs_wsL_flat(j, k, l, 0, i) &
                          + poly_coef_L(0, 0, j)*dvd(1) &
                          + poly_coef_L(0, 1, j)*dvd(0)
                poly(1) = v_rs_wsL_flat(j, k, l, 0, i) &
                          + poly_coef_L(1, 0, j)*dvd(0) &
                          + poly_coef_L(1, 1, j)*dvd(-1)
                poly(2) = v_rs_wsL_flat(j, k, l, 0, i) &
                          + poly_coef_L(2, 0, j)*dvd(-1) &
                          + poly_coef_L(2, 1, j)*dvd(-2)

                beta(0) = beta_coef(0, 0, j)*dvd(1)*dvd(1) &
                        + beta_coef(0, 1, j)*dvd(1)*dvd(0) &
                        + beta_coef(0, 2, j)*dvd(0)*dvd(0) &
                        + weno_eps
                beta(1) = beta_coef(1, 0, j)*dvd(0)*dvd(0) &
                        + beta_coef(1, 1, j)*dvd(0)*dvd(-1) &
                        + beta_coef(1, 2, j)*dvd(-1)*dvd(-1) &
                        + weno_eps
                beta(2) = beta_coef(2, 0, j)*dvd(-1)*dvd(-1) &
                        + beta_coef(2, 1, j)*dvd(-1)*dvd(-2) &
                        + beta_coef(2, 2, j)*dvd(-2)*dvd(-2) &
                        + weno_eps

                alpha = d_L(:, j)/(beta*beta)
                omega = alpha/sum(alpha)

                if (mapped_weno) then
                    call s_map_nonlinear_weights(d_L(:, j), alpha, omega)
                end if

                vL_vf_flat(j, k, l, i) = sum(omega*poly)

                !!! R Reconstruction
                dvd(1) = v_rs_wsL_flat(j, k, l, 2, i) &
                       - v_rs_wsL_flat(j, k, l, 1, i)
                dvd(0) = v_rs_wsL_flat(j, k, l, 1, i) &
                       - v_rs_wsL_flat(j, k, l, 0, i)
                dvd(-1) = v_rs_wsL_flat(j, k, l, 0, i) &
                        - v_rs_wsL_flat(j, k, l, -1, i)
                dvd(-2) = v_rs_wsL_flat(j, k, l, -1, i) &
                        - v_rs_wsL_flat(j, k, l, -2, i)

                poly(0) = v_rs_wsL_flat(j, k, l, 0, i) &
                          + poly_coef_R(0, 0, j)*dvd(1) &
                          + poly_coef_R(0, 1, j)*dvd(0)
                poly(1) = v_rs_wsL_flat(j, k, l, 0, i) &
                          + poly_coef_R(1, 0, j)*dvd(0) &
                          + poly_coef_R(1, 1, j)*dvd(-1)
                poly(2) = v_rs_wsL_flat(j, k, l, 0, i) &
                          + poly_coef_R(2, 0, j)*dvd(-1) &
                          + poly_coef_R(2, 1, j)*dvd(-2)

                beta(0) = beta_coef(0, 0, j)*dvd(1)*dvd(1) &
                        + beta_coef(0, 1, j)*dvd(1)*dvd(0) &
                        + beta_coef(0, 2, j)*dvd(0)*dvd(0) &
                        + weno_eps
                beta(1) = beta_coef(1, 0, j)*dvd(0)*dvd(0) &
                        + beta_coef(1, 1, j)*dvd(0)*dvd(-1) &
                        + beta_coef(1, 2, j)*dvd(-1)*dvd(-1) &
                        + weno_eps
                beta(2) = beta_coef(2, 0, j)*dvd(-1)*dvd(-1) &
                        + beta_coef(2, 1, j)*dvd(-1)*dvd(-2) &
                        + beta_coef(2, 2, j)*dvd(-2)*dvd(-2) &
                        + weno_eps

                alpha = d_R(:, j)/(beta*beta)
                omega = alpha/sum(alpha)

                if (mapped_weno) then
                    call s_map_nonlinear_weights(d_R(:, j), alpha, omega)
                end if

                vR_vf_flat(j, k, l, i) = sum(omega*poly)
            end do
        end do
        !$acc end parallel loop 

        if (mp_weno) then
        !$acc parallel loop gang vector private(d)
        do j = ixb, ixe
            do i = 1, sys_size

                ! Left Monotonicity Preserving Bound
                d(-1) = v_rs_wsL_flat(j, k, l, 0, i) &
                        + v_rs_wsL_flat(j, k, l, -2, i) &
                        - v_rs_wsL_flat(j, k, l, -1, i) &
                        *2d0
                d(0) = v_rs_wsL_flat(j, k, l, 1, i) &
                       + v_rs_wsL_flat(j, k, l, -1, i) &
                       - v_rs_wsL_flat(j, k, l, 0, i) &
                       *2d0
                d(1) = v_rs_wsL_flat(j, k, l, 2, i) &
                       + v_rs_wsL_flat(j, k, l, 0, i) &
                       - v_rs_wsL_flat(j, k, l, 1, i) &
                       *2d0

                d_MD = (sign(1d0, 4d0*d(-1) - d(0)) + sign(1d0, 4d0*d(0) - d(-1))) &
                       *abs((sign(1d0, 4d0*d(-1) - d(0)) + sign(1d0, d(-1))) &
                            *(sign(1d0, 4d0*d(-1) - d(0)) + sign(1d0, d(0)))) &
                       *min(abs(4d0*d(-1) - d(0)), abs(d(-1)), &
                            abs(4d0*d(0) - d(-1)), abs(d(0)))/8d0

                d_LC = (sign(1d0, 4d0*d(0) - d(1)) + sign(1d0, 4d0*d(1) - d(0))) &
                       *abs((sign(1d0, 4d0*d(0) - d(1)) + sign(1d0, d(0))) &
                            *(sign(1d0, 4d0*d(0) - d(1)) + sign(1d0, d(1)))) &
                       *min(abs(4d0*d(0) - d(1)), abs(d(0)), &
                            abs(4d0*d(1) - d(0)), abs(d(1)))/8d0

                vL_UL = v_rs_wsL_flat(j, k, l, 0, i) &
                        - (v_rs_wsL_flat(j, k, l, 1, i) &
                           - v_rs_wsL_flat(j, k, l, 0, i))*alpha_mp

                vL_MD = (v_rs_wsL_flat(j, k, l, 0, i) &
                         + v_rs_wsL_flat(j, k, l, -1, i) &
                         - d_MD)*5d-1

                vL_LC = v_rs_wsL_flat(j, k, l, 0, i) &
                        - (v_rs_wsL_flat(j, k, l, 1, i) &
                           - v_rs_wsL_flat(j, k, l, 0, i))*5d-1 + beta_mp*d_LC

                vL_min = max(min(v_rs_wsL_flat(j, k, l, 0, i), &
                                 v_rs_wsL_flat(j, k, l, -1, i), &
                                 vL_MD), &
                             min(v_rs_wsL_flat(j, k, l, 0, i), &
                                 vL_UL, &
                                 vL_LC))

                vL_max = min(max(v_rs_wsL_flat(j, k, l, 0, i), &
                                 v_rs_wsL_flat(j, k, l, -1, i), &
                                 vL_MD), &
                             max(v_rs_wsL_flat(j, k, l, 0, i), &
                                 vL_UL, &
                                 vL_LC))

                vL_vf_flat(j, k, l, i) = vL_vf_flat(j, k, l, i) &
                          + (sign(5d-1, vL_min - vL_vf_flat(j, k, l, i)) &
                             + sign(5d-1, vL_max - vL_vf_flat(j, k, l, i))) &
                          *min(abs(vL_min - vL_vf_flat(j, k, l, i)), &
                               abs(vL_max - vL_vf_flat(j, k, l, i)))

                ! Right Monotonicity Preserving Bound
                d(-1) = v_rs_wsL_flat(j, k, l, 0, i) &
                        + v_rs_wsL_flat(j, k, l, -2, i) &
                        - v_rs_wsL_flat(j, k, l, -1, i)*2d0
                d(0) = v_rs_wsL_flat(j, k, l, 1, i) &
                       + v_rs_wsL_flat(j, k, l, -1, i) &
                       - v_rs_wsL_flat(j, k, l, 0, i)*2d0
                d(1) = v_rs_wsL_flat(j, k, l, 2, i) &
                       + v_rs_wsL_flat(j, k, l, 0, i) &
                       - v_rs_wsL_flat(j, k, l, 1, i)*2d0

                d_MD = (sign(1d0, 4d0*d(0) - d(1)) + sign(1d0, 4d0*d(1) - d(0))) &
                       *abs((sign(1d0, 4d0*d(0) - d(1)) + sign(1d0, d(0))) &
                            *(sign(1d0, 4d0*d(0) - d(1)) + sign(1d0, d(1)))) &
                       *min(abs(4d0*d(0) - d(1)), abs(d(0)), &
                            abs(4d0*d(1) - d(0)), abs(d(1)))/8d0

                d_LC = (sign(1d0, 4d0*d(-1) - d(0)) + sign(1d0, 4d0*d(0) - d(-1))) &
                       *abs((sign(1d0, 4d0*d(-1) - d(0)) + sign(1d0, d(-1))) &
                            *(sign(1d0, 4d0*d(-1) - d(0)) + sign(1d0, d(0)))) &
                       *min(abs(4d0*d(-1) - d(0)), abs(d(-1)), &
                            abs(4d0*d(0) - d(-1)), abs(d(0)))/8d0

                vR_UL = v_rs_wsL_flat(j, k, l, 0, i) &
                        + (v_rs_wsL_flat(j, k, l, 0, i) &
                           - v_rs_wsL_flat(j, k, l, -1, i))*alpha_mp

                vR_MD = (v_rs_wsL_flat(j, k, l, 0, i) &
                         + v_rs_wsL_flat(j, k, l, 1, i) &
                         - d_MD)*5d-1

                vR_LC = v_rs_wsL_flat(j, k, l, 0, i) &
                        + (v_rs_wsL_flat(j, k, l, 0, i) &
                           - v_rs_wsL_flat(j, k, l, -1, i))*5d-1 + beta_mp*d_LC

                vR_min = max(min(v_rs_wsL_flat(j, k, l, 0, i), &
                                 v_rs_wsL_flat(j, k, l, 1, i), &
                                 vR_MD), &
                             min(v_rs_wsL_flat(j, k, l, 0, i), &
                                 vR_UL, &
                                 vR_LC))

                vR_max = min(max(v_rs_wsL_flat(j, k, l, 0, i), &
                                 v_rs_wsL_flat(j, k, l, 1, i), &
                                 vR_MD), &
                             max(v_rs_wsL_flat(j, k, l, 0, i), &
                                 vR_UL, &
                                 vR_LC))

                vR_vf_flat(j, k, l, i) = vR_vf_flat(j, k, l, i) &
                          + (sign(5d-1, vR_min - vR_vf_flat(j, k, l, i)) &
                             + sign(5d-1, vR_max - vR_vf_flat(j, k, l, i))) &
                          *min(abs(vR_min - vR_vf_flat(j, k, l, i)), &
                               abs(vR_max - vR_vf_flat(j, k, l, i)))
            end do
        end do
        !$acc end parallel loop
        end if
        !$acc end data

! -- Test --
!        !$acc exit data copyout(vL_vf_flat,vR_vf_flat)
! ----------

        ! call system_clock(t2)
        ! print *, "Took: ", real(t2 - t1) / real(c_rate)

        ! do i = ixb, ixe
        !     print*, 'v,vL,vR', &
        !         v_flat(i,0,0,1), &
        !         vL_vf_flat(i,0,0,1), &
        !         vR_vf_flat(i,0,0,1)
        ! end do

        do j = 1,sys_size
            do i = ixb,ixe
                vL_vf(j)%sf(i,0,0) = vL_vf_flat(i,0,0,j)
                vR_vf(j)%sf(i,0,0) = vR_vf_flat(i,0,0,j)
            end do
        end do

!         do i = 101, 101
!             print*, '** vL, vR ', &
!                 vL_vf(1)%sf(i,0,0), &
!                 vR_vf(1)%sf(i,0,0)
!         end do

        ! call s_mpi_abort()

    end subroutine s_weno_alt

    subroutine s_map_nonlinear_weights(d_K, alpha_K, omega_K) 
    !$acc routine seq 

        real(kind(0d0)), dimension(0:2), intent(IN)    ::     d_K
        real(kind(0d0)), dimension(0:2), intent(INOUT) :: alpha_K
        real(kind(0d0)), dimension(0:2), intent(INOUT) :: omega_K

        ! Mapping the WENO nonlinear weights to the WENOM nonlinear weights
        if (minval(d_K) == 0d0 .or. maxval(d_K) == 1d0) return

        alpha_K = (d_K*(1d0 + d_K - 3d0*omega_K) + omega_K**2d0) &
                  *(omega_K/(d_K**2d0 + omega_K*(1d0 - 2d0*d_K)))

        omega_K = alpha_K/sum(alpha_K)

    end subroutine s_map_nonlinear_weights ! -------------------------------


    subroutine s_weno(v_vf, vL_vf, vR_vf, weno_dir_dummy, ix, iy, iz)
        type(scalar_field), dimension(:), intent(IN) :: v_vf
        type(scalar_field), dimension(:), intent(INOUT) :: vL_vf, vR_vf
        integer, intent(IN) :: weno_dir_dummy
        type(bounds_info), intent(IN) :: ix, iy, iz

        real(kind(0d0)), dimension(-weno_polyn:weno_polyn-1) :: dvd 
        real(kind(0d0)), dimension(0:weno_polyn) :: poly
        real(kind(0d0)), dimension(0:weno_polyn) :: alpha
        real(kind(0d0)), dimension(0:weno_polyn) :: omega
        real(kind(0d0)), dimension(0:weno_polyn) :: beta 
        integer :: i, j, k, l, r, s

        integer :: ixb, ixe

        ! Do we need to copyin v_vf? We do this earlier I believe
        ! TODO come back to line 88 for the copyin

        ixb = ix%beg
        ixe = ix%end
        k = 0; l = 0

! A of now best method found is using managed memory
! -> requires -ta=tesla:managed compiler flag

        !$acc data copyin(v_vf) copyout(vL_vf, vR_vf) present(v_rs_wsL, poly_coef_L, poly_coef_R, D_L, D_R, beta_coef)
        !$acc parallel loop collapse(3)
        do j = ixb, ixe
           do i = 1, sys_size
              do s = -weno_polyn, weno_polyn
                    v_rs_wsL(s)%vf(i)%sf(j, k, l) = &
                        v_vf(i)%sf(s + j, k, l)                        
                end do
            end do
        end do
        !$acc end parallel loop

        !$acc parallel loop gang vector private(dvd, poly, beta, alpha, omega)
                do j = ixb, ixe
                   do i = 1, sys_size
                        dvd(1) = v_rs_wsL(2)%vf(i)%sf(j, k, l) &
                                 - v_rs_wsL(1)%vf(i)%sf(j, k, l)

                        dvd(0) = v_rs_wsL(1)%vf(i)%sf(j, k, l) &
                                - v_rs_wsL(0)%vf(i)%sf(j, k, l)
                        dvd(-1) = v_rs_wsL(0)%vf(i)%sf(j, k, l) &
                                - v_rs_wsL(-1)%vf(i)%sf(j, k, l)
                        dvd(-2) = v_rs_wsL(-1)%vf(i)%sf(j, k, l) &
                                - v_rs_wsL(-2)%vf(i)%sf(j, k, l)

                        poly(0) = v_rs_wsL(0)%vf(i)%sf(j, k, l) &
                                  + poly_coef_L(0, 0, j)*dvd(1) &
                                  + poly_coef_L(0, 1, j)*dvd(0)
                        poly(1) = v_rs_wsL(0)%vf(i)%sf(j, k, l) &
                                  + poly_coef_L(1, 0, j)*dvd(0) &
                                  + poly_coef_L(1, 1, j)*dvd(-1)
                        poly(2) = v_rs_wsL(0)%vf(i)%sf(j, k, l) &
                                  + poly_coef_L(2, 0, j)*dvd(-1) &
                                  + poly_coef_L(2, 1, j)*dvd(-2)

                        beta(0) = beta_coef(0, 0, j)*dvd(1)*dvd(1) &
                                + beta_coef(0, 1, j)*dvd(1)*dvd(0) &
                                + beta_coef(0, 2, j)*dvd(0)*dvd(0) &
                                + weno_eps
                        beta(1) = beta_coef(1, 0, j)*dvd(0)*dvd(0) &
                                + beta_coef(1, 1, j)*dvd(0)*dvd(-1) &
                                + beta_coef(1, 2, j)*dvd(-1)*dvd(-1) &
                                + weno_eps
                        beta(2) = beta_coef(2, 0, j)*dvd(-1)*dvd(-1) &
                                + beta_coef(2, 1, j)*dvd(-1)*dvd(-2) &
                                + beta_coef(2, 2, j)*dvd(-2)*dvd(-2) &
                                + weno_eps

                        alpha  = d_L(:, j)/(beta*beta)
                        omega  = alpha/sum(alpha)

                        vL_vf(i)%sf(j, k, l) = sum(omega*poly)

                        dvd(1) = v_rs_wsL(2)%vf(i)%sf(j, k, l) &
                               - v_rs_wsL(1)%vf(i)%sf(j, k, l)
                        dvd(0) = v_rs_wsL(1)%vf(i)%sf(j, k, l) &
                               - v_rs_wsL(0)%vf(i)%sf(j, k, l)
                        dvd(-1) = v_rs_wsL(0)%vf(i)%sf(j, k, l) &
                                - v_rs_wsL(-1)%vf(i)%sf(j, k, l)
                        dvd(-2) = v_rs_wsL(-1)%vf(i)%sf(j, k, l) &
                                - v_rs_wsL(-2)%vf(i)%sf(j, k, l)

                        poly(0)   = v_rs_wsL(0)%vf(i)%sf(j, k, l) &
                                  + poly_coef_R(0, 0, j)*dvd(1) &
                                  + poly_coef_R(0, 1, j)*dvd(0)
                        poly(1)   = v_rs_wsL(0)%vf(i)%sf(j, k, l) &
                                  + poly_coef_R(1, 0, j)*dvd(0) &
                                  + poly_coef_R(1, 1, j)*dvd(-1)
                        poly(2)   = v_rs_wsL(0)%vf(i)%sf(j, k, l) &
                                  + poly_coef_R(2, 0, j)*dvd(-1) &
                                  + poly_coef_R(2, 1, j)*dvd(-2)

                        beta(0) = beta_coef(0, 0, j)*dvd(1)*dvd(1) &
                                + beta_coef(0, 1, j)*dvd(1)*dvd(0) &
                                + beta_coef(0, 2, j)*dvd(0)*dvd(0) &
                                + weno_eps
                        beta(1) = beta_coef(1, 0, j)*dvd(0)*dvd(0) &
                                + beta_coef(1, 1, j)*dvd(0)*dvd(-1) &
                                + beta_coef(1, 2, j)*dvd(-1)*dvd(-1) &
                                + weno_eps
                        beta(2) = beta_coef(2, 0, j)*dvd(-1)*dvd(-1) &
                                + beta_coef(2, 1, j)*dvd(-1)*dvd(-2) &
                                + beta_coef(2, 2, j)*dvd(-2)*dvd(-2) &
                                + weno_eps

                        alpha   = d_R(:, j)/(beta*beta)
                        omega   = alpha/sum(alpha)

                        vR_vf(i)%sf(j, k, l) = sum(omega*poly)
! -- test --
!                        if ((j == 101) .and. (i == 2)) then
!                                print*, '** vL, vR ', &
!                                        vL_vf(2)%sf(i,0,0), &
!                                        vR_vf(2)%sf(i,0,0)
!                        end if
! ----------
                    end do
                end do
        !$acc end parallel loop
        !$acc end data

!        do i = -weno_polyn, weno_polyn
!            do j = 1, sys_size
!                deallocate (v_rs_wsL(i)%vf(j)%sf)
!            end do
!        end do

!        do i = 101,101
!            print*, '** vL, vR ', &
!                vL_vf(1)%sf(i,0,0), &
!                vR_vf(1)%sf(i,0,0)
!        end do

! --------------------
! Old test code left here (for now) for future ref if necessary
! --------------------

!originally
!        !$acc data copyout(vL_vf,vR_vf) present(v_rs_wsL, poly_coef_L, poly_coef_R, d_L, d_R, beta_coef)
!        !$acc parallel loop collapse(3) present(v_rs_wsL)

!Testing
!        !$acc data copyin(v_vf(:),v_vf(1)%sf(:,:,:)) copyout(vL_vf(:),vL_vf(1)%sf(:,:,:),vR_vf(:),vR_vf(1)%sf(:,:,:)) present(v_rs_wsL, poly_coef_L, poly_coef_R, d_L, d_R, beta_coef)
!        !$acc parallel loop collapse(3) present(v_rs_wsL(:),v_rs_wsL(0)%vf(:),v_rs_wsL(0)%vf(1)%sf(:,:,:))

!Old 'ugly' version
!        !$acc data copyin(v_vf(:),v_vf(1)%sf(:,:,:),v_vf(2)%sf(:,:,:),v_vf(3)%sf(:,:,:),v_vf(4)%sf(:,:,:)) copyout(vL_vf(:),vL_vf(1)%sf(:,:,:),vL_vf(2)%sf(:,:,:),vL_vf(3)%sf(:,:,:),vL_vf(4)%sf(:,:,:),vR_vf(:),vR_vf(1)%sf(:,:,:),vR_vf(2)%sf(:,:,:),vR_vf(3)%sf(:,:,:),vR_vf(4)%sf(:,:,:)) present(v_rs_wsL, poly_coef_L, poly_coef_R, d_L, d_R, beta_coef)
!        !$acc parallel loop collapse(3) present(v_rs_wsL(:),v_rs_wsL(-2)%vf(:),v_rs_wsL(-1)%vf(:),v_rs_wsL(0)%vf(:),v_rs_wsL(1)%vf(:),v_rs_wsL(2)%vf(:),v_rs_wsl(-2)%vf(1)%sf(:,:,:),v_rs_wsL(-2)%vf(2)%sf(:,:,:),v_rs_wsL(-2)%vf(3)%sf(:,:,:),v_rs_wsL(-2)%vf(4)%sf(:,:,:),v_rs_wsL(-1)%vf(1)%sf(:,:,:),v_rs_wsL(-1)%vf(2)%sf(:,:,:),v_rs_wsL(-1)%vf(3)%sf(:,:,:),v_rs_wsL(-1)%vf(4)%sf(:,:,:),v_rs_wsL(0)%vf(1)%sf(:,:,:),v_rs_wsL(0)%vf(2)%sf(:,:,:),v_rs_wsL(0)%vf(3)%sf(:,:,:),v_rs_wsL(0)%vf(4)%sf(:,:,:),v_rs_wsL(1)%vf(1)%sf(:,:,:),v_rs_wsL(1)%vf(2)%sf(:,:,:),v_rs_wsL(1)%vf(3)%sf(:,:,:),v_rs_wsL(1)%vf(4)%sf(:,:,:),v_rs_wsL(2)%vf(1)%sf(:,:,:),v_rs_wsL(2)%vf(2)%sf(:,:,:),v_rs_wsL(2)%vf(3)%sf(:,:,:),v_rs_wsL(2)%vf(4)%sf(:,:,:))

! More testing (here, only a data statement first (first loop not parallel)
!        !$acc data copyin(v_vf) copyout(vL_vf,vL_vf%sf,vR_vf,vR_vf%sf) present(v_rs_wsL, poly_coef_L, poly_coef_R, d_L, d_R, beta_coef)
!        !$acc data copyin(v_vf) copyout(vL_vf,vR_vf) present(v_rs_wsL, poly_coef_L, poly_coef_R, d_L, d_R, beta_coef)
!        !$acc parallel loop collapse(3) present(v_rs_wsL(-2:2),v_rs_wsL%vf(1:4),v_rs_wsL(2)%vf(4)%sf(:,:,:))
!        !$acc parallel loop default(present)

! --------------------
! End of old test code
! --------------------

! --------------------
! Other test code pieces
! --------------------

! -- At start --

!        !$acc data copyin(v_vf, v_vf%sf) copyout(vL_vf, vL_vf%sf,vL_vf(1)%sf(101,0,0), vR_vf, vR_vf%sf) present(v_rs_wsL, poly_coef_L, poly_coef_R, d_L, d_R, beta_coef)

!        do k = ix%beg, ix%end
!           do j = 1, sys_size
!              do i = -weno_polyn, weno_polyn
!                    v_rs_wsL(i)%vf(j)%sf(k, :, :) = &
!                        v_vf(j)%sf(i + k, iy%beg:iy%end, iz%beg:iz%end)
!                end do
!            end do
!        end do

!        !$acc parallel loop collapse(3) present(v_rs_wsL(:),v_rs_wsL(-2)%vf(:),v_rs_wsL(-1)%vf(:),v_rs_wsL(0)%vf(:),v_rs_wsL(1)%vf(:),v_rs_wsL(2)%vf(:),v_rs_wsl(-2)%vf(1)%sf(:,:,:),v_rs_wsL(-2)%vf(2)%sf(:,:,:),v_rs_wsL(-2)%vf(3)%sf(:,:,:),v_rs_wsL(-2)%vf(4)%sf(:,:,:),v_rs_wsL(-1)%vf(1)%sf(:,:,:),v_rs_wsL(-1)%vf(2)%sf(:,:,:),v_rs_wsL(-1)%vf(3)%sf(:,:,:),v_rs_wsL(-1)%vf(4)%sf(:,:,:),v_rs_wsL(0)%vf(1)%sf(:,:,:),v_rs_wsL(0)%vf(2)%sf(:,:,:),v_rs_wsL(0)%vf(3)%sf(:,:,:),v_rs_wsL(0)%vf(4)%sf(:,:,:),v_rs_wsL(1)%vf(1)%sf(:,:,:),v_rs_wsL(1)%vf(2)%sf(:,:,:),v_rs_wsL(1)%vf(3)%sf(:,:,:),v_rs_wsL(1)%vf(4)%sf(:,:,:),v_rs_wsL(2)%vf(1)%sf(:,:,:),v_rs_wsL(2)%vf(2)%sf(:,:,:),v_rs_wsL(2)%vf(3)%sf(:,:,:),v_rs_wsL(2)%vf(4)%sf(:,:,:)) copyin(v_vf(:),v_vf(1)%sf(:,:,:),v_vf(2)%sf(:,:,:),v_vf(3)%sf(:,:,:),v_vf(4)%sf(:,:,:))

! -- Between loops --

!        !$acc end parallel loop
!        !$acc update host (v_rs_wsL(:),v_rs_wsL(-2)%vf(:),v_rs_wsL(-1)%vf(:),v_rs_wsL(0)%vf(:),v_rs_wsL(1)%vf(:),v_rs_wsL(2)%vf(:),v_rs_wsl(-2)%vf(1)%sf(:,:,:),v_rs_wsL(-2)%vf(2)%sf(:,:,:),v_rs_wsL(-2)%vf(3)%sf(:,:,:),v_rs_wsL(-2)%vf(4)%sf(:,:,:),v_rs_wsL(-1)%vf(1)%sf(:,:,:),v_rs_wsL(-1)%vf(2)%sf(:,:,:),v_rs_wsL(-1)%vf(3)%sf(:,:,:),v_rs_wsL(-1)%vf(4)%sf(:,:,:),v_rs_wsL(0)%vf(1)%sf(:,:,:),v_rs_wsL(0)%vf(2)%sf(:,:,:),v_rs_wsL(0)%vf(3)%sf(:,:,:),v_rs_wsL(0)%vf(4)%sf(:,:,:),v_rs_wsL(1)%vf(1)%sf(:,:,:),v_rs_wsL(1)%vf(2)%sf(:,:,:),v_rs_wsL(1)%vf(3)%sf(:,:,:),v_rs_wsL(1)%vf(4)%sf(:,:,:),v_rs_wsL(2)%vf(1)%sf(:,:,:),v_rs_wsL(2)%vf(2)%sf(:,:,:),v_rs_wsL(2)%vf(3)%sf(:,:,:),v_rs_wsL(2)%vf(4)%sf(:,:,:))
!        !$acc parallel loop gang vector collapse(3) private(dvd, poly, beta, alpha, omega)
!        !$acc parallel loop gang vector private(dvd, poly, beta, alpha, omega)
!        do l = iz%beg, iz%end
!            do k = iy%beg, iy%end

!        !$acc parallel loop gang vector private(dvd,poly,beta,alpha,omega)

! -- At end --

!        !$acc end parallel loop
!        !$acc end data

! -- other old code with unstructured data directives

! Simplest method using unstructured data directives (implicit attach)
! Requires -ta=tesla:deepcopy compiler flag (works for PGI 17.10 and newer)
! UPDATE SEP 7: THIS DOES NOT WORK (some but not all derived types copied in correctly with this)

!!        !$acc enter data copyin(v_vf)

!!        !$acc enter data create(v_rs_wsL)!
!!        !$acc enter data create(vL_vf, vR_vf)
!!        !$acc enter data create(poly_coef_L, poly_coef_R, D_L, D_R, beta_coef)


! Other older (working??) method (commented out for now) which explicitly loops through
! all indices for derived types. To do: check different in computational
! cost between above code and explicit loops below

! -- copyin --
!        !$acc enter data copyin(v_vf(1:4))
!        !$acc enter data copyin(v_vf)
!        do i = 1, 4
!           ! !$acc enter data copyin(v_vf(i)%sf(ixb:ixe,0,0))
!           ! !$acc enter data copyin(v_vf(i)%sf(:,:,:))
!            do j = ixb, ixe
!                !$acc enter data copyin(v_vf(i)%sf(j,0,0))
!            end do
!        end do
! -- create --
!        !$acc enter data create(v_rs_wsL(-2:2))
!        do s = -2, 2
!            !$acc enter data create(v_rs_wsL(s)%vf(0:4))
!            do i = 1, 4
!                !$acc enter data create(v_rs_wsL(s)%vf(i)%sf(ixb:ixe,0,0))
!            end do
!        end do

!        !$acc enter data create(vL_vf(1:4), vR_vf(1:4))
!        do i = 1, 4
!            !$acc enter data create(vL_vf(i)%sf(ixb:ixe,0,0))
!            !$acc enter data create(vR_vf(i)%sf(ixb:ixe,0,0))
!        end do

!        !$acc enter data create(poly_coef_L, poly_coef_R, D_L, D_R, beta_coef)
! --

! -- at end --
!!        !$acc exit data copyout(vL_vf)
!!        !$acc exit data copyout(vR_vf)

! or more explicit version:
!        !$acc update host (vL_vf)
!        !$acc update host (vR_vf)

!        do i = 1, 4
!            !$acc exit data copyout(vL_vf(i)%sf)
!            !$acc exit data copyout(vR_vf(i)%sf)
!        end do
!        !$acc exit data delete(vL_vf, vR_vf)

! --------------------
! End of other test code
! --------------------
    end subroutine s_weno 

    subroutine s_compute_weno_coefficients(is) ! -------

        type(bounds_info), intent(IN) :: is
        real(kind(0d0)), pointer, dimension(:) :: s_cb => null()
        type(bounds_info) :: bc_s
        integer :: i

        s_cb => x_cb; bc_s = bc_x

        do i = is%beg - 1, is%end - 1

            poly_coef_R(0, 0, i + 1) = &
                ((s_cb(i) - s_cb(i + 1))*(s_cb(i + 1) - s_cb(i + 2)))/ &
                ((s_cb(i) - s_cb(i + 3))*(s_cb(i + 3) - s_cb(i + 1)))
            poly_coef_R(1, 0, i + 1) = &
                ((s_cb(i - 1) - s_cb(i + 1))*(s_cb(i + 1) - s_cb(i)))/ &
                ((s_cb(i - 1) - s_cb(i + 2))*(s_cb(i + 2) - s_cb(i)))
            poly_coef_R(1, 1, i + 1) = &
                ((s_cb(i) - s_cb(i + 1))*(s_cb(i + 1) - s_cb(i + 2)))/ &
                ((s_cb(i - 1) - s_cb(i + 1))*(s_cb(i - 1) - s_cb(i + 2)))
            poly_coef_R(2, 1, i + 1) = &
                ((s_cb(i) - s_cb(i + 1))*(s_cb(i + 1) - s_cb(i - 1)))/ &
                ((s_cb(i - 2) - s_cb(i))*(s_cb(i - 2) - s_cb(i + 1)))
            poly_coef_L(0, 0, i + 1) = &
                ((s_cb(i + 1) - s_cb(i))*(s_cb(i) - s_cb(i + 2)))/ &
                ((s_cb(i) - s_cb(i + 3))*(s_cb(i + 3) - s_cb(i + 1)))
            poly_coef_L(1, 0, i + 1) = &
                ((s_cb(i) - s_cb(i - 1))*(s_cb(i) - s_cb(i + 1)))/ &
                ((s_cb(i - 1) - s_cb(i + 2))*(s_cb(i) - s_cb(i + 2)))
            poly_coef_L(1, 1, i + 1) = &
                ((s_cb(i + 1) - s_cb(i))*(s_cb(i) - s_cb(i + 2)))/ &
                ((s_cb(i - 1) - s_cb(i + 1))*(s_cb(i - 1) - s_cb(i + 2)))
            poly_coef_L(2, 1, i + 1) = &
                ((s_cb(i - 1) - s_cb(i))*(s_cb(i) - s_cb(i + 1)))/ &
                ((s_cb(i - 2) - s_cb(i))*(s_cb(i - 2) - s_cb(i + 1)))

            poly_coef_R(0, 1, i + 1) = &
                ((s_cb(i) - s_cb(i + 2)) + (s_cb(i + 1) - s_cb(i + 3)))/ &
                ((s_cb(i) - s_cb(i + 2))*(s_cb(i) - s_cb(i + 3)))* &
                ((s_cb(i) - s_cb(i + 1)))
            poly_coef_R(2, 0, i + 1) = &
                ((s_cb(i - 2) - s_cb(i + 1)) + (s_cb(i - 1) - s_cb(i + 1)))/ &
                ((s_cb(i - 1) - s_cb(i + 1))*(s_cb(i + 1) - s_cb(i - 2)))* &
                ((s_cb(i + 1) - s_cb(i)))
            poly_coef_L(0, 1, i + 1) = &
                ((s_cb(i) - s_cb(i + 2)) + (s_cb(i) - s_cb(i + 3)))/ &
                ((s_cb(i) - s_cb(i + 2))*(s_cb(i) - s_cb(i + 3)))* &
                ((s_cb(i + 1) - s_cb(i)))
            poly_coef_L(2, 0, i + 1) = &
                ((s_cb(i - 2) - s_cb(i)) + (s_cb(i - 1) - s_cb(i + 1)))/ &
                ((s_cb(i - 2) - s_cb(i + 1))*(s_cb(i + 1) - s_cb(i - 1)))* &
                ((s_cb(i) - s_cb(i + 1)))

            d_R(0, i + 1) = &
                ((s_cb(i - 2) - s_cb(i + 1))*(s_cb(i + 1) - s_cb(i - 1)))/ &
                ((s_cb(i - 2) - s_cb(i + 3))*(s_cb(i + 3) - s_cb(i - 1)))
            d_R(2, i + 1) = &
                ((s_cb(i + 1) - s_cb(i + 2))*(s_cb(i + 1) - s_cb(i + 3)))/ &
                ((s_cb(i - 2) - s_cb(i + 2))*(s_cb(i - 2) - s_cb(i + 3)))
            d_L(0, i + 1) = &
                ((s_cb(i - 2) - s_cb(i))*(s_cb(i) - s_cb(i - 1)))/ &
                ((s_cb(i - 2) - s_cb(i + 3))*(s_cb(i + 3) - s_cb(i - 1)))
            d_L(2, i + 1) = &
                ((s_cb(i) - s_cb(i + 2))*(s_cb(i) - s_cb(i + 3)))/ &
                ((s_cb(i - 2) - s_cb(i + 2))*(s_cb(i - 2) - s_cb(i + 3)))

            d_R(1, i + 1) = 1d0 - d_R(0, i + 1) - d_R(2, i + 1)
            d_L(1, i + 1) = 1d0 - d_L(0, i + 1) - d_L(2, i + 1)

            beta_coef(0, 0, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*(10d0*(s_cb(i + 1) - &
                s_cb(i))**2d0 + (s_cb(i + 1) - s_cb(i))*(s_cb(i + 2) - &
                s_cb(i + 1)) + (s_cb(i + 2) - s_cb(i + 1))**2d0)/((s_cb(i) - &
                s_cb(i + 3))**2d0*(s_cb(i + 1) - s_cb(i + 3))**2d0)

            beta_coef(0, 1, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*(19d0*(s_cb(i + 1) - &
                s_cb(i))**2d0 - (s_cb(i + 1) - s_cb(i))*(s_cb(i + 3) - &
                s_cb(i + 1)) + 2d0*(s_cb(i + 2) - s_cb(i))*((s_cb(i + 2) - &
                s_cb(i)) + (s_cb(i + 3) - s_cb(i + 1))))/((s_cb(i) - &
                s_cb(i + 2))*(s_cb(i) - s_cb(i + 3))**2d0*(s_cb(i + 3) - &
                s_cb(i + 1)))

            beta_coef(0, 2, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*(10d0*(s_cb(i + 1) - &
                s_cb(i))**2d0 + (s_cb(i + 1) - s_cb(i))*((s_cb(i + 2) - &
                s_cb(i)) + (s_cb(i + 3) - s_cb(i + 1))) + ((s_cb(i + 2) - &
                s_cb(i)) + (s_cb(i + 3) - s_cb(i + 1)))**2d0)/((s_cb(i) - &
                s_cb(i + 2))**2d0*(s_cb(i) - s_cb(i + 3))**2d0)

            beta_coef(1, 0, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*(10d0*(s_cb(i + 1) - &
                s_cb(i))**2d0 + (s_cb(i) - s_cb(i - 1))**2d0 + (s_cb(i) - &
                s_cb(i - 1))*(s_cb(i + 1) - s_cb(i)))/((s_cb(i - 1) - &
                s_cb(i + 2))**2d0*(s_cb(i) - s_cb(i + 2))**2d0)

            beta_coef(1, 1, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*((s_cb(i) - &
                s_cb(i + 1))*((s_cb(i) - s_cb(i - 1)) + 20d0*(s_cb(i + 1) - &
                s_cb(i))) + (2d0*(s_cb(i) - s_cb(i - 1)) + (s_cb(i + 1) - &
                s_cb(i)))*(s_cb(i + 2) - s_cb(i)))/((s_cb(i + 1) - &
                s_cb(i - 1))*(s_cb(i - 1) - s_cb(i + 2))**2d0*(s_cb(i + 2) - &
                s_cb(i)))

            beta_coef(1, 2, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*(10d0*(s_cb(i + 1) - &
                s_cb(i))**2d0 + (s_cb(i + 1) - s_cb(i))*(s_cb(i + 2) - &
                s_cb(i + 1)) + (s_cb(i + 2) - s_cb(i + 1))**2d0)/ &
                ((s_cb(i - 1) - s_cb(i + 1))**2d0*(s_cb(i - 1) - &
                                                   s_cb(i + 2))**2d0)

            beta_coef(2, 0, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*(12d0*(s_cb(i + 1) - &
                s_cb(i))**2d0 + ((s_cb(i) - s_cb(i - 2)) + (s_cb(i) - &
                s_cb(i - 1)))**2d0 + 3d0*((s_cb(i) - s_cb(i - 2)) + &
                (s_cb(i) - s_cb(i - 1)))*(s_cb(i + 1) - s_cb(i)))/ &
                ((s_cb(i - 2) - s_cb(i + 1))**2d0*(s_cb(i - 1) - &
                                                   s_cb(i + 1))**2d0)

            beta_coef(2, 1, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*(19d0*(s_cb(i + 1) - &
                s_cb(i))**2d0 + ((s_cb(i) - s_cb(i - 2))*(s_cb(i) - &
                s_cb(i + 1))) + 2d0*(s_cb(i + 1) - s_cb(i - 1))*((s_cb(i) - &
                s_cb(i - 2)) + (s_cb(i + 1) - s_cb(i - 1))))/((s_cb(i - 2) - &
                s_cb(i))*(s_cb(i - 2) - s_cb(i + 1))**2d0*(s_cb(i + 1) - &
                s_cb(i - 1)))

            beta_coef(2, 2, i + 1) = &
                4d0*(s_cb(i) - s_cb(i + 1))**2d0*(10d0*(s_cb(i + 1) - &
                s_cb(i))**2d0 + (s_cb(i) - s_cb(i - 1))**2d0 + (s_cb(i) - &
                s_cb(i - 1))*(s_cb(i + 1) - s_cb(i)))/((s_cb(i - 2) - &
                s_cb(i))**2d0*(s_cb(i - 2) - s_cb(i + 1))**2d0)

        end do

        !$acc update device( beta_coef, D_L, D_R, poly_coef_L, poly_coef_R )

        nullify(s_cb)

    end subroutine s_compute_weno_coefficients ! ---------------------------

    subroutine s_finalize_weno_module() ! ----------------------------------

        deallocate (v_rs_wsL)
        deallocate (poly_coef_L, poly_coef_R)
        deallocate (d_L, d_R)
        deallocate (beta_coef)

        deallocate(v_rs_wsL_flat)
        deallocate(v_flat)
        deallocate(vL_vf_flat)
        deallocate(vR_vf_flat)

    end subroutine s_finalize_weno_module ! --------------------------------

end module m_weno
