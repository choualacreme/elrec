defmodule CliTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Elrec
  import Elrec.CLI, only: [main: 1]

  test ":help returned by option parsing with -h and --help options" do
    output = capture_io(fn -> main(["-h", "anything"]) end)
    assert output =~ "Usage: mix elrec [options] <.exs file>"

    output = capture_io(fn -> main(["--help", "anything"]) end)
    assert output =~ "Usage: mix elrec [options] <.exs file>"
  end

  test ":version returned by option parsing with -v and --version options" do
    output = capture_io(fn -> main(["-v", "anything"]) end)
    assert output =~ "ELREC version"

    output = capture_io(fn -> main(["--version", "anything"]) end)
    assert output =~ "ELREC version"
  end

  test "mode option parsing with -m and --mode options" do
    output = capture_io(fn -> main(["-m", "to_enum", "file.exs"]) end)
    assert output =~ "Error: enoent"

    output = capture_io(fn -> main(["--mode", "to_rec", "file.exs"]) end)
    assert output =~ "Error: enoent"
  end

  test "diff option parsing with -d and --diff options" do
    output = capture_io(fn -> main(["-d", "file.exs"]) end)
    assert output =~ "Invalid mode. Use `--mode to_enum` or `--mode to_rec`"

    output = capture_io(fn -> main(["--diff", "file.exs"]) end)
    assert output =~ "Invalid mode. Use `--mode to_enum` or `--mode to_rec`"
  end

  test "benchmark option parsing with -b and --benchmark options" do
    output = capture_io(fn -> main(["-b", "file.exs"]) end)
    assert output =~ "Invalid mode. Use `--mode to_enum` or `--mode to_rec`"

    output = capture_io(fn -> main(["--benchmark", "file.exs"]) end)
    assert output =~ "Invalid mode. Use `--mode to_enum` or `--mode to_rec`"
  end

  test "invalid mode option" do
    output = capture_io(fn -> main(["--mode", "invalid", "file.exs"]) end)
    assert output =~ "Invalid mode. Use `--mode to_enum` or `--mode to_rec`"
  end

  test "invalid arguments" do
    output = capture_io(fn -> main([]) end)
    assert output =~ "Invalid arguments. Use --help for usage information."
  end
end
