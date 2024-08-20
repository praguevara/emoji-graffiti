defmodule EmojiGraffiti.Repo do
  use Ecto.Repo,
    otp_app: :emoji_graffiti,
    adapter: Ecto.Adapters.Postgres
end
