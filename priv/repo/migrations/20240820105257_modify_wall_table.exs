defmodule EmojiGraffiti.Repo.Migrations.ModifyWallTable do
  use Ecto.Migration

  def change do
    alter table(:cells) do
      modify :emoji, :string, size: 64
    end
  end
end
