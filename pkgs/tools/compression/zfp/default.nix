{ cmake, cudatoolkit, fixDarwinDylibNames, fetchFromGitHub, gfortran, lib, llvmPackages, pythonPackages, stdenv, enableCuda ? !stdenv.targetPlatform.isDarwin, enableFortran ? true, enableOpenMp ? true, enablePython ? true }:

stdenv.mkDerivation rec {
  name = "zfp";
  version = "0.5.5";

  src = fetchFromGitHub {
    owner = "LLNL";
    repo = "zfp";
    rev = version;
    sha256 = "19ycflz35qsrzfcvxdyy0mgbykfghfi9y5v684jb4awjp7nf562c";
  };

  nativeBuildInputs = [ cmake ]
    ++ lib.optional stdenv.hostPlatform.isDarwin fixDarwinDylibNames
    ++ lib.optional enableFortran gfortran
    ++ lib.optional enableOpenMp llvmPackages.openmp
    ++ lib.optional enablePython pythonPackages.python;

  buildInputs = lib.optional enableCuda cudatoolkit
    ++ lib.optional enablePython [ pythonPackages.cython pythonPackages.numpy ];

  cmakeFlags = [
    ''-DBUILD_CFP=ON''
    ''-DBUILD_UTILITIES=ON''
    ''-DBUILD_EXAMPLES=ON''
    # More tests not enabled by default
    ''-DZFP_BUILD_TESTING_LARGE=ON''
  ]
    ++ lib.optional enableCuda "-DZFP_WITH_CUDA=ON"
    ++ lib.optional enableFortran "-DBUILD_ZFORP=ON"
    ++ lib.optional enableOpenMp "-DZFP_WITH_OPENMP=ON"
    ++ lib.optional enablePython "-DBUILD_ZFPY=ON";

  # makeFlags = lib.optional stdenv.isDarwin "LDFLAGS=-Wl,-install_name,$(out)/lib/libzfp.${version}.dylib";

  preConfigure = ''
    export cmakeFlags="-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$out/bin -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=$out/lib -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=$out/lib $cmakeFlags"
  '';

  preCheck = if stdenv.isDarwin then ''
      fixDarwinDylibNamesIn $prefix
      export DYLD_LIBRARY_PATH=$out/lib:$DYLD_LIBRARY_PATH
  '' else ''export LD_LIBRARY_PATH=$out/lib:$LD_LIBRARY_PATH'';

  doCheck = true;

  meta = with lib; {
    homepage = "https://computing.llnl.gov/projects/zfp";
    description = "Library for random-access compression of floating-point arrays";
    license = licenses.bsd3;
    maintainers = [ maintainers.spease ];
    # 64-bit only
    platforms = [ "x86_64-darwin" "x86_64-linux" ];
  };
}
