{ pkgs, ... }:
{
  # Local LLM inference, CUDA-accelerated on the RTX 5060 Ti.
  # Service listens on 127.0.0.1:11434; pull/run models with the `ollama` CLI.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };
}
