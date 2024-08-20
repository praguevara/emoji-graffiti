defmodule EmojiGraffiti.Cell do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cells" do
    field :emoji, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cell, attrs) do
    cell
    |> cast(attrs, [:emoji])
    |> validate_required([:emoji])
  end
end
