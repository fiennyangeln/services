{ releng_pkgs
}: 

let

  inherit (releng_pkgs.lib) mkBackend fromRequirementsFile filterSource;
  inherit (releng_pkgs.pkgs) writeScript;
  inherit (releng_pkgs.pkgs.lib) fileContents;
  inherit (releng_pkgs.tools) pypi2nix;

  python = import ./requirements.nix { inherit (releng_pkgs) pkgs; };
  name = "mozilla-releng-slavehealth";
  dirname = "releng_slavehealth";

  self = mkBackend {
    inherit python name dirname;
    inProduction = false;
    version = fileContents ./../../VERSION;
    src = filterSource ./. { inherit name; };
    buildInputs =
      fromRequirementsFile ./requirements-dev.txt python.packages;
    propagatedBuildInputs =
      [ python.packages."mozilla-cli-common"
        python.packages."mozilla-backend-common"
        python.packages."mysqlclient"
      ];
    #fromRequirementsFile ./requirements.txt python.packages;
    passthru = {
      update = writeScript "update-${name}" ''
        pushd ${self.src_path}
        ${pypi2nix}/bin/pypi2nix -v \
          -V 3.5 \
          -E "postgresql mysql zlib openssl" \
          -r requirements.txt \
          -r requirements-dev.txt
        popd
      '';
    };
  };

in self