#!/usr/bin/env python3

import math

x0      = 10.E-06
p0      = 101325.
rho0    = 1.E+03
c0      = math.sqrt( p0/rho0 )
patm    = 1.

#water props
## AKA little \gamma (see coralic 2014 eq'n (13))
n_tait  = 7.1
## AKA little \pi(see coralic 2014 eq'n (13))
B_tait  = 306.E+06 / p0

mul0    = 1.002E-03     #viscosity
ss      = 0.07275       #surface tension
# ss      = 1.E-12 ## this would turn-off surface tension
pv      = 2.3388E+03    #vapor pressure

# water 
# These _v and _n parameters ONLY correspond to the bubble model of Preston (2010 maybe 2008)
# (this model would replace the usual Rayleigh-plesset or Keller-miksis model (it's more compilcated))
#gamma_v = 1.33
#M_v     = 18.02
#mu_v    = 0.8816E-05
#k_v     = 0.019426

##air props
#gamma_n = 1.4
#M_n     = 28.97
#mu_n    = 1.8E-05
#k_n     = 0.02556

#air props
gamma_gas = 1.4

#reference bubble size
R0ref   = 10.E-06

pa      = 0.1 * 1.E+06 / 101325.

print(('pa',pa))

#Characteristic velocity
uu = math.sqrt( p0/rho0 )
#Cavitation number
Ca = (p0 - pv)/(rho0*(uu**2.))
#Weber number
We = rho0*(uu**2.)*R0ref/ss
#Inv. bubble Reynolds number
Re_inv = mul0/(rho0*uu*R0ref)

#IC setup
vf0     = 0.00004
n0      = vf0/(math.pi*4.E+00/3.E+00)

cphysical = 1475.
t0      = x0/c0

nbubbles = 1 
myr0    = R0ref


# CFL numebr should be < 1  for numerical stability
# CFL = speed of sound * dt/dx
cfl     = 0.1
Nx      = 100
Ldomain = 20.E-03
L       = Ldomain/x0
dx      = L/float(Nx)
dt      = cfl*dx/(cphysical/c0)

Lpulse  = 0.3*Ldomain
Tpulse  = Lpulse/cphysical
Tfinal  = 0.25*10.*Tpulse*c0/x0
Nt      = int(Tfinal/dt)

Nfiles = 20.
Nout = int(math.ceil(Nt/Nfiles))
Nt = int(Nout*Nfiles)

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

# ==============================================================================

# Case Analysis Configuration ==================================================

# Selecting MFC component
comp_name = argv[1].strip()

# Serial or parallel computational engine
engine = 'serial'
if (comp_name=='pre_process'): engine = 'serial'

# Configuring case dictionary
case_dict =                                                                     \
    {                                                                           \
                    # Logistics ================================================
                    'case_dir'                     : '\'.\'',                   \
                    'run_time_info'                : 'T',                       \
                    'nodes'                        : 1,                         \
                    # processes per node... > 1 indicates parallel (avoid this for now)
                    'ppn'                          : 1,                         \
                    'queue'                        : 'normal',                  \
                    'walltime'                     : '24:00:00',                \
                    'mail_list'                    : '',                        \
                    # ==========================================================
                                                                                \
                    # Computational Domain Parameters ==========================
                    'x_domain%beg'                 : -10.E-03/x0,               \
                    'x_domain%end'                 :  10.E-03/x0,               \
                    'stretch_x'                    : 'F',                       \
                    'cyl_coord'                    : 'F',                       \
                    'm'                            : Nx,                        \
                    'n'                            : 0,                         \
                    'p'                            : 0,                         \
                    'dt'                           : dt,                      \
                    't_step_start'                 : 0,                         \
                    't_step_stop'                  : Nt,                        \
                    't_step_save'                  : Nout,   \
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
                    'weno_order'                   : 5,                        \
                    'weno_eps'                     : 1.E-16,                   \
                    'char_decomp'                  : 'F',                      \
                    'mapped_weno'                  : 'T',                      \
                    'null_weights'                 : 'F',                      \
                    'mp_weno'                      : 'T',                      \
		    'riemann_solver'               : 2,                        \
                    'wave_speeds'                  : 1,                        \
                    'avg_state'                    : 2,                        \
                    'commute_err'                  : 'F',                      \
                    'split_err'                    : 'F',                      \
                    'bc_x%beg'                     : -8,                       \
                    'bc_x%end'                     : -8,                       \
                    # ==========================================================
                                                                               \
                    # Formatted Database Files Structure Parameters ============
                    'format'                       : 1,                        \
                    'precision'                    : 2,                        \
                    'prim_vars_wrt'                :'T',                       \
		    'parallel_io'                  :'T',                       \
	            'fd_order'                     : 1,                       \
                    #'schlieren_wrt'                :'T',                      \
		    'probe_wrt'                    :'T',                   \
		    'num_probes'                   : 1,                    \
		    'probe(1)%x'                   : 0.,             \
		    # ==========================================================
                                                                                
                    # Patch 1 _ Background =====================================
                    # this problem is 1D... so based on the dimension of the problem
                    # you have different 'geometries' available to you
                    # e.g. in 3D you might have spherical geometries
                    # and rectangular ones
                    # in 1D (like here)... there is only one option {#1}... which is a 
                    # line
                    'patch_icpp(1)%geometry'       : 1,                         \
                    'patch_icpp(1)%x_centroid'     : 0.,                        \
                    'patch_icpp(1)%length_x'       : 20.E-03/x0,                \
                    'patch_icpp(1)%vel(1)'         : 0.0,                       \
                    'patch_icpp(1)%pres'           : patm,                      \
                    # \alpha stands for volume fraction of this phase
                    # so if there are no bubbles, then it is all water (liquid)
                    # and \alpha_1 = \alpha_liquid \approx 1 
                    'patch_icpp(1)%alpha_rho(1)'   : (1.-1.E-12)*(1.E+03/rho0), \
                    # \alpha_1 here is always (for num_fluids = 1 and bubbles=True)
                    # \alpha is always the void fraction of bubbles (usually << 1)
                    'patch_icpp(1)%alpha(1)'       : 1.E-12,                    \
                    # dimensionless initial bubble radius
                    'patch_icpp(1)%r0'             : 1.,                        \
                    # dimensionless initial velocity
                    'patch_icpp(1)%v0'             : 0.0E+00,                   \
                    # ==========================================================

                    # Patch 2 Screen ===========================================
                    'patch_icpp(2)%geometry'       : 1,                         \
                    #overwrite the part in the middle that was the
                    #background (no bubble) area
                    'patch_icpp(2)%alter_patch(1)' : 'T',                       \
                    'patch_icpp(2)%x_centroid'     : 0.,                        \
                    'patch_icpp(2)%length_x'       : 5.E-03/x0,                 \
                    'patch_icpp(2)%vel(1)'         : 0.0,                       \
                    'patch_icpp(2)%pres'           : patm,                      \
                    # \alpha stands for volume fraction of this phase
                    # so if there are no bubbles, then it is all water (liquid)
                    # and \alpha_1 = \alpha_liquid \approx 1 
                    # in the screen case, you have \alpha_1 = 1 - \alpha_bubbles = 1 - vf0
                    'patch_icpp(2)%alpha_rho(1)'   : (1.-vf0)*1.E+03/rho0,   \
                    # void fraction of bubbles
                    'patch_icpp(2)%alpha(1)'       : vf0,                       \
                    'patch_icpp(2)%r0'             : 1.,                        \
                    'patch_icpp(2)%v0'             : 0.0E+00,                   \
                    # ==========================================================

                    # Fluids Physical Parameters ===============================
                    # Surrounding liquid
                    'fluid_pp(1)%gamma'             : 1.E+00/(n_tait-1.E+00),  \
                    'fluid_pp(1)%pi_inf'            : n_tait*B_tait/(n_tait-1.),   \
                    # 'fluid_pp(1)%mul0'              : mul0,     \
                    # 'fluid_pp(1)%ss'                : ss,       \
                    # 'fluid_pp(1)%pv'                : pv,       \
                    # 'fluid_pp(1)%gamma_v'           : gamma_v,  \
                    # 'fluid_pp(1)%M_v'               : M_v,      \
                    # 'fluid_pp(1)%mu_v'              : mu_v,     \
                    # 'fluid_pp(1)%k_v'               : k_v,      \

                    # Last fluid_pp is always reserved for bubble gas state ===
                    # if applicable  ==========================================
                    'fluid_pp(2)%gamma'             : 1./(gamma_gas-1.),      \
                    'fluid_pp(2)%pi_inf'            : 0.0E+00,      \
                    # 'fluid_pp(2)%gamma_v'           : gamma_n,      \
                    # 'fluid_pp(2)%M_v'               : M_n,          \
                    # 'fluid_pp(2)%mu_v'              : mu_n,         \
                    # 'fluid_pp(2)%k_v'               : k_n,          \
                    # ==========================================================

                    # Non-polytropic gas compression model AND/OR Tait EOS =====
                    'pref'                  : p0,                  \
                    'rhoref'                : rho0,                \
                    # ==========================================================

                    # Bubbles ==================================================
                    'bubbles'               : 'T',                  \
                    # in user guide... 1 = gilbert 2 = keller-miksis
                    # but gilbert won't work for the equations that you are using... (i think)
                    'bubble_model'          : 2,                  \
                    # polytropic: this is where the different between Rayleigh--Plesset and 
                    # Preston's model shows up. polytropic = False means complicated Preston model
                   # = True means simpler Rayleigh--Plesset model
                    # if polytropic == False then you will end up calling s_initialize_nonpoly in 
                    # m_global_parameters.f90 in both the pre_process and simulation_code
                    'polytropic'            : 'T',                  \
                    'polydisperse'          : 'F',                  \
                    #'poly_sigma'            : 0.3,                  \
                    # only matters if polytropic = False (complicated model)
                    # 'thermal'               : 3,           \
                    # only matters if polytropic = False (complicated model)
                    'R0ref'                 : myr0,                 \
                    'nb'                    : 1,             \
                    # cavitation number (has something to do with the ratio of gas to vapour in the bubble)
                    # this is usually near 1
                    # can set = 1 for testing purposes
                    'Ca'                    : Ca,                   \
                    # weber number (corresponds to surface tension) 
                    'Web'                   : We,                   \
                    # inverse reynolds number (coresponds to viscosity)
                    'Re_inv'                : Re_inv,               \
                    # ==========================================================

                    # Acoustic source ==========================================
                    'Monopole'                  : 'T',                  \
                    'num_mono'                  : 1,                  \
                    'Mono(1)%loc(1)'            : -5.E-03/x0,  \
                    'Mono(1)%npulse'            : 1, \
                    'Mono(1)%dir'               : 1., \
                    'Mono(1)%pulse'             : 1, \
                    'Mono(1)%mag'               : pa, \
                    'Mono(1)%length'            : (1./(300000.))*cphysical/x0, \
                    # ==========================================================
    }

# Executing MFC component
f_execute_mfc_component(comp_name, case_dict, mfc_dir, engine)

# ==============================================================================
