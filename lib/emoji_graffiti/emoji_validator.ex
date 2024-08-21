defmodule EmojiGraffiti.Validator do
  def validate_emoji(input) do
    input
    |> String.graphemes()
    |> Enum.any?(&is_emoji?/1)
    |> case do
      true -> {:ok, "Valid emoji"}
      false -> {:error, "Invalid emoji"}
    end
  end

  defp is_emoji?(char) do
    unicode_blocks = [
      # Emoticons
      0x1F600..0x1F64F,
      # Miscellaneous Symbols and Pictographs
      0x1F300..0x1F5FF,
      # Transport and Map Symbols
      0x1F680..0x1F6FF,
      # Regional Indicator Symbols
      0x1F1E6..0x1F1FF,
      # Alchemical Symbols
      0x1F700..0x1F77F,
      # Geometric Shapes Extended
      0x1F780..0x1F7FF,
      # Supplemental Arrows-C
      0x1F800..0x1F8FF,
      # Supplemental Symbols and Pictographs
      0x1F900..0x1F9FF,
      # Chess Symbols
      0x1FA00..0x1FA6F,
      # Symbols and Pictographs Extended-A
      0x1FA70..0x1FAFF,
      # Miscellaneous Symbols
      0x2600..0x26FF,
      # Dingbats
      0x2700..0x27BF
    ]

    char
    |> to_charlist()
    |> Enum.any?(fn codepoint ->
      Enum.any?(unicode_blocks, fn range -> codepoint in range end)
    end)
  end
end
