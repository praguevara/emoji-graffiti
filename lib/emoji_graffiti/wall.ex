defmodule EmojiGraffiti.Wall do
  use GenServer
  import Ecto.Query
  alias EmojiGraffiti.Repo
  alias EmojiGraffiti.Cell

  @max_id 9999

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(id) when id >= 0 and id <= @max_id do
    GenServer.call(__MODULE__, {:get, id})
  end

  def get(_id), do: {:error, :invalid_id}

  def get_many(from, to) when from >= 0 and to <= @max_id and from <= to do
    GenServer.call(__MODULE__, {:get_many, from, to})
  end

  def get_many(_from, _to), do: {:error, :invalid_range}

  def update(id, emoji) when id >= 0 and id <= @max_id do
    GenServer.call(__MODULE__, {:update, id, emoji})
  end

  def update(_id, _emoji), do: {:error, :invalid_id}

  # Server Callbacks
  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {cell, new_state} = get_or_fetch_cell(id, state)
    {:reply, cell.emoji, new_state}
  end

  @impl true
  def handle_call({:get_many, from, to}, _from, state) do
    range = from..to
    {cells, new_state} = get_or_fetch_cells(range, state)
    result = Enum.map(from..to, fn id -> cells[id] end)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:update, id, emoji}, _from, state) do
    cell = Map.get(state, id) || %Cell{id: id}
    updated_cell = %{cell | emoji: emoji}

    Phoenix.PubSub.broadcast(
      EmojiGraffiti.PubSub,
      "emoji_updates",
      {:emoji_changed, id, emoji}
    )

    new_state = Map.put(state, id, updated_cell)
    persist_to_db(updated_cell)
    {:reply, {:ok, updated_cell}, new_state}
  end

  # Helper Functions
  defp default_emoji() do
    "⬜"
  end

  defp get_or_fetch_cell(id, state) do
    case Map.fetch(state, id) do
      {:ok, cell} ->
        {cell, state}

      :error ->
        cell = fetch_from_db(id)
        {cell, Map.put(state, id, cell)}
    end
  end

  defp get_or_fetch_cells(ids, state) do
    {present, missing} = Enum.split_with(ids, &Map.has_key?(state, &1))
    present_cells = Map.take(state, present)
    fetched_cells = fetch_many_from_db(missing)
    cells = Map.merge(present_cells, fetched_cells)
    new_state = Map.merge(state, fetched_cells)
    {cells, new_state}
  end

  defp fetch_from_db(id) do
    Repo.get(Cell, id) || %Cell{id: id, emoji: default_emoji()}
  end

  defp fetch_many_from_db(ids) do
    cells =
      Cell
      |> where([c], c.id in ^ids)
      |> Repo.all()

    existing_cells = Map.new(cells, fn cell -> {cell.id, cell} end)

    Enum.reduce(ids, existing_cells, fn id, acc ->
      Map.put_new(acc, id, %Cell{id: id, emoji: default_emoji()})
    end)
  end

  defp persist_to_db(%Cell{emoji: emoji} = cell) do
    IO.puts("Writing to db cell #{cell.id}")
    Repo.insert!(cell, on_conflict: [set: [emoji: emoji]], conflict_target: :id)
  end
end
