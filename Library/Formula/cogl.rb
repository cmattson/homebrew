class Cogl < Formula
  homepage "https://developer.gnome.org/cogl/"
  url "http://ftp.gnome.org/pub/gnome/sources/cogl/1.20/cogl-1.20.0.tar.xz"
  sha256 "729e35495829e7d31fafa3358e47b743ba21a2b08ff9b6cd28fb74c0de91192b"

  bottle do
    revision 1
    sha1 "f86c435b6472355f9db615cfc7ea94d76452d8f6" => :yosemite
    sha1 "113da66275bfe4c1af107b9cfa65619e20af5441" => :mavericks
    sha1 "2740ac7cb7da32ae2e44d055918352d5d947aa1e" => :mountain_lion
  end

  head do
    url "https://git.gnome.org/browse/cogl", :using => :git
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "cairo"
  depends_on "glib"
  depends_on "gobject-introspection"
  depends_on "gtk-doc"
  depends_on "pango"

  depends_on :x11 => ["2.5.1", :recommended]
  deprecated_option "without-x" => "without-x11"

  # Lion's grep fails, which later results in compilation failures:
  # libtool: link: /usr/bin/grep -E -e [really long regexp] ".libs/libcogl.exp" > ".libs/libcogl.expT"
  # grep: Regular expression too big
  if MacOS.version == :lion
    resource "grep" do
      url "http://ftpmirror.gnu.org/grep/grep-2.20.tar.xz"
      mirror "https://ftp.gnu.org/gnu/grep/grep-2.20.tar.xz"
      sha256 "f0af452bc0d09464b6d089b6d56a0a3c16672e9ed9118fbe37b0b6aeaf069a65"
    end
  end

  def install
    # Don't dump files in $HOME.
    ENV["GI_SCANNER_DISABLE_CACHE"] = "yes"

    if MacOS.version == :lion
      resource("grep").stage do
        system "./configure", "--disable-dependency-tracking",
               "--disable-nls",
               "--prefix=#{buildpath}/grep"
        system "make", "install"
        ENV["GREP"] = "#{buildpath}/grep/bin/grep"
      end
    end

    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --enable-cogl-pango=yes
      --enable-introspection=yes
      --disable-glx
    ]
    args << "--without-x" if build.without? "x11"

    if build.head?
      system "./autogen.sh", *args
    else
      system "./configure", *args
    end
    system "make", "install"
    doc.install "examples"
  end
  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <cogl/cogl.h>

      int main()
      {
          return 0;
      }
    EOS
    system ENV.cc, "-I#{include}/cogl",
           "-I#{Formula["glib"].opt_include}/glib-2.0",
           "-I#{Formula["glib"].opt_lib}/glib-2.0/include",
           testpath/"test.c", "-o", testpath/"test"
    system "./test"
  end
end
