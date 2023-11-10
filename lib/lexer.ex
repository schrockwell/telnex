defmodule Telnex.Lexer do
  @moduledoc """
  Implements a lexer for RFC 854.

  https://datatracker.ietf.org/doc/html/rfc854
  """
  defstruct buffer: ""

  @special_chars %{
    null: 0,
    lf: 10,
    # cr: 13, # ignore CR that's on its own
    bell: 7,
    bs: 8,
    ht: 9,
    vt: 11,
    ff: 12
  }

  @basic_commands %{
    se: 240,
    nop: 241,
    data_mark: 242,
    break: 243,
    interrupt_process: 244,
    abort_output: 245,
    are_you_there: 246,
    erase_character: 247,
    erase_line: 248,
    go_ahead: 249,
    sb: 250
  }

  @option_commands %{
    will: 251,
    wont: 252,
    do: 253,
    dont: 254
  }

  @cr 13
  @lf 10
  @null 0

  @iac 255

  def put(lexer, binary) do
    all_next(%{lexer | buffer: lexer.buffer <> binary})
  end

  defp all_next(lexer, acc \\ [])

  defp all_next(lexer, acc) do
    case next(lexer) do
      {nil, lexer} -> {Enum.reverse(acc), lexer}
      {token, lexer} -> all_next(lexer, [token | acc])
    end
  end

  # ASCII text
  defp next(%{buffer: <<char, rest::binary>>} = lexer) when char in 32..126 do
    lexer = %{lexer | buffer: rest}
    {<<char>>, lexer}
  end

  # Newlines
  defp next(%{buffer: <<@cr, @lf, rest::binary>>} = lexer) do
    lexer = %{lexer | buffer: rest}
    {:cr_lf, lexer}
  end

  defp next(%{buffer: <<@cr, @null, rest::binary>>} = lexer) do
    lexer = %{lexer | buffer: rest}
    {:cr_nul, lexer}
  end

  # Special characters
  for {name, code} <- @special_chars do
    defp next(%{buffer: <<char, rest::binary>>} = lexer) when char == unquote(code) do
      lexer = %{lexer | buffer: rest}
      {unquote(name), lexer}
    end
  end

  # Basic commands
  for {name, code} <- @basic_commands do
    defp next(%{buffer: <<@iac, unquote(code), rest::binary>>} = lexer) do
      lexer = %{lexer | buffer: rest}
      {unquote(name), lexer}
    end
  end

  # Commands with options
  for {name, code} <- @option_commands do
    defp next(%{buffer: <<@iac, unquote(code), option, rest::binary>>} = lexer) do
      lexer = %{lexer | buffer: rest}
      {{unquote(name), option}, %{lexer | buffer: rest}}
    end
  end

  # Invalid character
  defp next(%{buffer: <<char, rest::binary>>} = lexer) do
    {{:invalid, char}, %{lexer | buffer: rest}}
  end

  # Empty buffer
  defp next(%{buffer: <<>>} = lexer) do
    {nil, %{lexer | buffer: <<>>}}
  end
end
