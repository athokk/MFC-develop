#!/usr/bin/python
import math

#Numerical setup
Nx      = 399
dx      = 1./(1.*(Nx+1))

Ny = 19
dy = 1./(1.*(Ny+1))

Tend    = 6.4E-05
Nt      = 200
mydt    = Tend/(1.*Nt)

# Command to navigate between directories
from os import chdir

# Command to acquire directory path
from os.path import dirname

# Command to acquire script name and module search path
from sys import argv, path

# Navigating to script directory
if len(dirname(argv[0])) != 0: chdir(dirname(argv[0]))

# Adding master_scripts directory to module search path
mfc_dir = '../../src'; path[:0] = [mfc_dir + '/master_scripts']

# Command to execute the MFC components
from m_python_proxy import f_execute_mfc_component

# Selecting MFC component
comp_name = argv[1].strip()

# Serial or parallel computational engine
#engine = 'parallel'
engine = 'serial'
if (comp_name == 'pre_process'): engine = 'serial'
# ==============================================================================

# Case Analysis Configuration ==================================================


# Configuring case dictionary
case_dict =                                                                     \
    {                                                                           \
                    # Logistics ================================================
                    'case_dir'                     : '\'.\'',                   \
                    'run_time_info'                : 'T',                       \
                    'nodes'                        : 1,                         \
                    'ppn'                          : 1,                         \
                    'queue'                        : 'normal',                  \
                    'walltime'                     : '24:00:00',                \
                    'mail_list'                    : '',                        \
                    # ==========================================================
                                                                                \
                    # Computational Domain Parameters ==========================
                    'x_domain%beg'                 : 0.E+00,                    \
                    'x_domain%end'                 : 1.E+00,                    \
                    'y_domain%beg'                 : -1.E-01,                   \
                    'y_domain%end'                 : 1.E-01,                    \
                    'm'                            : Nx,                        \
                    'n'                            : Ny,                         \
                    'p'                            : 0,                         \
                    'dt'                           : mydt,                      \
                    't_step_start'                 : 0,                         \
                    't_step_stop'                  : int(Nt),                        \
                    't_step_save'                  : int(math.ceil(Nt/1)),    \
		    # ==========================================================
                                                                                \
                    # Simulation Algorithm Parameters ==========================
                    'num_patches'                  : 2,                        \
                    'model_eqns'                   : 2,                        \
                    'alt_soundspeed'               : 'F',                      \
                    'num_fluids'                   : 1,                        \
		    'adv_alphan'                   : 'T',                      \
		    'mpp_lim'                      : 'F',                      \
		    'mixture_err'                  : 'F',                      \
		    'time_stepper'                 : 3,                        \
                    'weno_vars'                    : 2,                        \
                    'weno_order'                   : 3,                        \
                    'weno_eps'                     : 1.E-16,                   \
                    'char_decomp'                  : 'F',                      \
                    'mapped_weno'                  : 'F',                      \
                    'null_weights'                 : 'F',                      \
                    'mp_weno'                      : 'F',                      \
		    'riemann_solver'               : 1,                        \
                    'wave_speeds'                  : 1,                        \
                    'avg_state'                    : 2,                        \
                    'commute_err'                  : 'F',                      \
                    'split_err'                    : 'F',                      \
                    'bc_x%beg'                     : -3,                       \
                    'bc_x%end'                     : -3,                       \
                    'bc_y%beg'                     : -3,                       \
                    'bc_y%end'                     : -3,                       \

                    'weno_Re_flux'                 : 'F',                      \
                    # ==========================================================

                    # Turning on Hypoelasticity ================================
                    #'tvd_rhs_flux'                 : ,                      \
                    'hypoelasticity'               : 'T',                      \
                    # ==========================================================
                                                                               \
                    # Formatted Database Files Structure Parameters ============
                    'format'                       : 1,                        \
                    'precision'                    : 2,                        \
                    'prim_vars_wrt'                :'T',                       \
		    'parallel_io'                  :'F',                       \
		    # ==========================================================
                                                                                
		    # Patch 1 L ================================================
                    'patch_icpp(1)%geometry'       : 3,                     \
                    'patch_icpp(1)%x_centroid'     : 0.25,                   \
                    'patch_icpp(1)%y_centroid'     : 0.0,                    \
                    'patch_icpp(1)%length_x'       : 0.5,                    \
                    'patch_icpp(1)%length_y'       : 0.2,                     \
                    'patch_icpp(1)%vel(1)'         : 0.0,   \
                    'patch_icpp(1)%vel(2)'         : 100,                      \
                    'patch_icpp(1)%pres'           : 1E+08,                    \
                    'patch_icpp(1)%alpha_rho(1)'   : 1000,                    \
                    'patch_icpp(1)%alpha(1)'       : 1.,                \
                    'patch_icpp(1)%tau_e(1)'       : 0.0,                \
                    # ==========================================================

                    # Patch 2 R ================================================
                    'patch_icpp(2)%geometry'       : 3,                     \
                    'patch_icpp(2)%x_centroid'     : 0.75,                   \
                    'patch_icpp(2)%y_centroid'     : 0.0,                   \
                    'patch_icpp(2)%length_x'       : 0.5,                    \
                    'patch_icpp(2)%length_y'       : 0.2,                   \
                    'patch_icpp(2)%vel(1)'         : 0.0,                    \
                    'patch_icpp(2)%vel(2)'         : -100,                       \
                    'patch_icpp(2)%pres'           : 1E+05,                    \
                    'patch_icpp(2)%alpha_rho(1)'   : 1000,                    \
                    'patch_icpp(2)%alpha(1)'       : 1.,                \
                    'patch_icpp(2)%tau_e(1)'       : 0.0,                \
                    # ==========================================================

                    # Fluids Physical Parameters ===============================
                    'fluid_pp(1)%gamma'            : 1.E+00/(4.4E+00-1.E+00),   \
                    'fluid_pp(1)%pi_inf'           : 4.4E+00*6.E+08/(4.4E+00 - 1.E+00), \
                    'fluid_pp(1)%G'                : 10.E+9,                       \
	            # ==========================================================
    }

# Executing MFC component
f_execute_mfc_component(comp_name, case_dict, mfc_dir, engine)

# ==============================================================================
