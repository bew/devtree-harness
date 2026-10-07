{ config, lib, ... }:

let
  cfg = config.devtree;
in
{
  options.devtree.for-opencode.enable = lib.mkEnableOption "devtree opencode context plugin";

  config = lib.mkIf cfg.for-opencode.enable {
    xdg.configFile."opencode/plugins/devtree-context.ts".source =
      ./opencode-plugin/devtree-context.ts;
  };
}
