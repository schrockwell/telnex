defmodule Telnex.LexerTest do
  use ExUnit.Case
  doctest Telnex

  alias Telnex.Lexer

  test "a basic mixed string" do
    # GIVEN
    lexer = %Lexer{}
    string = <<"hello", 13, 10, "world", 255, 246, 255, 251, 123, 220>>

    # WHEN
    {tokens, _lexer} = Lexer.put(lexer, string)

    # THEN
    assert tokens == [
             "h",
             "e",
             "l",
             "l",
             "o",
             :cr_lf,
             "w",
             "o",
             "r",
             "l",
             "d",
             :are_you_there,
             {:will, 123},
             {:invalid, 220}
           ]
  end

  test "commands" do
    # GIVEN
    lexer = %Lexer{}

    string =
      <<255, 240, 255, 241, 255, 242, 255, 243, 255, 244, 255, 245, 255, 246, 255, 247, 255, 248,
        255, 249, 255, 250>>

    # WHEN
    {tokens, _lexer} = Lexer.put(lexer, string)

    # THEN
    assert tokens == [
             :se,
             :nop,
             :data_mark,
             :break,
             :interrupt_process,
             :abort_output,
             :are_you_there,
             :erase_character,
             :erase_line,
             :go_ahead,
             :sb
           ]
  end

  test "option commands" do
    # GIVEN
    lexer = %Lexer{}

    string = <<255, 251, 1, 255, 252, 2, 255, 253, 3, 255, 254, 4>>

    # WHEN
    {tokens, _lexer} = Lexer.put(lexer, string)

    # THEN
    assert tokens == [will: 1, wont: 2, do: 3, dont: 4]
  end
end
