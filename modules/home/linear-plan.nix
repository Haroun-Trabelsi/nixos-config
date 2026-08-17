{ ... }:
{
  # Browser -> Claude Code bridge for Linear issues.
  #
  # A bookmarklet on the Linear issue page navigates to claude-plan://ENG-123;
  # xdg hands that URI to this entry (see xdg-mimes.nix for the association),
  # which runs the linear-plan script from scripts/scripts/linear-plan.sh.
  #
  # The entry is deliberately visible in the launcher: activated with no URI the
  # script falls back to the clipboard, so it doubles as "plan the issue I just
  # copied".
  xdg.desktopEntries.linear-plan = {
    name = "Linear → Claude plan";
    genericName = "Plan a Linear issue";
    comment = "Open a Claude Code terminal running /plan-issue for a Linear issue";
    exec = "linear-plan %u";
    icon = "utilities-terminal";
    terminal = false;
    categories = [
      "Development"
      "Utility"
    ];
    mimeType = [ "x-scheme-handler/claude-plan" ];
  };

  # Kept on disk (and in git) because a bookmarklet otherwise only exists inside
  # the browser profile, which nothing here manages — reinstalling or resetting the
  # profile would lose the only copy.
  #
  # Netscape bookmark format, so it goes in through Bookmark manager -> Import
  # bookmarks and HTML file rather than by hand. PERSONAL_TOOLBAR_FOLDER puts it on
  # the bookmarks bar. ADD_DATE is a fixed epoch on purpose: a real timestamp would
  # make this file's hash change on every rebuild.
  home.file.".local/share/linear-plan/bookmarks.html".text = ''
    <!DOCTYPE NETSCAPE-Bookmark-file-1>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>Bookmarks</TITLE>
    <H1>Bookmarks</H1>
    <DL><p>
        <DT><H3 ADD_DATE="1754352000" LAST_MODIFIED="1754352000" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks bar</H3>
        <DL><p>
            <DT><A HREF="javascript:(function(){var m=location.href.match(/\/issue\/([A-Za-z]+-\d+)/)||document.title.match(/\b([A-Za-z]+-\d+)\b/);if(!m){alert('No Linear issue id on this page');return;}location.href='claude-plan://'+m[1].toUpperCase();})();" ADD_DATE="1754352000">⚡ Plan issue</A>
        </DL><p>
    </DL><p>
  '';
}
