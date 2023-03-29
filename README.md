# <image src="doc/MFC.png" />

[![DOI](https://zenodo.org/badge/doi/10.1016/j.cpc.2020.107396.svg)](http://dx.doi.org/10.1016/j.cpc.2020.107396)
[![YourActionName Actions Status](https://github.com/ComputationalFlowPhysics/MFC-develop/workflows/CI/badge.svg)](https://github.com/ComputationalFlowPhysics/MFC-develop/actions)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)
[![GitHub latest commit](https://badgen.net/github/last-commit/MFlowCode/MFC-develop)](https://github.com/MFlowCode/MFC-develop/commit/)
 
Welcome to MFC! 
MFC is an exascale-ready fully-documented parallel simulation code for multi-component, multi-phase, high-speed, and bubbly flows.

<p align="center">
 <a href="#authors">Authors</a> | 
 <a href="#publications">Publications</a> | 
 <a href="#installing-mfc">Installing</a> | 
 <a href="#running-mfc">Running</a> | 
 <a href="#testing-mfc">Testing</a> | 
 <a href="#development">Development</a> | 
 <a href="#useful-scripts">Useful Scripts</a> | 
 <a href="https://github.com/MFlowCode/MFC/raw/master/doc/MFC_user_guide.pdf">User's Guide</a> | 
 <a href="https://mflowcode.github.io/">Documentation</a>
</p>

## Authors

<p align="justify">
MFC was first developed by the Colonius research group at Caltech.
Now it is developed and maintained by the groups of Professors <a href="https://comp-physics.group">Spencer Bryngelson</a>, <a href="https://colonius.caltech.edu/">Tim Colonius</a>, and <a href="https://vivo.brown.edu/display/mrodri97">Mauro Rodriguez</a> (alphabetical).
We try to maintain a list of current and past developers in the <a href="AUTHORS">AUTHORS</a> file!
 </p>
 
## Publications
 
### Primary Paper
 
  The paper that describes MFC's capabilities:
* <a href="https://doi.org/10.1016/j.cpc.2020.107396">
        S. H. Bryngelson, K. Schmidmayer, V. Coralic, K. Maeda, J. Meng, T. Colonius (2021) Computer Physics Communications 4655, 107396
        </a>
  
### Related publications
 
  Several publications have used MFC in various stages of its 
  development. A partial list is included here.
 
  Journal papers:
* <a href="https://arxiv.org/abs/2112.14172">
        S. H. Bryngelson, R. O. Fox, T. Colonius (2021) arXiv: 2112.14172.
        </a>
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

## Installing MFC

<p align="justify">
To fetch, build, and run MFC and its dependencies on a UNIX-like system, you must have installed common utilities such as GNU's Make, Python3, its developement headers and libraries, a C/C++ compiler
(GCC, NVHPC, etc., but *not Clang*), and an MPI wrapper (like Open MPI). 
Below are some commands for popular operating systems and package managers.
<p>

[Anaconda](https://www.anaconda.com/) may interfere with the building process. If an issue arises, you can either uninstall the affected Anaconda packages, change the ordering of directory paths in your `$PATH`, or make aliases to the correct binaries.
 
### \*nix 
 
- **Via [Aptitude](https://wiki.debian.org/Aptitude):**

```console
$ sudo apt install tar wget make cmake gcc g++ python3 "openmpi-*" python python-dev python3-dev python3-venv libopenmpi-dev
```
 
If you wish to build MFC using [NVidia's NVHPC SDK](https://developer.nvidia.com/hpc-sdk), follow the instructions [here](https://developer.nvidia.com/nvidia-hpc-sdk-downloads).

### MacOS (including x86 and M1/Apple Silicon) [**via [Homebrew](https://brew.sh/)**]
 
 - **MacOS v10.15 (Catalina) or newer [ZSH]**

```console
$ touch ~/.zshrc
$ open ~/.zshrc
```

 - **Older than MacOS v10.15 (Catalina) [BASH]**
 
```console
$ touch ~/.bash_profile
$ open ~/.bash_profile
```
 
An editor should open. Please paste the following lines into it before saving the file. If you wish to use a version of GNU's GCC other than 11, modify the first assignment. These lines ensure that LLVM's Clang, and Apple's modified version of GCC, won't be used to compile MFC. Further reading on `open-mpi` incompatibility with `clang`-based `gcc` on macOS: [here](https://stackoverflow.com/questions/27930481/how-to-build-openmpi-with-homebrew-and-gcc-4-9). We do *not* support `clang` due to conflicts with our Silo dependency.

```console
# === MFC MPI Installation ===
export MFC_GCC_VER=11
export HOMEBREW_CC=gcc-$MFC_GCC_VER
export HOMEBREW_CXX=g++-$MFC_GCC_VER
export OMPI_MPICC=gcc-$MFC_GCC_VER
export OMPI_CXX=g++-$MFC_GCC_VER
export OMPI_FC=gfortran-$MFC_GCC_VER
# === MFC MPI Installation ===
```

Close your the open editor **and** terminal windows. Open a **new terminal** window before executing the commands bellow.

```console
$ brew install wget make python make cmake coreutils gcc@$MFC_GCC_VER
$ brew install --build-from-source open-mpi
```
 
 They will download the dependencies MFC requires to build itself. `open-mpi` will be compiled from source, using the version of GCC we specified above with the environment variables `HOMEBREW_CC` and `HOMEBREW_CXX`. Building this package might take a while.

### Fetch and build MFC

The following commands fetch and build MFC and its required dependencies. 
The dependencies are built to the `build/common/` directory within your MFC installation. 
This should have no impact on your local installation(s) of these packages.

+ **Fetch MFC:**

```console
$ git clone https://github.com/MFlowCode/MFC
$ cd MFC
```

+ **(Optional) Configure MFC defaults in [mfc.user.yaml](mfc.user.yaml):**

If you wish, you can override MFC's default build parameters in [mfc.user.yaml](mfc.user.yaml), a file intended for user customisation. This can greatly reduce the number of command-line arguments you have to pass to [mfc.sh](mfc.sh)` in the following sections. You can do this at any time.

+ **Build MFC and its dependencies with 8 threads in `release-cpu` mode:**

```console
$ ./mfc.sh build -j 8
```

To build MFC in different configurations (herein, *modes*), the `-m <mode>` option
can be specified to each call to `mfc.sh`. A full list of modes is located in
[mfc.user.yaml](mfc.user.yaml). It can be modified to work with system, and additional
modes can be created at your discretion. The default mode is `release-cpu` but
you can use others such as `release-gpu`.

**IMPORTANT NOTE**: This same mode will be used for any future commands such as `./mfc.sh test` and `./mfc.sh run` until you specify `-m` again (in any of these commands).

+ Run MFC's tests with as many concurrent processes as you wish to make sure it was correctly built and your environment is adequate

```console
$ ./mfc.sh test -j $(nproc)
```

Please refer to the [Testing](#testing-mfc) section of this document for more information. 

## User Configuration (`mfc.user.yaml`)

The `mfc.sh` script used in the previous section is configured through the file named `mfc.user.yaml`.

# Running MFC

The MFC can be run using `mfc.sh`'s `run` command. It supports both serial and
parallel execution, the latter being designed for multi-socket systems, namely supercomputers,
equipped with a scheduler such as PBS, SLURM, and LSF. A full (and updated) list
of available arguments can be acquired with `./mfc.sh run -h`. Example Python input
files can be found in the [samples/](samples/) directory, and they are often called `input.py`
or `case.py`. They print a Python dictionary containing input parameters for the
MFC. Their contents, and a guide to filling them out, are documented
in the user manual. A commented, tutorial script
can also be found in [samples/3d_sphbubcollapse/](samples/3D_sphbubcollapse/).

## Serial Execution (`-e serial`)

To run all stages of MFC, that is [pre_process](src/pre_process_code/), [simulation](src/simulation_code/), and [post_process](src/post_process_code/) on the sample case [2D_shockbubble](samples/2D_shockbubble/),

```console
$ ./mfc.sh run samples/2D_shockbubble/case.py
```

If you want to run a subset of the available stages, you can use the `-t` argument.
To use multiple threads, use the `-n` option along with the number of threads you wish to use.
If a (re)build is required, it will be done automatically, with the number of threads
specified with the `-j` option.

For example,

- Running [pre_process](src/pre_process_code/) with 2 cores:

```console
$ ./mfc.sh run samples/2D_shockbubble/case.py -t pre_process -n 2
```

- Running [simulation](src/simulation_code/) and [post_process](src/post_process_code/)
using 4 cores:

```console
$ ./mfc.sh run samples/2D_shockbubble/case.py -t simulation post_process -n 4
```

Most parameters have sensible defaults which can be overridden in [mfc.user.yaml](mfc.user.yaml):

https://github.com/MFlowCode/MFC-develop/blob/d74e714b08562a9f8f815112e05df54c99c8c18f/mfc.user.yaml#L12-L21

On some computer clusters, MFC might select the wrong MPI program to execute your application
because it uses a general heuristic for selection. Notably, `srun` is known to fail on some SLURM
systems in GPU mode, whereas `mpirun` functions properly. To override and manually specify which
MPI program you wish to run your application with, please use the `-b <program name>` option (i.e `--binary`).

Additional flags can be given appended to the MPI executable call using the `-f` (i.e `--flags`) option.

Please refer to `./mfc.sh run -h` for a complete list of arguments and options, along with their defaults.

## Batch Submission (`-e parallel`)

The MFC detects which scheduler your system is using and handles the creation and
execution of batch scripts. The parallel engine is requested with the `-e parallel` option.
Whereas the serial engine can execute all MFC's codes in succession, the parallel engine
requires you to only specify one target with the `-t` option. The number of nodes and GPUs can, 
respectively be specified with the `-N` (i.e `--nodes`) and `-g` (i.e `--gpus-per-node`) options.

```console
$ ./mfc.sh run samples/2D_shockbubble/case.py -e parallel -N 2 -n 4 -g 4 -t simulation
```

Other useful arguments include:

- `-# <job name>` to name your job. (i.e `--name`)
- `-@ sample@example.com` to receive emails from the scheduler. (i.e `--email`)
- `-w hh:mm:ss` to specify the job's maximum allowed walltime. (i.e `--walltime`)
- `-a <account name>` to identify the account to be charged for the job. (i.e `--account`)
- `-p <partition name>` to select the job's partition. (i.e `--partition`)

Since some schedulers don't have a standardized syntax to request GPUs, MFC can only
provide support for a restricted subset of common configuration options. If MFC fails
to execute on your system, or if you wish to adjust how the program runs and resources
are requested to be allocated, you are welcome to modify the template for your queue system.
Upon execution of `./mfc.sh run`, MFC fills in the template with runtime parameters, to
generate the batch file it will submit. These files are located in the [templates](templates/)
directory. To request GPUs, modification of the template will be required with most queue
systems.

- Lines that begin with "#>" are ignored and won't figure in the final batch
script, not even as a comment.

- Statements of the form `${expression}` are string-replaced by mfc.sh run to provide
runtime parameters, most notably execution options. They reference the variables in the
same format as those under the "run" section of [mfc.user.yaml](mfc.user.yaml), replacing*
"-" for "_". You can perform therein any Python operation recognized by the built-in `expr()` function.

As an example, on might request GPUs on a SLURM system using the following:

```
#SBATCH --gpus=v100-32:{gpus_per_node*nodes}
```

- Statements of the form `{MFC::expression}` tell MFC where to place the common code,
across all batch files that is required to run MFC. They are not intended to be
modified by users.

**Disclaimer**: IBM's JSRUN on LSF-managed computers does use the traditional node-based approach to
allocate resources. Therefore, the MFC constructs equivalent resource-sets in task and GPU count.

### Example Runs

- Oak Ridge National Laboratory's [Summit](https://www.olcf.ornl.gov/summit/):

```console
$ ./mfc.sh run samples/2D_shockbubble/case.py -e parallel    \
               -N 2 -n 4 -g 4​ -t simulation -a <redacted>
```

- University of California, San Diego's [Expanse](https://www.sdsc.edu/services/hpc/expanse/):

```console
$ ./mfc.sh run samples/2D_shockbubble/case.py -e parallel -p GPU -t simulation​ \
               -N 2 -n 8 -g 8​ -f="--gpus=v100-32:16" -b mpirun –w 00:30:00
```

# Testing MFC
 
To run MFC's test suite, simply run `./mfc.sh test`. It will generate and run test cases, to compare their output to that of previous runs from versions of MFC considered to be accurate. *golden files*, stored in the `tests/` directory contain this data, by aggregating `.dat` files generated when running MFC. A test is considered passing within a very small margin of error, to maintain a high level of stability and accuracy across versions of MFC.
 
Adding a new test case is as simple as modifying [bootstrap/tests/cases.py](bootstrap/tests/cases.py), and selecting which parameters you want to vary from the base case. Then run `./mfc.sh test -g` (i.e `--generate`) to generate new golden files. Please make sure that these files are generated with accurate data.

If you want to only run certain tests, you can pass the argument `-o` (i.e `--only`) along with the associated hash. A test's hash is a hexadecimal representation of the hash of the parameters given to MFC by a certain test. They look like `1A6B6EB3` and are used to refer to a specific test, as they don't change if tests are added or removed, since they are not based on execution order, but rather on test content. However, if a test's parameters change, its hash also changes (ignoring collisions).

An example of running targeted tests:
```console
$ ./mfc.sh test -j 8 -o 1A6B6EB3 0F5DB706
```

# Development

## Fypp

MFC uses [Fypp](https://github.com/aradi/fypp), a Python-based Fortran preprocessor to reduce code duplication. `.fpp` files are converted into regular `.f90` files as part of the build process. Documentation for Fypp can be found [here](https://fypp.readthedocs.io/en/stable/). 

You can inspect the generated `.f90` files located in `build/<mode name>/src/<name of target>/src`.

# Useful Scripts

## Loading Modules

On computer systems that run using environment modules, with implementations like [TACC's Lmod](https://github.com/TACC/Lmod), MFC provides a script that can load modules that have been used by contributors.

```console
$ . ./mfc.sh load
``` 

The list of modules offered by a system is subject to change. The aforementioned script serves as a convenient way to load modules that should work for most users of MFC. 

## OpenACC Memory Profiling

You can append `-DMFC_MEMORY_DUMP` to `release-gpu`'s Fortran compiler options in [mfc.user.yaml](mfc.user.yaml) to make the [simulation code](src/simulation_code/) call `acc_present_dump()` at various stages of program execution to obtain a printout of on-device memory usage. The [mem_parse.sh](misc/mem_parse.sh) script can be given as an argument the path to a file containing MFC's output, in order to aggregate the data and produce tables with formatted output.

# License
 
Copyright 2022.
MFC is under the MIT license (see [LICENSE](LICENSE) file for full text).

# Acknowledgements
 
<p align="justify">
The development of MFC was supported in part by multiple current and past grants from the US Office of Naval Research (ONR), the US National Institute of Health (NIH), and the US National Science Foundation (NSF).
MFC computations utilize the Extreme Science and Engineering Discovery Environment (XSEDE), under allocations TG-CTS120005 (PI Colonius) and TG-PHY210084 (PI Bryngelson) and ORNL Summit under allocation CFD154 (PI Bryngelson).
 </p>
