class Jank < Formula
  desc "The native Clojure dialect hosted on LLVM"
  homepage "https://jank-lang.org"
  url "https://github.com/jank-lang/jank.git", branch: "system-boehm"
  version "0.1"
  license "MPL-2.0"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "llvm@19"
  depends_on "bdw-gc"
  depends_on "boost"
  depends_on "libzip"
  depends_on "openssl"

  def install
    if OS.mac?
      ENV["SDKROOT"] = MacOS.sdk_path
      ENV.prepend_path "PATH", Formula['llvm@19'].opt_bin
      ENV.append "LDFLAGS", "-Wl,-rpath,#{Formula['llvm@19'].opt_lib}"

      ENV.append "CPPFLAGS", "-L#{Formula['llvm@19'].opt_include}"
      ENV.append "CPPFLAGS", "-fno-sized-deallocation"

      jank_install_dir = OS.linux? ? libexec : bin
      inreplace "compiler+runtime/cmake/install.cmake",
                '\\$ORIGIN',
                jank_install_dir
    end

    cd "compiler+runtime"

    system "./bin/configure",
           "-GNinja",
           *std_cmake_args
    system "./bin/compile"
    system "./bin/install"
  end

  test do
    jank = bin/"jank"

    (testpath/"test.jank").write <<~JANK
        (+ 5 7)
    JANK

    assert_equal "12", shell_output("#{jank} run test.jank").strip.lines.last

    assert_predicate jank, :exist?, "jank must exist"
    assert_predicate jank, :executable?, "jank must be executable"
  end
end
