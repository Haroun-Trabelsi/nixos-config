{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Hindsight (Claude Code's long-term memory) runs on the Coder workspace:
  # the hindsight-coding-agents plugin there starts a hindsight-embed daemon on
  # 127.0.0.1:9077 and every Claude session reads/writes it. The workspace is
  # the one place every device reaches, so that is where memory lives.
  #
  # This unit only projects it outward, into two separate git repos so work
  # and personal memory never share an owner:
  #
  #   journeyai (every JourneyAI-Team repo, routed there by mapPathToBank and
  #   banks.* in the workspace's ~/.hindsight/coding-agent.json)
  #       -> work account,     ~/Documents/journeyai-memory
  #   every other bank
  #       -> personal account, ~/Documents/hindsight-memory
  #
  # Each gets the bank's knowledge pages as markdown (for Obsidian — a
  # projection: edits there do NOT flow back into Hindsight) and, daily, a
  # full transfer ZIP under .backups/, which
  # `POST /v1/default/banks/{id}/transfer/import` restores on a fresh
  # workspace.
  #
  # Runs from here rather than on the workspace because the workspace has no
  # cron, no user systemd and no GitHub credentials; this machine has all
  # three. Work pushes over SSH (~/.ssh/id_github is the work account),
  # personal over HTTPS through gh's credential helper (the personal account).
  workspace = "haroun";
  docs = "${config.home.homeDirectory}/Documents";

  targets = {
    work = {
      vault = "${docs}/journeyai-memory";
      repo = "git@github.com:haroun-mj-ai/journeyai-memory.git";
      email = "haroun@meetjourney.ai";
    };
    personal = {
      vault = "${docs}/hindsight-memory";
      repo = "https://github.com/Haroun-Trabelsi/hindsight-memory.git";
      email = "fantasycrit20@gmail.com";
    };
  };

  # Only the journeyai bank is work. Anything else is personal — which is why
  # the workspace config over-routes (generic names like `frontend` go to
  # journeyai too): a misrouted bank should land on the work side, not leak
  # out of it.
  workBank = "journeyai";

  # Runs on the workspace, fed over `coder ssh ... bash -s`. Only curl and jq,
  # both already there. Writes a tar of <n>.kb.json (+ <n>.zip with BACKUP=1)
  # and a banks.tsv manifest to stdout; exits 75 if the daemon is down, which
  # just means no Claude session has run since the workspace started — so
  # there is nothing new to sync either.
  remote = pkgs.writeText "hindsight-sync-remote.sh" ''
    set -euo pipefail
    base=http://127.0.0.1:9077
    api=$base/v1/default
    curl -sf -o /dev/null "$base/health" || exit 75
    out=$(mktemp -d); trap 'rm -rf "$out"' EXIT
    n=0
    for b in $(curl -sf "$api/banks" | jq -r '.banks[].bank_id'); do
      n=$((n + 1))
      enc=$(jq -rn --arg b "$b" '$b | @uri')
      printf '%s\t%s\n' "$n" "$b" >> "$out/banks.tsv"
      curl -sf "$api/banks/$enc/knowledge-base/export" > "$out/$n.kb.json"
      if [ "''${BACKUP:-0}" = 1 ]; then
        op=$(curl -sf -X POST "$api/banks/$enc/transfer/export?include_data=true&include_bank_config=true" | jq -r .operation_id)
        for _ in $(seq 1 90); do
          s=$(curl -sf "$api/banks/$enc/operations/$op")
          case $(jq -r .status <<< "$s") in
            completed) curl -sf "$base$(jq -r .result_metadata.download_url <<< "$s")" > "$out/$n.zip"; break ;;
            failed) echo "backup of $b failed" >&2; break ;;
          esac
          sleep 2
        done
      fi
    done
    tar -C "$out" -cf - .
  '';

  # Name pages by their frontmatter title instead of kp-<uuid>.md and rewrite
  # the links between them to match, so Obsidian's file tree and graph read as
  # words. One JSON line per file: {name, content}.
  pages = pkgs.writeText "hindsight-pages.jq" ''
    def title: (capture("(?m)^title: \"(?<t>[^\"]*)\"").t // null);
    def safe: gsub("[/\\\\:*?\"<>|#^\\[\\]]"; "-");
    .files as $f
    | ($f | map(select(.path != "index.md")
               | {key: .path, value: (((.content | title) // (.path | rtrimstr(".md"))) | safe) + ".md"})
          | from_entries) as $names
    | $f[]
    | .name = ($names[.path] // .path)
    | .content = (reduce ($names | to_entries[]) as $e (.content;
        gsub("\\./" + ($e.key | gsub("\\."; "\\.")); "./" + ($e.value | gsub(" "; "%20")))))
  '';

  sync = pkgs.writeShellApplication {
    name = "hindsight-sync";
    runtimeInputs = with pkgs; [
      coder
      coreutils
      git
      gnutar
      jq
      openssh
    ];
    text = ''
      backup=0
      [ "''${1:-}" = --backup ] && backup=1

      tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
      set +e
      coder --global-config ${config.xdg.configHome}/coderv2 ssh ${workspace} -- \
        env BACKUP=$backup bash -s < ${remote} > "$tmp/bundle.tar"
      rc=$?
      set -e
      if [ "$rc" = 75 ]; then echo "hindsight daemon not running on ${workspace}; nothing to sync"; exit 0; fi
      [ "$rc" = 0 ] || { echo "remote export failed ($rc)" >&2; exit 1; }
      tar -xf "$tmp/bundle.tar" -C "$tmp"

      # prepare <vault> <repo> <email>: clone on first run, catch up after.
      prepare() {
        [ -d "$1/.git" ] || git clone --quiet "$2" "$1"
        git -C "$1" config user.email "$3"
        # An empty repo has no upstream yet; the first push creates it.
        git -C "$1" pull --quiet --rebase 2> /dev/null || true
      }
      prepare ${targets.work.vault} ${targets.work.repo} ${targets.work.email}
      prepare ${targets.personal.vault} ${targets.personal.repo} ${targets.personal.email}

      while IFS=$'\t' read -r n bank; do
        if [ "$bank" = ${workBank} ]; then vault=${targets.work.vault}; else vault=${targets.personal.vault}; fi
        # coding-agent::job-search -> job-search; journeyai stays journeyai.
        dir=''${bank#coding-agent::}
        dir=''${dir//[:\/]/-}
        rm -rf "''${vault:?}/$dir"; mkdir -p "$vault/$dir"
        jq -c -f ${pages} "$tmp/$n.kb.json" | while read -r page; do
          jq -r .content <<< "$page" > "$vault/$dir/$(jq -r .name <<< "$page")"
        done
        # Dot-folder: Obsidian doesn't index it, git still carries it.
        if [ -f "$tmp/$n.zip" ]; then
          mkdir -p "$vault/.backups"
          cp "$tmp/$n.zip" "$vault/.backups/$dir.zip"
        fi
      done < "$tmp/banks.tsv"

      suffix=""
      [ "$backup" = 1 ] && suffix=" (+backup)"
      for vault in ${targets.work.vault} ${targets.personal.vault}; do
        git -C "$vault" add -A
        git -C "$vault" diff --cached --quiet && continue
        git -C "$vault" commit --quiet -F - <<EOF
      sync: $(date -u +%FT%TZ)$suffix

      Co-Authored-By: Haroun Trabelsi <haroun@meetjourney.ai>
      Co-Authored-By: Haroun Trabelsi <fantasycrit20@gmail.com>
      EOF
        git -C "$vault" push --quiet -u origin HEAD
      done
    '';
  };

  unit = description: arg: {
    Unit = {
      Description = description;
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe sync}${arg}";
    };
  };
in
{
  home.packages = [ sync ];

  systemd.user.services.hindsight-sync = unit "Sync Hindsight memory pages to git" "";
  systemd.user.services.hindsight-backup = unit "Back up Hindsight banks to git" " --backup";

  # Pages every 15 minutes; the full ZIPs (≈300 KB a bank, and git keeps every
  # version) once a day. Persistent so a machine that was off catches up.
  systemd.user.timers.hindsight-sync = {
    Timer = {
      OnCalendar = "*:0/15";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
  systemd.user.timers.hindsight-backup = {
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
