#!/bin/bash

url=www.student.dtu.dk/~nicpa/sisl/workshop/17

function _help {
    echo "This script may be used to install the dependencies for the"
    echo "tutorial such as Python, numpy, scipy matplotlib, jupyter and sisl."
    echo ""
    echo "This script is a two-step script. Please read below."
    echo ""
    echo "If you do not have Python, numpy, scipy, jupyter, matplotlib or sisl installed"
    echo "you should probably run this script in installation mode:"
    echo ""
    echo "  $0 install"
    echo ""
    echo "If you have a working Python installation with pip you may only need"
    echo "to run"
    echo ""
    echo "  pip install --upgrade numpy scipy matplotlib netCDF4 jupyter sisl"
    echo ""
    echo "Once the above steps are fulfilled you should run the download part"
    echo "of the script. It will download the required files for the tutorial:"
    echo ""
    echo "  $0 download"
    echo ""
}

if [ $# -eq 0 ]; then
    _help
    exit 1
fi

# First we get the current directory
cwd=$(pwd)

# Figure out if we are dealing with UNIX or MacOS
os=linux
case "x$OSTYPE" in
    xlinux*)
	os=linux
	;;
    xdarwin*)
	os=macos
	;;
    x*)
	# Try and determine using uname
	case "$(uname -s)" in
	    Linux*)
		os=linux
		;;
	    Darwin*)
		os=macos
		;;
	    *)
		echo "Are you using MingGW or FreeBSD? Or a third?"
		echo "Either way this installation script does not work for your distribution..."
		exit 1
		;;
	esac
	;;
esac
action=install
case $1 in
    install)
	echo nothing > /dev/null
	# do nothing, we use the OS to determine stuff
	action=install
	;;
    update)
	# Update this script
	# Try and update
	base=$(basename $0)
	cp $cwd/$0 $cwd/old_$base
	wget -O $cwd/new_$base $url/install_tutorial.sh
	if [ $? -eq 0 ]; then
	    mv $cwd/new_$base $cwd/$base
	    chmod u+x $cwd/$base
	    echo ""
	    echo "Successfully updated the script..."
	    rm $cwd/old_$base
 	fi
	exit 0
	;;
    download)
	action=download
	;;
    *)
	echo "###########################################"
	echo "# Unknown argument: $1"
	echo "#"
	echo "# Should be either 'install', 'update' or 'download'"
	echo "#"
	echo "###########################################"
	echo ""
	_help
	exit 1
	;;
esac


# Function for installation on Linux
function linux_install {

    # First ensure that the correct packages are installed
    for p in gcc gfortran libhdf5-dev libnetcdf-dev libnetcdff-dev python-dev python-tk python-pip python-pip-whl libatlas3-base liblapack3 libfreetype6-dev libpng12-dev
    do
	sudo apt-get install $p
    done
    
    # Perform the Python installation
    pip install --upgrade six numpy scipy matplotlib netCDF4 jupyter sisl
    if [ $? -ne 0 ]; then
	echo "pip failed to install the packages, will try to install"
	echo "in your user directory, if this fails you will have to fix it"
	pip install --user --upgrade six numpy scipy matplotlib netCDF4 jupyter sisl
	if [ $? -ne 0 ]; then
	    echo ""
	    echo "pip failed to install the packages, in either the global or user domain."
	    echo "Please try and get pip to work and re-run the installation proceduce."
	fi
    fi
    
    # You probably need to add to the path, this is a simplistic way of
    # adding the default ubuntu installation directories
    grep "/.local/bin" ~/.bashrc > /dev/null
    if [ $? -eq 1 ]; then
	echo "" >> ~/.bashrc
	echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc
	echo ""
	echo "PLEASE RESTART YOUR SHELL!"
    fi
    grep "/.local/lib/python2.7" ~/.bashrc > /dev/null
    if [ $? -eq 1 ]; then
	echo "" >> ~/.bashrc
	echo "export PYTHONPATH=\$HOME/.local/lib/python2.7/site-packages:\$PYTHONPATH" >> ~/.bashrc
	echo ""
	echo "PLEASE RESTART YOUR SHELL!"
    fi
    exit 0
}


# Function for installation on Linux
function my_brew {
    brew $@
    if [ $? -ne 0 ]; then
	echo "Running:"
	echo "   brew $@"
	echo "failed."
	echo "If this requests you should do a link brew:"
	echo "   brew link ..."
	echo "then most probably your write access to this folder is prohibited:"
	echo "   /usr/local/include/Frameworks"
	echo "If the folder does not exist, create it."
	exit 1
    fi
}
	
function macos_install {

    # Check that brew is installed?
    which brew 2>/dev/null
    if [ $? -ne 0 ]; then
	echo "You have not installed brew, this script requires that you have brew installed"
	exit 1
    fi
    
    # First we need to install xcode-select
    xcode-select --install

    # Now try and install gcc (it should also include gfortran)
    my_brew install gcc
    # Ensure wget is installed
    my_brew install wget --with-libressl

    # Add the science tap
    my_brew tap homebrew/science

    my_brew install szip hdf5
    my_brew install netcdf --with-fortran
    my_brew install python
    sudo easy_install pip

    pip install --upgrade six numpy scipy matplotlib netCDF4 jupyter sisl
    if [ $? -ne 0 ]; then
	echo "pip failed to install the packages, will try to install"
	echo "in your user directory, if this fails you will have to fix it"
	pip install --user --upgrade six numpy scipy matplotlib netCDF4 jupyter sisl
	if [ $? -ne 0 ]; then
	    echo ""
	    echo "pip failed to install the packages, in either the global or user domain."
	    echo "Please try and get pip to work and re-run the installation proceduce."
	fi
    fi
    exit 0
}

function install_warning {
    echo "RUNNING THIS SCRIPT IS AT YOUR OWN RISK!!!"
    echo "THIS SCRIPT IS MADE FOR HELPFUL PURPOSE, BUT YOU ARE"
    echo "RESPONSIBLE FOR ANY ERRORS/DATALOSSES THIS SCRIPT MAY INFER."
    echo "IF YOU DO NOT WANT TO RUN THIS SCRIPT PRESS:"
    echo ""
    echo "  CTRL+^C"
    echo ""
    sleep 3
}

if [ $action == install ]; then
# os will be download
case $os in
    linux)
	install_warning
	linux_install
	;;
    macos)
	install_warning
    	macos_install
	;;
esac

exit 0
fi

# Now create a common folder in the top-home directory

function download_warning {
    echo ""
    echo "This script will create a folder in your $HOME directory:"
    echo "  $HOME/TBT-TS-sisl-workshop"
    echo "where all the tutorials and executable files will be downloaded."
    echo ""
}

function dwn_file {
    local rname=$1
    local outname=$1
    if [ $# -eq 2 ]; then
	outname=$2
    fi
    if [ ! -e $1 ]; then
	wget -O $outname $url/$(basename $rname)
	if [ $? -eq 0 ]; then
	    chmod u+x $outname
	else
	    rm -f $outname
	fi
    fi
}

download_warning

indir=$HOME/TBT-TS-sisl-workshop
mkdir -p $indir
pushd $indir

# Now download the executables
mkdir -p bin

# Download latest tutorial files
dwn_file sisl-TBT-TS.tar.gz

case $os in
    linux)
	dwn_file bin/transiesta
	dwn_file bin/tbtrans
	;;
    macos)
	dwn_file bin/transiesta_mac bin/transiesta
	dwn_file bin/tbtrans_mac bin/tbtrans
	;;
esac

# We will simply add it if it does not exist
# We also assume the SHELL is BASH
if ! `grep $indir ~/.bashrc` ; then
    echo "" >> ~/.bashrc
    echo "# Variable for the TBT-TS-sisl workshop" >> ~/.bashrc
    echo "export PATH=$indir/bin:\$PATH" >> ~/.bashrc
    echo "" >> ~/.bashrc
fi

echo ""
echo "In folder TBT-TS-sisl-workshop you will find everything needed for the tutorial"
echo "If you use BASH (most likely) you should have transiesta and tbtrans in your path."
echo "Run (after you have restarted your shell):"
echo "  which tbtrans"
echo "and check it returns $indir/bin/tbtrans"
