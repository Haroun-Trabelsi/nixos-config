{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  installShellFiles,
  ...
}:

let
  version = "0.39.0";

  # Upstream ships prebuilt release tarballs. Building from source would need
  # Go 1.26+ with CGO (DuckDB driver) plus a Node 22 / Vite frontend build, so
  # we consume the release artifact and patch its interpreter instead.
  sources = {
    x86_64-linux = {
      arch = "linux_amd64";
      hash = "sha256-xx5O0DCtumzEGOCZMo4/RKQjK8zHMXzMNAgYJUImI4c=";
    };
    aarch64-linux = {
      arch = "linux_arm64";
      hash = "sha256-fgMUbq/ciXMt3KhgnG7xu07BRmcBZSqOrUnCWUL3c1U=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "agentsview: unsupported platform ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "agentsview";
  inherit version;

  src = fetchurl {
    url = "https://github.com/kenn-io/agentsview/releases/download/v${version}/agentsview_${version}_${source.arch}.tar.gz";
    inherit (source) hash;
  };

  # The tarball is a single bare `agentsview` binary with no top-level directory.
  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    installShellFiles
  ];

  # CGO build: needs libstdc++ / libgcc_s for the bundled DuckDB driver.
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 agentsview "$out/bin/agentsview"
    runHook postInstall
  '';

  # Generate completions from the patched binary once it can actually run.
  postInstall = ''
    if "$out/bin/agentsview" completion bash > /dev/null 2>&1; then
      installShellCompletion --cmd agentsview \
        --bash <("$out/bin/agentsview" completion bash) \
        --zsh  <("$out/bin/agentsview" completion zsh) \
        --fish <("$out/bin/agentsview" completion fish)
    fi
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/agentsview" --version
    runHook postInstallCheck
  '';

  meta = {
    description = "Local-first session search, analytics, and token usage statistics for coding agents";
    longDescription = ''
      AgentsView indexes local coding-agent sessions (Claude Code, Codex, and
      20+ others) into a SQLite database with FTS5 search, and serves a local
      web UI plus CLI reports for cost and token usage.
    '';
    homepage = "https://github.com/kenn-io/agentsview";
    changelog = "https://github.com/kenn-io/agentsview/releases/tag/v${version}";
    license = lib.licenses.mit;
    platforms = lib.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "agentsview";
  };
}
