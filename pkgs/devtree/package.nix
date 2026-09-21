{
  lib,
  python3,
  python3Packages,
  bats,
  jq,
  makeWrapper,
}:

# Ships the devtree Python script; its only runtime dependency is Python itself.
python3Packages.buildPythonApplication {
  pname = "devtree";
  version = "0.1.0";

  # No pyproject.toml: a single script, installed by hand in installPhase.
  format = "other";

  src = ./.;

  # Nothing to compile; installPhase does all the work.
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 devtree $out/bin/devtree
    runHook postInstall
  '';

  nativeCheckInputs = [
    bats
    jq
    python3
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  # jq is optional at runtime — the script falls back to plain JSON without it —
  # but putting it on PATH is what gives terminal users jq's colored output.
  postFixup = ''
    wrapProgram $out/bin/devtree --prefix PATH : ${lib.makeBinPath [ jq ]}
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck
    # Keep HOME inside the writable build tmpdir, away from the real home.
    HOME=$TMPDIR bats devtree.bats
    runHook postCheck
  '';

  meta = {
    description = "Devtree CLI: resolve and inspect the enclosing devtree root";
    mainProgram = "devtree";
    platforms = lib.platforms.unix;
  };
}
