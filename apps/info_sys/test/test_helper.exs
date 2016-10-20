Code.require_file "backends/http_client.exs", __DIR__
ExUnit.start()

Mix.Task.run "ecto.create", ~w(-r Rumbl.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Rumbl.Repo --quiet)

