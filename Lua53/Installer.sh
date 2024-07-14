#!/bin/bash
# Script to install the certificate renewal package
# Run the script with the command: (The . first helps set environment variables in the caller environment see https://stackoverflow.com/questions/496702/can-a-shell-script-set-environment-variables-of-the-calling-shell)
# > . ./Installer.sh

######################## CONFIGURATION SETTINGS ####################


# Setup Flags
ILUA="YES"
ILUASHARED="NO"	
ILUASOCKET="YES"
ILFS="YES"
ILUA_AWS="NO"
ILUASQL="YES"
ILUASEC="YES"
ILUAOSSL="YES"
ILPTY="YES"
ISRLUA="NO"		
ITABLEUTILS="YES"
IPGMOON="YES"
ILPEG="YES"	 # this is a dependency for pgmoon

INSTALLDIR="/opt/software/LuaScripts"

LUAV="5.3.6"
LUA="5.3"
LUASOCKETSHA="5b18e475f38fcf28429b1cc4b17baee3b9793a62"
CURPATH=$(pwd)
LFSVER="1_7_0_2"
GCCLUAINC="-I$INSTALLDIR/inc"
#echo $GCCLUAINC
LUA_AWSSHA="a14d26ff35b3fad2b45ae07c242a2cf781ec90ae"	# From aryajur pull request
LUASQLSHA="5e65ae41f87f545070f378e4882fa1ef87287fa5"
OPENSSL="openssl-3.3.1"
LUASECSHA="22eadbd20e1e9a53b0f55b38c731e04e935a9595"
LPTY="lpty-1.2.2-1"
LUAOSSL="rel-20220711"
LPEG="lpeg-1.1.0"
SRLUA="srlua-102"

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
	mkdir $INSTALLDIR/lib
	cp lua-$LUAV/src/lauxlib.h $INSTALLDIR/inc/.
	cp lua-$LUAV/src/lua.h $INSTALLDIR/inc/.
	cp lua-$LUAV/src/luaconf.h $INSTALLDIR/inc/.
	cp lua-$LUAV/src/lualib.h $INSTALLDIR/inc/.
	cp lua-$LUAV/src/liblua.a $INSTALLDIR/lib/.
	rm -rf lua-$LUAV
	rm -f *.tar.gz
	
	echo "io.write('Adding module paths...') package.path = package.path..';/home/ubuntu/Lua/?.lua' package.cpath = package.cpath..';/home/ubuntu/Lua/?.so' print('DONE')" > $INSTALLDIR/initpaths.lua
	
	export LUA_INIT="@$INSTALLDIR/initpaths.lua"

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
	make linux LUAV=$LUA LUAINC_linux_base=$INSTALLDIR LUAINC_linux=$INSTALLDIR/inc LUAPREFIX_linux=$INSTALLDIR CDIR_linux=$INSTALLDIR LDIR_linux=$INSTALLDIR
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
	
if [ "$ILUASEC" == "YES" ] || ["$ILUAOSSL" == "YES" ];
then
	# Download and build luasocket
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build OpenSSL------------------------------>"
	echo "                                                             "
	echo "#############################################################"
	cd $INSTALLDIR
	wget http://www.openssl.org/source/$OPENSSL.tar.gz
	tar zxf $OPENSSL.tar.gz
	cd $OPENSSL
	#mkdir $INSTALLDIR/openssl
	./config #--prefix=$INSTALLDIR/openssl --openssldir=$INSTALLDIR/openssl shared
	#./config shared
	make
	#make install#	cp *.so $INSTALLDIR/.
	cp *.so* $INSTALLDIR/.
	cd ..

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Setup OpenSSL------------------------>"
	echo "                                                             "
	echo "#############################################################"
	
	if [ "$ILUAOSSL" == "YES" ]
	then
		echo "#############################################################"
		echo "                                                             "
		echo "### Download and Build LuaOSSL------------------------------>"
		echo "                                                             "
		echo "#############################################################"
		wget https://github.com/wahern/luaossl/archive/refs/tags/$LUAOSSL.tar.gz
		tar zxf $LUAOSSL.tar.gz
		cd luaossl-$LUAOSSL
		
		make all$LUA ALL_CFLAGS="-Wall -fPIC -I$INSTALLDIR/inc -I$INSTALLDIR/$OPENSSL/include" ALL_SOFLAGS="-Wall -shared -L$INSTALLDIR/$OPENSSL -L$INSTALLDIR"
		mkdir $INSTALLDIR/openssl
		mkdir $INSTALLDIR/openssl/x509
		mkdir $INSTALLDIR/openssl/ssl
		mkdir $INSTALLDIR/openssl/ocsp
		cp src/$LUA/openssl.so $INSTALLDIR/_openssl.so
		cp src/openssl.x509.lua $INSTALLDIR/openssl/x509.lua
		cp src/openssl.rand.lua $INSTALLDIR/openssl/rand.lua
		cp src/openssl.ssl.lua $INSTALLDIR/openssl/ssl.lua
		cp src/openssl.pkcs12.lua $INSTALLDIR/openssl/pkcs12.lua
		cp src/openssl.pkey.lua $INSTALLDIR/openssl/pkey.lua
		cp src/openssl.pubkey.lua $INSTALLDIR/openssl/pubkey.lua
		cp src/openssl.kdf.lua $INSTALLDIR/openssl/kdf.lua
		cp src/openssl.des.lua $INSTALLDIR/openssl/des.lua
		cp src/openssl.digest.lua $INSTALLDIR/openssl/digest.lua
		cp src/openssl.hmac.lua $INSTALLDIR/openssl/hmac.lua
		cp src/openssl.auxlib.lua $INSTALLDIR/openssl/auxlib.lua
		cp src/openssl.bignum.lua $INSTALLDIR/openssl/bignum.lua
		cp src/openssl.cipher.lua $INSTALLDIR/openssl/cipher.lua
		cp src/openssl.x509.verify_param.lua $INSTALLDIR/openssl/x509/verify_param.lua
		cp src/openssl.x509.name.lua $INSTALLDIR/openssl/x509/name.lua
		cp src/openssl.x509.store.lua $INSTALLDIR/openssl/x509/store.lua
		cp src/openssl.x509.crl.lua $INSTALLDIR/openssl/x509/crl.lua
		cp src/openssl.x509.csr.lua $INSTALLDIR/openssl/x509/csr.lua
		cp src/openssl.x509.extension.lua $INSTALLDIR/openssl/x509/extension.lua
		cp src/openssl.x509.altname.lua $INSTALLDIR/openssl/x509/altname.lua
		cp src/openssl.x509.chain.lua $INSTALLDIR/openssl/x509/chain.lua
		cp src/openssl.ssl.context.lua $INSTALLDIR/openssl/ssl/context.lua
		cp src/openssl.ocsp.basic.lua $INSTALLDIR/openssl/ocsp/basic.lua
		cp src/openssl.ocsp.response.lua $INSTALLDIR/openssl/ocsp/response.lua
		
		cd ..
		rm -rf luaossl-$LUAOSSL
		rm -f *.tar.gz

		echo "#############################################################"
		echo "                                                             "
		echo "<-------------Finished Setup LuaOSSL------------------------>"
		echo "                                                             "
		echo "#############################################################"
	fi
	
	if [ "$ILUASEC" == "YES" ]
	then
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
		$INSTALLDIR/lua $CURPATH/updateLuaSecMakeFile.lua $INSTALLDIR/luasec-$LUASECSHA/src/Makefile	
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
		echo "#############################################################"
		echo "                                                             "
		echo "<-------------Finished Setup LuaSec------------------------->"
		echo "                                                             "
		echo "#############################################################"
	fi
	
	rm -rf $OPENSSL
	rm -f *.tar.gz

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
	wget https://codeberg.org/gnarz/lpty/archive/master.tar.gz
	tar zxf master.tar.gz
	cd lpty/src
	$INSTALLDIR/lua mkinc.lua expectsrc
	gcc -fPIC -Wall -I$INSTALLDIR/inc -c lpty.c -o lpty.o
	gcc -shared -o lpty.so -L$INSTALLDIR lpty.o
	cp lpty.so $INSTALLDIR/.
	cd ../..
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
	cd $INSTALLDIR
	wget https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/$SRLUA.tar.gz
	tar zxf $SRLUA.tar.gz
	cd $SRLUA
	make bin LUA_TOPDIR=$INSTALLDIR/ LUA_INCDIR=$INSTALLDIR/inc LUA_LIBDIR=$INSTALLDIR/lib
	
	cd ..
	cp $SRLUA/srlua $INSTALLDIR/.
	cp $SRLUA/srglue $INSTALLDIR/.
	rm -rf $SRLUA
	rm -f *.tar.gz

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

if [ "$IERRORH" == "YES" ]
then
	# Also get the errorH module
	echo "#############################################################"
	echo "                                                             "
	echo "### Download ErrorH----------------------------------------->"
	echo "                                                             "
	echo "#############################################################"
	cd $INSTALLDIR
	wget https://raw.githubusercontent.com/aryajur/errorH/master/src/errorH.lua
	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished downloading ErrorH------------------->"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$IPGMOON" == "YES" ]
then
	# Download and build pgmoon
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and install pgmoon----------------------------->"
	echo "                                                             "
	echo "#############################################################"
	cd $INSTALLDIR
	wget https://github.com/leafo/pgmoon/archive/master.tar.gz
	tar zxf master.tar.gz
	cd pgmoon-master


	# Transfer files to Lua directory
	cp -r pgmoon $INSTALLDIR/.
	cd ..
	rm -rf pgmoon-master
	rm -f *.tar.gz

	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished installing pgmoon-------------------->"
	echo "                                                             "
	echo "#############################################################"
fi

if [ "$ILPEG" == "YES" ]
then
	# Download and build LPEG
	echo "#############################################################"
	echo "                                                             "
	echo "### Download and Build LPEG---------------------------->"
	echo "                                                             "
	echo "#############################################################"
	cd $INSTALLDIR
	wget https://www.inf.puc-rio.br/~roberto/lpeg/$LPEG.tar.gz
	tar zxf $LPEG.tar.gz
	cd $LPEG
	make linux LUADIR=$INSTALLDIR/inc
	cp lpeg.so $INSTALLDIR/.
	cd ..
	rm -rf $LPEG
	rm -f *.tar.gz
	echo "#############################################################"
	echo "                                                             "
	echo "<-------------Finished Building LPEG------------------->"
	echo "                                                             "
	echo "#############################################################"
fi



echo "DONE"
echo "INSTALLATION DONE!"

echo "Make sure LUA_INIT environment variable is set to '@$INSTALLDIR/initpaths.lua'"

