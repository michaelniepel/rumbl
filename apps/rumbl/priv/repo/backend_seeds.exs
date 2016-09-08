alias Rumbl.Repo
alias Rumbl.User


Repo.get_by(User, username: "wolfram") ||
  Repo.insert!(%User{name: "Wolfram", username: "wolfram"})
