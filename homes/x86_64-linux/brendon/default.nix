{
    # Snowfall Lib provides a customized `lib` instance with access to your flake's library
    # as well as the libraries available from your flake's inputs.
    lib,
    pkgs,
    inputs,
    config,
    ...
}:
{
    snowfallorg.user.enable = true;
    snowfallorg.user.name = "my-user";
    snowfallorg.user.home = "/mnt/home/my-user";
}
