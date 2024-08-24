defmodule EmojiGraffiti.Wall do
  use GenServer
  import Ecto.Query
  alias EmojiGraffiti.Repo
  alias EmojiGraffiti.Cell

  require Logger

  @max_count 100_000 - 1

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(id) when id >= 0 and id <= @max_count do
    GenServer.call(__MODULE__, {:get, id})
  end

  def get(_id), do: {:error, :invalid_id}

  def get_many(from, to) when from >= 0 and to > from and to <= @max_count do
    Logger.debug("Getting cells from #{from} to #{to}")
    GenServer.call(__MODULE__, {:get_many, from, to})
  end

  def get_many(_from, _count), do: {:error, :invalid_range}

  def update(id, emoji) when id >= 0 and id <= @max_count do
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
    {cells, new_state} = get_or_fetch_cells(from, to, state)
    result = Enum.map(from..to, fn id -> cells[id] end)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:update, id, emoji}, _from, state) do
    cell = %Cell{id: id}
    updated_cell = %{cell | emoji: emoji}

    new_state = Map.put(state, id, updated_cell)
    persist_to_db(updated_cell)

    Phoenix.PubSub.broadcast(
      EmojiGraffiti.PubSub,
      "emoji_updates",
      {:emoji_changed, id, emoji}
    )

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

  defp get_or_fetch_cells(from, to, state) do
    all_present =
      Enum.all?(Enum.to_list(from..to), &Map.has_key?(state, &1))

    if all_present do
      {Map.take(state, Enum.to_list(from..to)), state}
    else
      cells = fetch_range_from_db(from, to)
      new_state = Map.merge(state, cells)
      {cells, new_state}
    end
  end

  defp fetch_from_db(id) do
    Repo.get(Cell, id) || %Cell{id: id, emoji: default_emoji()}
  end

  defp fetch_range_from_db(from, to) do
    cells =
      Cell
      |> where([c], c.id >= ^from and c.id <= ^to)
      |> Repo.all()

    existing_cells = Map.new(cells, fn cell -> {cell.id, cell} end)

    Enum.reduce(from..to, existing_cells, fn id, acc ->
      Map.put_new(acc, id, %Cell{id: id, emoji: default_emoji()})
    end)
  end

  defp persist_to_db(%Cell{emoji: emoji} = cell) do
    Logger.info("Writing to db cell #{inspect(cell)}")
    Repo.insert!(cell, on_conflict: [set: [emoji: emoji]], conflict_target: :id)
  end
end
