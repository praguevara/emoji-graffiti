defmodule EmojiGraffitiWeb.WallLive do
  use Phoenix.LiveView
  alias EmojiGraffiti.Wall

  import EmojiGraffitiWeb.CellComponent, only: [cell: 1]

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(EmojiGraffiti.PubSub, "emoji_updates")
    end

    emoji = Wall.get_many(0, 9999)

    {:ok, assign(socket, emoji: emoji)}
  end

  def handle_event("change_emoji", %{"id" => i, "value" => input_emoji}, socket) do
    with {:ok, _cell} <- Wall.update(i, input_emoji) do
      Phoenix.PubSub.broadcast(
        EmojiGraffiti.PubSub,
        "emoji_updates",
        {:emoji_changed, i, input_emoji}
      )
    end

    {:noreply, socket}
  end

  def handle_info({:emoji_changed, i, new_emoji}, socket) do
    {:noreply, push_event(socket, "update_emoji", %{i: i, emoji: new_emoji})}
  end
end
