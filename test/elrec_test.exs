defmodule ElrecTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Elrec

  alias Elrec

  @file_name "test_file.exs"

  setup do
    File.write!(@file_name, """
    defmodule Test do
      def rec_func([]), do: []
      def rec_func([h | t]), do: [h | rec_func(t)]

      def enum_func(list), do: Enum.map(list, &(&1))
    end
    """)

    on_exit(fn ->
      File.rm(@file_name)
    end)

    :ok
  end

  test "run/4 with valid file and mode :rec_to_enum" do
    assert capture_io(fn ->
             Elrec.run(@file_name, :rec_to_enum, false, false)
           end) =~ "All tests completed."
  end

  test "run/4 with valid file and mode :enum_to_rec" do
    assert capture_io(fn ->
             Elrec.run(@file_name, :enum_to_rec, false, false)
           end) =~ "All tests completed."
  end

  test "run/4 with invalid file" do
    assert capture_io(fn ->
             Elrec.run("invalid_file.exs", :rec_to_enum, false, false)
           end) =~ "Error: enoent"
  end

  test "run/4 with diff option" do
    output =
      capture_io(fn ->
        Elrec.run(@file_name, :rec_to_enum, true, false)
      end)

    assert output =~ "---------conversion result----------"
  end

  test "run/4 with benchmark option" do
    output =
      capture_io(fn ->
        Elrec.run(@file_name, :rec_to_enum, false, true)
      end)

    assert output =~ "---------conversion result----------"
  end
end
