{
  programs.nixvim.plugins = {
    copilot-lua = {
      enable = true;
      autoLoad = true;
    };

    copilot-chat = {
      enable = true;
    };
  };
}
