with import <nixpkgs> {};
let 
  buildout = pythonPackages.zc_buildout_nix.overrideDerivation(args: {
    postInstall = "";
    propagatedNativeBuildInputs = [
        pythonPackages.pillow
        pythonPackages.lxml
        pythonPackages.python_magic
    ];
  });
in stdenv.mkDerivation rec {
  name = "env";
  env = buildEnv { name = name; paths = buildInputs; };
  buildInputs = [
    #gitAndTools.pre-commit
    zsh
    #docker-compose
    python27
    python27Packages.virtualenv
    python27Packages.recursivePthLoader
    python27Packages.pip
    libxml2
    libxslt
    python27Packages.pillow
    python27Packages.isort
    python27Packages.flake8
    zlib
    graphicsmagick
    buildout
    httpie
  ];
}
