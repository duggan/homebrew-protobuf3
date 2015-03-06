require 'formula'

class OldOrNoDateutilUnlessGoogleApputils < Requirement
  # https://github.com/Homebrew/homebrew/issues/32571
  # https://code.google.com/p/google-apputils-python/issues/detail?id=6
  fatal true

  satisfy(:build_env => false) {
    if can_import("dateutil") && !can_import("google.apputils")
      dateutil_version < Version.new("2.0")
    else
      true
    end
  }

  def message; <<-EOS.undent
    The protobuf Python bindings depend on the google-apputils Python library,
    which requires a version of python-dateutil less than 2.0.

    You have python-dateutil version #{dateutil_version} installed in:
      #{Pathname.new(`python -c "import dateutil; print(dateutil.__file__)"`.chomp).dirname}

    Please run:
      pip uninstall python-dateutil && pip install "python-dateutil<2"
    EOS
  end

  def can_import pymodule
    quiet_system "python", "-c", "import #{pymodule}"
  end

  def dateutil_version
    Version.new(`python -c "import dateutil; print(dateutil.__version__)"`.chomp)
  end
end

class Protobuf3python < Formula
  homepage 'https://developers.google.com/protocol-buffers/'
  url 'https://github.com/google/protobuf/releases/download/v3.0.0-alpha-2/protobuf-python-3.0.0-alpha-2.tar.gz'
  sha1 'f1966e9764cea5e31a6865eb41f91ee4be54b87a'

  keg_only 'Conflicts with protobuf in main repository.'

  option :universal

  depends_on OldOrNoDateutilUnlessGoogleApputils

  fails_with :llvm do
    build 2334
  end

  def install
    # Don't build in debug mode. See:
    # https://github.com/mxcl/homebrew/issues/9279
    # http://code.google.com/p/protobuf/source/browse/trunk/configure.ac#61
    ENV.prepend 'CXXFLAGS', '-DNDEBUG'
    ENV.universal_binary if build.universal?
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-zlib"
    system "make"
    system "make install"

    # Install editor support and examples
    doc.install %w( editors examples )
  
    chdir "python" do
      ENV.append_to_cflags "-I#{include}"
      ENV.append_to_cflags "-L#{lib}"
      system "python", "setup.py", "build"
      system "python", "setup.py", "install", "--cpp_implementation", "--prefix=#{prefix}",
             "--single-version-externally-managed", "--record=installed.txt"
    end
  end

  def caveats; <<-EOS.undent
    Editor support and examples have been installed to:
      #{doc}/protobuf
    EOS
  end
end
