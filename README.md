# Multi-component Flow Code (MFC)

Welcome to the MFC! The MFC is a fully-documented parallel simulation software
for multi-component, multi-phase, and bubbly flows.

# Authors

  MFC was developed at Caltech by a group of post-doctoral scientists and graduate research students under the supervision of Professor Tim Colonius.
  These contributors include:
* Dr. Spencer Bryngelson
* Dr. Kevin Schmidmayer
* Dr. Vedran Coralic
* Dr. Jomela Meng
* Dr. Kazuki Maeda  

  and their contact information is located in the `AUTHORS` file in the source code.

# Documentation
 
  The following codes are documented, please follow the links to see their Doxygen:
* <a href="https://mfc-caltech.github.io/pre_process/namespaces.html">Pre_process</a> 
* <a href="https://mfc-caltech.github.io/simulation/namespaces.html">Simulation</a> 
* <a href="https://mfc-caltech.github.io/post_process/namespaces.html">Post_process</a>
 

## User's guide
 
  A user's guide is included 
  <a href="https://github.com/ComputationalFlowPhysics/MFC-Caltech/raw/master/doc/MFC_user_guide.pdf">here.</a>
 
## MFC paper
 
  The paper that describes the MFC's capabilities:
* <a href="https://doi.org/10.1016/j.cpc.2020.107396">
        S. H. Bryngelson, K. Schmidmayer, V. Coralic, K. Maeda, J. Meng, T. Colonius (2020) Computer Physics Communications 4655, 107396
        </a>
  
## Related publications
 
  Several publications have used the MFC in various stages of its 
  development. A partial list is included here.
 
  Refereed journal publications:
* <a href="https://asa.scitation.org/doi/full/10.1121/10.0000746">
        S. H. Bryngelson and T. Colonius (2020) Journal of the Acoustical Society of America, Vol. 147, pp. 1126-1135
        </a>
* <a href="https://www.sciencedirect.com/science/article/pii/S0021999119307855">
        K. Schmidmayer, S. H. Bryngelson, T. Colonius (2020) Journal of Computational Physics, Vol. 402, 109080
        </a>
* <a href="http://colonius.caltech.edu/pdfs/BryngelsonSchmidmayerColonius2019.pdf">
        S. H. Bryngelson, K. Schmidmayer, T. Colonius (2019) International Journal of Multiphase Flow, Vol. 115, pp. 137-143  
        </a>
* <a href="http://colonius.caltech.edu/pdfs/MaedaColonius2019.pdf">
        K. Maeda and T. Colonius (2019) Journal of Fluid Mechanics, Vol. 862, pp. 1105-1134 
        </a>
* <a href="http://colonius.caltech.edu/pdfs/MaedaColonius2018c.pdf">
        K. Maeda and T. Colonius (2018) Journal of Computational Physics, Vol. 371, pp. 994-1017 
        </a>
* <a href="http://colonius.caltech.edu/pdfs/MengColonius2018.pdf">
        J. C. Meng and T. Colonius (2018) Journal of Fluid Mechanics,  Vol. 835, pp. 1108-1135 
        </a>
* <a href="http://colonius.caltech.edu/pdfs/MaedaColonius2017.pdf">
        K. Maeda and T. Colonius (2017) Wave Motion, Vol. 75, pp. 36-49 
        </a>
* <a href="http://colonius.caltech.edu/pdfs/MengColonius2015.pdf">
        J. C. Meng and T. Colonius (2015) Shock Waves, Vol. 25(4), pp. 399-414 
        </a>
* <a href="http://colonius.caltech.edu/pdfs/CoralicColonius2014.pdf">
        V. Coralic and T. Colonius (2014) Journal of Computational Physics, Vol. 274, pp. 95-121 
        </a>
 
 
Ph.D. Disserations:
* <a href="https://thesis.library.caltech.edu/11395/">
        J.-C. Veilleux (2019) Ph.D. thesis, California Institute of Technology 
        </a>
* <a href="https://thesis.library.caltech.edu/11007/">
        K. Maeda (2018) Ph.D. thesis, California Institute of Technology 
        </a>
* <a href="https://thesis.library.caltech.edu/9764/">
        J. Meng (2016) Ph.D. thesis, California Institute of Technology
        </a>
* <a href="https://thesis.library.caltech.edu/8758/">
        V. Coralic (2014) Ph.D. thesis, California Institute of Technology
        </a>



# Installation
 
  The documents that describe how to configure and install the MFC are located in the 
  source code as `CONFIGURE` and `INSTALL`. They are also described here.
 
## Step 1: Configure and ensure dependencies can be located
 
 
### Main dependencies: MPI and Python 
  If you do not have Python, it can be installed via
  <a href="https://brew.sh/">Homebrew on OSX</a> as:  
`brew install python`
 
  or compiled via your favorite package manager on Unix systems.
 
  An MPI fortran compiler is required for all systems.
  If you do not have one, Homebrew can take care of this
  on OSX:  

`brew install open-mpi` or `brew install mpich`    

  If a gcc v10.1+ backend is used, then the additional flag `-fallow-argument-mismatch` must be added to `FFLAGS` in `Makefile.user`.
  MPICH and Open-MPI can be compiled via another package manager on *nix systems.
 
### Simulation code dependency: FFTW 

If you already have FFTW compiled:
* Specify the location of your FFTW library and
      include files in Makefile.user (`fftw_lib_dir` and
      `fftw_include_dir`)  


If you do not have FFTW compiler, the library and
  installer are included in this package. Just:  
`cd installers`  
`./install_fftw.sh`  
 
### Post process code dependency: Silo/HDF5
 
  Post-processing of parallel data files is not required,
  but can indeed be handled with the MFC. For this, HDF5
  and Silo must be installed
 
  On OSX, a custom Homebrew tap for Silo is included in the installers
  directory. You can use it via  
`cd installers`  
`brew install silo.rb`  
 
  This will install silo and its dependences (including HDF5)
  in their usual locations (`/usr/local/lib` and
  `/usr/local/include`)
 
  On Unix systems, you can install via a package manager or
  from source. On CentOS (also Windows 7), HDF5
  binaries can be found <a href="https://support.hdfgroup.org/ftp/HDF5/current18/bin/">here.</a>
  
  Untar this archive in your intended location via  
`tar -zxf [your HDF5 archive]`  
  
  Silo should be downloaded 
  <a href="https://wci.llnl.gov/simulation/computer-codes/silo/downloads">here,</a>
  then  
`tar -zxf [your Silo archive]`  
`cd [your Silo archive]`  
`./configure --prefix=[target installation directory] --enable-pythonmodule --enable-optimization --disable-hzip --disable-fpzip FC=mpif90 F77=mpif77 -with-hdf5=[your hdf5 directory]/include,/[your hdf5 directory]/lib --disable-silex`  
`make`  
`make install`  
 
  Add the following line to your `~/.bash_profile`:  
  `export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/[your silo directory]/lib:/[your hdf5 directory]/lib`
 
  Finally:  
`source ~/.bash_profile`  
  
  You will then need to modify `silo_lib_dir` and `silo_include_dir` in
  `Makefile.user` to point to your silo directory.
 
## Step 2: Build and test
 
  Once all dependencies have been installed, the MFC can be built via  
`make`
 
  from the MFC directory. This will build all MFC components. Individual
  components can be built via  
`make [component]`  
 
  where `[component]` is one of `pre_process`, `simulation`, or `post_process`.
 
  Once this is completed, you can ensure that the software is working
  as intended by  
`make test`  

# Running

The MFC can be run by changing into
a case directory and executing the appropriate Python input file.
Example Python input files can be found in the 
`example_cases` directories, and they are called `input.py`.
Their contents, and a guide to filling them out, are documented
in the user manual. A commented, tutorial script
can also be found in `example_cases/3d_sphbubcollapse`.
MFC can be executed as  
`python pre_process`

which will generate the restart and grid files that will be read 
by the simulation code. Then  
`python simulation`

will execute the flow solver. The last (optional) step
is to post treat the data files and output HDF5 databases
for the flow variables via  
`python post_process`

Note that the post-processing step 
requires installation of Silo and HDF5.

# License
 
MFC is under the MIT license (see the LICENSE file)

# Acknowledgements
 
The development of the MFC  was supported in part by multiple past grants from the US Office of 
Naval Research (ONR), the US National Institute of 
Health (NIH), and the US National Science Foundation (NSF), as well as current ONR grant numbers 
N0014-17-1-2676 and N0014-18-1-2625 and NIH grant number 2P01-DK043881.
The computations presented here utilized the Extreme Science
and Engineering Discovery Environment, which is supported under NSF
grant number CTS120005. K.M. acknowledges support from the Funai Foundation
for Information Technology via the Overseas Scholarship.
