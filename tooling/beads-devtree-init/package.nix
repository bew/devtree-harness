{
  lib,
  python3,
  python3Packages,
  bats,
  expect,
  git,
  beads,
}:

# Ships the Python script and pins its runtime tools (git, bd) on PATH.
python3Packages.buildPythonApplication {
  pname = "beads-devtree-init";
  version = "0.1.0";

  # No pyproject.toml: a single script, installed by hand in installPhase.
  format = "other";

  src = ./.;

  # Nothing to compile; installPhase does all the work.
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 beads-devtree-init $out/bin/beads-devtree-init
    mkdir -p $out/share/beads-devtree-init
    cp -R skills $out/share/beads-devtree-init/skills
    runHook postInstall
  '';

  makeWrapperArgs = [
    "--set BEADS_DEVTREE_INIT_SKILLS $out/share/beads-devtree-init/skills"
    "--prefix PATH : ${lib.makeBinPath [ git beads ]}"
  ];

  nativeCheckInputs = [
    bats
    expect
    git
    beads
    python3
  ];

  doCheck = true;

  checkPhase = ''
    runHook preCheck
    # HOME must be writable for bd's local store and git's config lookups.
    HOME=$TMPDIR bats beads-devtree-init.bats
    runHook postCheck
  '';

  meta = {
    description = "Initialize beads (`bd init`) in a devtree project with harness-safe defaults";
    mainProgram = "beads-devtree-init";
    platforms = lib.platforms.unix;
  };
}
