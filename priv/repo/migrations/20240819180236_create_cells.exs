defmodule EmojiGraffiti.Repo.Migrations.CreateCells do
  use Ecto.Migration

  def change do
    create table(:cells, primary_key: false) do
      add :id, :integer, primary_key: true
      add :emoji, :string, size: 4
    end
  end
end
