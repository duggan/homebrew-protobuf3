require 'formula'

class Protobuf3python < Formula
  homepage 'https://developers.google.com/protocol-buffers/'
  url 'https://github.com/google/protobuf/releases/download/v3.0.0-alpha-2/protobuf-python-3.0.0-alpha-2.tar.gz'
  sha1 'f1966e9764cea5e31a6865eb41f91ee4be54b87a'

  keg_only 'Conflicts with protobuf in main repository.'

  option :universal

  fails_with :llvm do
    build 2334
  end

  # make it build with clang and libc++
  patch :DATA

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
  end

  def caveats; <<-EOS.undent
    Editor support and examples have been installed to:
      #{doc}/protobuf
    EOS
  end
end
