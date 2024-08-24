defmodule EmojiGraffitiWeb.WallLive do
  use Phoenix.LiveView

  alias EmojiGraffiti.Wall
  alias EmojiGraffiti.Validator

  @column_size 12
  @chunk_size 300 * @column_size

  import EmojiGraffitiWeb.CellComponent, only: [cell: 1]

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(EmojiGraffiti.PubSub, "emoji_updates")
    end

    emojis = Wall.get_many(0, @chunk_size - 1)
    rows = group_emojis_into_rows(emojis)

    socket =
      socket
      |> assign(:start, @chunk_size)
      |> stream(:rows, rows)

    {:ok, socket}
  end

  defp group_emojis_into_rows(emojis) do
    emojis
    |> Enum.chunk_every(@column_size)
    |> Enum.with_index()
    |> Enum.map(fn {row, index} -> %{id: index, row: row} end)
  end

  def handle_event("change_emoji", %{"id" => i, "value" => input_emoji}, socket) do
    with {:ok, _msg} <- Validator.validate_emoji(input_emoji) do
      Wall.update(i, input_emoji)
    end

    {:noreply, socket}
  end

  def handle_event("load_more", _, socket) do
    start = socket.assigns.start
    to = start + @chunk_size - 1

    emojis = Wall.get_many(start, to)

    case emojis do
      [_ | _] ->
        rows = group_emojis_into_rows(emojis)
        socket = socket |> assign(:start, start + @chunk_size) |> stream(:rows, rows)
        {:noreply, socket}

      _ ->
        {:noreply, push_event(socket, "finish_scroll", %{})}
    end
  end

  def handle_info({:emoji_changed, i, new_emoji}, socket) do
    {:noreply, push_event(socket, "update_emoji", %{i: i, emoji: new_emoji})}
  end
end
