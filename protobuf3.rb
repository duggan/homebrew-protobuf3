require "formula"
require "language/go"

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

class Protobuf3 < Formula
  homepage 'https://developers.google.com/protocol-buffers/'

  head do 
    url 'https://github.com/google/protobuf.git'
    depends_on "libtool"
    depends_on "autoconf"
    depends_on "automake"
  end

  keg_only 'Conflicts with protobuf in main repository.'

  option :universal
  option :cxx11

  option "with-python", "Build with Python support."
  option "with-go", "Build with Go support."

  depends_on :python => :optional
  depends_on OldOrNoDateutilUnlessGoogleApputils if build.with? "python"

  if build.with? "go"
    depends_on "go" => :build
    go_resource "github.com/golang/protobuf" do
      url "https://github.com/golang/protobuf.git", :revision => "c22ae3cf020a21ebb7ae566dccbe90fc8ea4f9ea"
    end
  end

  fails_with :llvm do
    build 2334
  end

  def install
    # Don't build in debug mode. See:
    # https://github.com/mxcl/homebrew/issues/9279
    # http://code.google.com/p/protobuf/source/browse/trunk/configure.ac#61
    ENV.prepend 'CXXFLAGS', '-DNDEBUG'
    ENV.universal_binary if build.universal?
    system "./autogen.sh"
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-zlib"
    system "make"
    system "make install"

    if build.with? "go"
      ENV["GOPATH"] = buildpath
      host = "github.com"
      org_name = "golang"
      repo_name = "protobuf"

      gopath = "src/#{host}/#{org_name}/#{repo_name}"

      mkdir_p buildpath/"#{gopath}"
      ln_s buildpath, buildpath/"#{gopath}"

      Language::Go.stage_deps resources, buildpath/"src/"

      bin_name = "protoc-gen-go"
      cd "src/#{host}/#{org_name}/#{repo_name}/#{bin_name}" do
        system "go", "build", "-o", bin_name
        bin.install bin_name
      end
    end

    # Install editor support and examples
    doc.install %w( editors examples )
 
    if build.with? "python"
      chdir "python" do
        ENV.append_to_cflags "-I#{include}"
        ENV.append_to_cflags "-L#{lib}"
        system "python", "setup.py", "build"
        system "python", "setup.py", "install", "--cpp_implementation", "--prefix=#{prefix}",
               "--single-version-externally-managed", "--record=installed.txt"
      end
    end
  end

  def caveats; <<-EOS.undent
    Editor support and examples have been installed to:
      #{doc}/protobuf
    EOS
  end
end
