{ 
  config, 
  lib, 
  pkgs, 
  inputs, 
  ... 
}:

{

  options = {
    podman = {
      enable = lib.mkOption {
	      description = "Enable podman and tools.";
	      type = lib.types.bool;
	      default = false;
      };
    };
  };

  config = lib.mkIf config.podman.enable {

    virtualisation.oci-containers.containers = {
        # Define a service named 'my-web-app'
        my-web-app = {
        image = "docker.io/library/nginx:latest"; # Replace with your desired image
        autoStart = true; # Start automatically on boot
        ports = [ "8080:80" ]; # Host_Port:Container_Port
        # Optional: Environment variables
        # environment = {
        #   MY_ENV_VAR = "my_value";
        # };
        # Optional: Volumes
        # volumes = [ "/path/on/host:/path/in/container" ];
        # Optional: Network configuration
        # extraContainerFlags = [ "--network=host" ];
        };

        # Define another service if needed
        # another-service = {
        #   image = "my-registry/my-image:tag";
        #   autoStart = true;
        #   ports = [ "9000:8000" ];
        # };
    };
    }
  };
}