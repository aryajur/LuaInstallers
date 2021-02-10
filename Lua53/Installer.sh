#!/bin/bash
# Script to install the certificate renewal package
# Run the script with the command:
# > sudo sh ./Installer.sh

######################## CONFIGURATION SETTINGS ####################


# Setup Flags
ILUA="YES"
ILUASHARED = "NO"
ILUASOCKET="YES"
ILFS="YES"
ILUA_AWS="YES"
ILUASQL="YES"
ILUASEC="YES"
ILPTY="YES"
ISRLUA="NO"

INSTALLDIR="/opt/software/LuaScripts"

LUAV="5.3.6"
LUASOCKETSHA="5b18e475f38fcf28429b1cc4b17baee3b9793a62"
CURPATH=$(pwd)
LFSVER="1_7_0_2"
GCCLUAINC="-I$INSTALLDIR/inc"
#echo $GCCLUAINC
LUA_AWSSHA="a14d26ff35b3fad2b45ae07c242a2cf781ec90ae"	# From aryajur pull request
LUASQLSHA="5e65ae41f87f545070f378e4882fa1ef87287fa5"
OPENSSL="openssl-1.1.1g"
LUASECSHA="22eadbd20e1e9a53b0f55b38c731e04e935a9595"
LPTY="lpty-1.2.2-1"

###################################################################

if [ -d "$INSTALLDIR" ]; then
	# Control will enter here if $DIRECTORY exists.
	echo "Clear the Installation Directory..."
	sudo rm -rf $INSTALLDIR/*
	read -r -p "DONE. Press Enter to Continue" response
else
	mkdir $INSTALLDIR
fi

cd $INSTALLDIR

if [ "$ILUA" == "YES" ]
then
	# Install the readline library
	echo "#############################################################"
	echo "                                                             "
	echo "### Install Lib Readline   --------------------------------->"
	echo "                                                             "
	echo "#############################################################"
	sudo apt-get --assume-yes install libreadline6 libreadline6-dev
	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Installing LibReadline--------->"
	echo "                                                             "
	echo "#############################################################"

	# Download and build Lua 5.3
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build Lua --------------------------------->"
	echo "                                                             "
	echo "#############################################################"
	wget http://www.lua.org/ftp/lua-$LUAV.tar.gz
	tar zxf lua-$LUAV.tar.gz
	cd lua-$LUAV
	if [ "$ILUASHARED" == "YES" ]
	then
		# To patch lua to build as a shared library
		patch -Np1 -i ../../lua-5.3.5-shared_library-1.patch
	fi
	make linux test

	# Create directory for Lua setup
	cd ..
	cp lua-$LUAV/src/lua $INSTALLDIR/.

	# Copy the include files
	if [ -d "$INSTALLDIR/inc" ]; then
		sudo rm -rf $INSTALLDIR/inc
	fi
	mkdir $INSTALLDIR/inc
	cp lua-$LUAV/src/lauxlib.h $INSTALLDIR/inc/.
	cp lua-$LUAV/src/lua.h $INSTALLDIR/inc/.
	cp lua-$LUAV/src/luaconf.h $INSTALLDIR/inc/.
	cp lua-$LUAV/src/lualib.h $INSTALLDIR/inc/.
	rm -rf lua-$LUAV
	rm -f *.tar.gz

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Building Lua------------------------->"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$ILUASOCKET" == "YES" ]
then
	# Download and build luasocket
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build Luasocket---------------------------->"
	echo "                                                             "
	echo "#############################################################"
	wget https://github.com/diegonehab/luasocket/archive/$LUASOCKETSHA.tar.gz
	tar zxf $LUASOCKETSHA.tar.gz
	cd luasocket-$LUASOCKETSHA
	make linux LUAV=5.3 LUAINC_linux_base=$INSTALLDIR LUAINC_linux=$INSTALLDIR/inc LUAPREFIX_linux=$INSTALLDIR CDIR_linux=$INSTALLDIR LDIR_linux=$INSTALLDIR
	cd ..

	# Transfer files to certRenew
	if [ -d "$INSTALLDIR/socket" ]; then
		sudo rm -rf $INSTALLDIR/socket
	fi
	mkdir $INSTALLDIR/socket
	if [ -d "$INSTALLDIR/mime" ]; then
		sudo rm -rf $INSTALLDIR/mime
	fi
	mkdir $INSTALLDIR/mime
	cp luasocket-$LUASOCKETSHA/src/*.so $INSTALLDIR/.
	cp luasocket-$LUASOCKETSHA/src/*.lua $INSTALLDIR/socket/.
	mv $INSTALLDIR/socket*.so $INSTALLDIR/socket/core.so
	mv $INSTALLDIR/mime*.so $INSTALLDIR/mime/core.so
	mv $INSTALLDIR/socket/socket.lua $INSTALLDIR/.
	mv $INSTALLDIR/socket/mime.lua $INSTALLDIR/.
	mv $INSTALLDIR/socket/ltn12.lua $INSTALLDIR/.
	rm -rf luasocket-$LUASOCKETSHA
	rm -f *.tar.gz

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Building Luasocket------------------->"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$ILFS" == "YES" ]
then
	# Download and build luafilesystem
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build Luafilesystem------------------------>"
	echo "                                                             "
	echo "#############################################################"
	wget https://github.com/keplerproject/luafilesystem/archive/v$LFSVER.tar.gz
	tar zxf v$LFSVER.tar.gz
	cd luafilesystem-$LFSVER
	gcc -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic $GCCLUAINC   -c -o src/lfs.o src/lfs.c
	gcc -shared  -o src/lfs.so src/lfs.o
	cd ..

	# Transfer files to certRenew
	cp luafilesystem-$LFSVER/src/lfs.so $INSTALLDIR/.
	rm -rf luafilesystem-$LFSVER
	rm -f *.tar.gz

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Building Luafilesystem--------------->"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$ILUA_AWS" == "YES" ]
then
	# Download and setup lua-aws
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Setup lua-aws------------------------------>"
	echo "                                                             "
	echo "#############################################################"
	#wget https://github.com/umegaya/lua-aws/archive/$LUA_AWSSHA.tar.gz
	wget https://github.com/aryajur/lua-aws/archive/$LUA_AWSSHA.tar.gz
	tar zxf $LUA_AWSSHA.tar.gz
	cd lua-aws-$LUA_AWSSHA

	# Transfer files to certRenew
	mv lua-aws $INSTALLDIR/.
	cd ..
	# Also get the bit compatibility library
	cd $INSTALLDIR
	wget https://raw.githubusercontent.com/aryajur/bit/master/src/bit.lua
	mkdir bit
	cd bit
	wget https://raw.githubusercontent.com/aryajur/bit/master/src/bit53.lua
	cd ..
	rm -rf lua-aws-$LUA_AWSSHA
	rm -f *.tar.gz

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Setup lua-aws------------------------>"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$ILUASQL" == "YES" ]
then
	# Download and build luasocket
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build LuaSQL------------------------------->"
	echo "                                                             "
	echo "#############################################################"
	wget https://github.com/keplerproject/luasql/archive/$LUASQLSHA.tar.gz
	tar zxf $LUASQLSHA.tar.gz
	cd luasql-$LUASQLSHA
	make LUA_LIBDIR=$INSTALLDIR LUA_DIR=$INSTALLDIR LUA_INC=$INSTALLDIR/inc mysql

	if [ -d "$INSTALLDIR/luasql" ]; then
		sudo rm -rf $INSTALLDIR/luasql
	fi
	mkdir $INSTALLDIR/luasql
	cp src/*.so $INSTALLDIR/luasql/.
	cd ..
	rm -rf luasql-$LUASQLSHA
	rm -f *.tar.gz

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Setup LuaSQL------------------------->"
	echo "                                                             "
	echo "#############################################################"
fi
	
if [ "$ILUASEC" == "YES" ]
then
	# Download and build luasocket
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build OpenSSL------------------------------>"
	echo "                                                             "
	echo "#############################################################"
	wget http://www.openssl.org/source/$OPENSSL.tar.gz
	tar zxf $OPENSSL.tar.gz
	cd $OPENSSL
	mkdir $INSTALLDIR/openssl
	./config --prefix=$INSTALLDIR/openssl --openssldir=$INSTALLDIR/openssl shared
	#./config shared
	make
	#make install#	cp *.so $INSTALLDIR/.
	#cp *.so.1.1 $INSTALLDIR/.
	cd ..

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Setup OpenSSL------------------------>"
	echo "                                                             "
	echo "#############################################################"
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build LuaSec------------------------------->"
	echo "                                                             "
	echo "#############################################################"

	wget https://github.com/brunoos/luasec/archive/$LUASECSHA.tar.gz
	tar zxf $LUASECSHA.tar.gz
	cd luasec-$LUASECSHA
	#make linux INC_PATH="-I$INSTALLDIR/inc -I$INSTALLDIR/openssl/inc" LIB_PATH="-L$INSTALLDIR -L$INSTALLDIR/openssl/lib" LUAPATH=$INSTALLDIR LUACPATH=$INSTALLDIR
	# Patch the Luasec Makefile to add rpath . (Did not need to do it on some systems)
	# $INSTALLDIR/lua $CURPATH/updateLuaSecMakeFile.lua $INSTALLDIR/luasec-$LUASECSHA/src/Makefile	
	make linux INC_PATH=-I$INSTALLDIR/inc LIB_PATH=-L$INSTALLDIR LUAPATH=$INSTALLDIR LUACPATH=$INSTALLDIR
	cp src/*.so $INSTALLDIR/.
	cp src/ssl.lua $INSTALLDIR/.
	if [ ! -d "$INSTALLDIR/ssl" ]; then
		mkdir $INSTALLDIR/ssl
	else
		rm -rf $INSTALLDIR/ssl/*
	fi
	cp src/https.lua $INSTALLDIR/ssl/.
	cd ..
	rm -rf luasec-$LUASECSHA
	rm -f *.tar.gz
	
	rm -rf $OPENSSL
	rm -f *.tar.gz

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Setup LuaSec------------------------->"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$ILPTY" == "YES" ]
then
	# Download and build luasocket
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build lpty--------------------------------->"
	echo "                                                             "
	echo "#############################################################"
	cd $INSTALLDIR
	cp $CURPATH/../Software/$LPTY.tar.gz $INSTALLDIR/.
	tar zxf $LPTY.tar.gz
	cd $LPTY
	$INSTALLDIR/lua mkinc.lua expectsrc
	gcc -fPIC -Wall -I$INSTALLDIR/inc -c lpty.c -o lpty.o
	gcc -shared -o lpty.so -L$INSTALLDIR lpty.o
	cp lpty.so $INSTALLDIR/.
	cd ..
	rm -rf $LPTY
	rm -f *.tar.gz

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Setup lpty------------------------->"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$ISRLUA" == "YES" ]
then
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build SRLua-------------------------------->"
	echo "                                                             "
	echo "#############################################################"
	cd $CURPATH/srlua
	make LUA_TOPDIR=$INSTALLDIR/ LUA_INCDIR=$INSTALLDIR/inc/ LUA_LIBDIR=$INSTALLDIR/
	# Convert KogenceIfaceApp to executable
	./srglue srlua ../KogenceIfaceApp.lua $INSTALLDIR/KogenceIfaceApp; chmod +x $INSTALLDIR/KogenceIfaceApp


	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished building SRLua----------------------->"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$ITABLEUTILS" == "YES" ]
then
	# Also get the tableUtils library
	echo "#############################################################"
	echo "                                                             "
	echo "### Download TableUtils------------------------------------->"
	echo "                                                             "
	echo "#############################################################"
	cd $INSTALLDIR
	wget https://raw.githubusercontent.com/aryajur/tableUtils/master/src/tableUtils.lua
	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished downloading TableUtils--------------->"
	echo "                                                             "
	echo "#############################################################"
fi

echo "DONE"
echo "INSTALLATION DONE!"

