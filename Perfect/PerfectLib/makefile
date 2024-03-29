# Makefile for server-side PerfectLib

OS = $(shell uname)
SWIFTC = swift
MODULE_NAME = PerfectLib
DEBUG = -g -Onone -Xcc -DDEBUG=1
Linux_INSTALL_PATH = /usr/local/lib
Darwin_INSTALL_PATH = /Library/Frameworks

INSTALL_PATH = $($(OS)_INSTALL_PATH)

Darwin_SWIFTC_FLAGS = -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk
Linux_SWIFTC_FLAGS = -I linked/LinuxBridge

SWIFTC_FLAGS = $(DEBUG) -emit-module -I linked/LibEvent -I linked/OpenSSL_Linux -I linked/ICU -I linked/SQLite3 \
	-module-cache-path $(MODULE_CACHE_PATH) -module-name $(MODULE_NAME) $($(OS)_SWIFTC_FLAGS)

PERFECT_SRC = ICU.swift NetNamedPipe.swift File.swift Threading.swift LibEvent.swift Bytes.swift FastCGI.swift \
	LogManager.swift NetTCPSSL.swift PerfectServer.swift WebConnection.swift Closeable.swift \
	FastCGIServer.swift Net.swift Utilities.swift MimeReader.swift NetTCP.swift SessionManager.swift \
	WebRequest.swift HTTPServer.swift MimeType.swift PageHandler.swift SQLite.swift WebResponse.swift \
	Dir.swift Mustache.swift PerfectError.swift SysProcess.swift DynamicLoader.swift JSON.swift Utilities-Server.swift \
	Routing.swift StaticFileHandler.swift WebSocketHandler.swift

PERFECT_OBJ = $(addsuffix .o, $(basename $(PERFECT_SRC))) LinuxBridge.o util.o

PERFECT_MODULES = $(addprefix ./tmp/, $(addsuffix .swiftmodule, $(basename $(PERFECT_SRC))))

Darwin_SHLIB_PATH = -L./linked/ICU/osx -L./linked/LibEvent/osx -L./linked/OpenSSL/osx -L./linked/SQLite3/osx
Linux_SHLIB_PATH = -L$(shell dirname $(shell dirname $(shell which swiftc)))/lib/swift/linux
SHLIB_PATH = $($(OS)_SHLIB_PATH)

Darwin_LFLAGS = $(SHLIB_PATH) -arch x86_64 -dynamiclib \
	-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk \
	-install_name @rpath/PerfectLib.framework/Versions/A/PerfectLib -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
	-Xlinker -rpath -Xlinker @loader_path/Frameworks -stdlib=libc++ \
	-L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx \
	-Xlinker -add_ast_path -Xlinker PerfectLib.swiftmodule -single_module

Linux_LFLAGS = $(SHLIB_PATH) -lFoundation -lswiftCore -lswiftGlibc -ldl -lm -shared

LFLAGS = $($(OS)_LFLAGS) -levent -levent_pthreads -lssl -lcrypto -lsqlite3 -licudata -licui18n -licuuc -lpthread
CFLAGS = -fPIC
MODULE_CACHE_PATH = /tmp/modulecache

all: perfectlib

install:
	ln -sf `pwd`/$(MODULE_NAME).so /usr/local/lib/
	ln -sf `pwd`/$(MODULE_NAME).swiftmodule /usr/local/lib/
	ln -sf `pwd`/$(MODULE_NAME).swiftdoc /usr/local/lib/

modulecache:
	@mkdir -p $(MODULE_CACHE_PATH)
	@mkdir -p tmp

perfectlib: modulecache $(MODULE_NAME).so


$(MODULE_NAME).so: $(PERFECT_OBJ) $(MODULE_NAME).swiftmodule LinuxBridge.o util.o
	clang++ $(PERFECT_OBJ) $(LFLAGS) -o $(MODULE_NAME).so

$(MODULE_NAME).swiftmodule:
	$(SWIFTC) -frontend $(SWIFTC_FLAGS) $(PERFECT_MODULES) -parse-as-library -emit-module-doc-path $(MODULE_NAME).swiftdoc -o $(MODULE_NAME).swiftmodule

clean:
	@rm -f *.o *.so *.swiftmodule *.swiftdoc *.d *.swiftdeps ./tmp/*

%.o : %.swift
	$(SWIFTC) -frontend -c $(subst $<,,$(PERFECT_SRC)) -primary-file $< \
		-emit-module-path ./tmp/$(subst .o,.swiftmodule,$@) \
		-emit-module-doc-path ./tmp/$(subst .o,.swiftdoc,$@) \
		-emit-dependencies-path ./tmp/$(subst .swift,.d,$<) \
		-emit-reference-dependencies-path ./tmp/$(subst .swift,.swiftdeps,$<) \
		$(SWIFTC_FLAGS) $(SWIFTC_FLAGS) \
		-o $@
