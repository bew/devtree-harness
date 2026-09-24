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

  preCheck = ''
    # Patch where the test file finds the binary to test
    substituteInPlace ./devtree.bats \
      --replace-fail 'SCRIPT_PATH="$SCRIPT_DIR/devtree"' SCRIPT_PATH="$out/bin/devtree"
  '';
  checkPhase = ''
    runHook preCheck
    bats devtree.bats
    runHook postCheck
  '';

  meta = {
    description = "Devtree CLI: resolve and inspect the enclosing devtree root";
    mainProgram = "devtree";
    platforms = lib.platforms.unix;
  };
}
