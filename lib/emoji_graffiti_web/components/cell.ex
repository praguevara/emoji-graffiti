defmodule EmojiGraffitiWeb.CellComponent do
  use Phoenix.Component

  def cell(assigns) do
    ~H"""
    <button class="cell" id={@id} }>
      <%= @emoji %>
    </button>
    """
  end
end
