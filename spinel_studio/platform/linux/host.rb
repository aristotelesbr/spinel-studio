# What the code asks about the system it runs on.
module Host
  NAME = "linux"          # config/NAME.json, when there, is laid over application.json
  OPEN = "xdg-open"       # opens a file with its default app
  USER_SETTINGS = File.expand_path("~/.config/spinel-studio/settings.json")
end
