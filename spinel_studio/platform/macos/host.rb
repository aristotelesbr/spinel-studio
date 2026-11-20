# What the code asks about the system it runs on.
module Host
  NAME = "macos"  # config/NAME.json, when there, is laid over application.json
  OPEN = "open"   # the command that opens a file with its default app
  USER_SETTINGS = File.expand_path("~/Library/Application Support/Spinel Studio/settings.json")
end
