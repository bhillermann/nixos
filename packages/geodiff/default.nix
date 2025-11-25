{ lib, inputs, pkgs, stdenv, ... }:

{

  stdenv.mkDerivation rec {
    pname = "geodiff";
    version = "2.0.3";

    src = pkgs.fetchgit {
      url = "https://github.com/MerginMaps/geodiff.git";
      rev = "db6ed20";
      fetchSubmodules = true;
      sha256 = "sha256-hn6mM+KjLKkDTn+ls6GXKP/0lqo2kkuPWGPuzzVO+RI=";
    };

    libgpkg = pkgs.fetchurl {
      url = "https://github.com/benstadin/libgpkg/archive/0822c5cba7e1ac2c2806e445e5f5dd2f0d0a18b4.tar.gz";
      sha256 = "sha256-IDn5KHJMV9fouimDUyNGUGzeSEN+dk76JD+8a6JP0bo=";
    };

    sourceRoot = "${src.name}/geodiff";

    preConfigure = ''
      mkdir -p external
      ${pkgs.gnutar}/bin/tar xfz ${libgpkg} -C external
    '';

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      git
    ];

    buildInputs = with pkgs; [
      sqlite
      gdal
      libspatialite
      zlib
      openssl
      curl
    ];

    cmakeFlags = [ 
      "-DBUILD_TESTS=OFF" 
      "-DWITH_POSTGRESQL=TRUE"
      "-DPEDANTIC=FALSE" 
    ]; 

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 geodiff $out/bin/geodiff
      runHook postInstall
    '';

    patches = [
      (pkgs.writeText "disable-tests.patch" ''
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -12,7 +12,7 @@
 # set path to additional CMake modules
 SET(CMAKE_MODULE_PATH ''${CMAKE_SOURCE_DIR}/cmake ''${CMAKE_MODULE_PATH})

-SET(ENABLE_TESTS TRUE CACHE BOOL "Build tests?")
+SET(ENABLE_TESTS FALSE CACHE BOOL "Build tests?")
 SET(ENABLE_COVERAGE FALSE CACHE BOOL "Enable GCOV code coverage?")
 SET(BUILD_TOOLS TRUE CACHE BOOL "Build tool executables?")
 SET(BUILD_STATIC FALSE CACHE BOOL "Build static libraries?")
@@ -75,7 +75,7 @@
     RESULT_VARIABLE rv)
 ENDIF()

-SET(libgpkg_dir ''${CMAKE_BINARY_DIR}/external/libgpkg-0822c5cba7e1ac2c2806e445e5f5dd2f0d0a18b4)
+SET(libgpkg_dir ''${CMAKE_SOURCE_DIR}/external/libgpkg-0822c5cba7e1ac2c2806e445e5f5dd2f0d0a18b4)
 SET(libgpkg_src
   '$'{libgpkg_dir}/gpkg/binstream.c
   '$'{libgpkg_dir}/gpkg/blobio.c
	    '')
	  ];
  };
}
