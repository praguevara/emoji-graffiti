defmodule EmojiGraffitiWeb.CellComponent do
  use Phoenix.Component

  def cell(assigns) do
    ~H"""
    <button class="cell" id={"emo-#{Integer.to_string(@i, 16)}"}>
      <%= @emoji %>
    </button>
    """
  end
end
