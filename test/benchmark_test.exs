defmodule BenchmarkTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Elrec.Benchmark

  test "run/4 with mode :rec_to_enum" do
    func_info = {MyModule, :my_func, [:integer], false}
    before_test = fn _ -> :ok end
    after_test = fn _ -> :ok end

    output =
      capture_io(fn ->
        Benchmark.run(func_info, :rec_to_enum, before_test, after_test)
      end)

    assert output =~ "Benchmarking MyModule.my_func (integer)"
  end

  test "run/4 with mode :enum_to_rec" do
    func_info = {MyModule, :my_func, [:integer], false}
    before_test = fn _ -> :ok end
    after_test = fn _ -> :ok end

    output =
      capture_io(fn ->
        Benchmark.run(func_info, :enum_to_rec, before_test, after_test)
      end)

    assert output =~ "Benchmarking MyModule.my_func (integer)"
  end

  test "create_title/1 with accumulator" do
    title = Benchmark.create_title({MyModule, :my_func, [:integer], true})
    assert title == "MyModule.my_func (integer) acc = 1"
  end

  test "create_title/1 without accumulator" do
    title = Benchmark.create_title({MyModule, :my_func, [:integer], false})
    assert title == "MyModule.my_func (integer)"
  end

  test "create_tests/3 with mode :rec_to_enum" do
    before_test = fn _ -> :ok end
    after_test = fn _ -> :ok end
    tests = Benchmark.create_tests(:rec_to_enum, before_test, after_test)

    assert Map.has_key?(tests, "Before (rec) ")
    assert Map.has_key?(tests, "After  (enum)")
  end

  test "create_tests/3 with mode :enum_to_rec" do
    before_test = fn _ -> :ok end
    after_test = fn _ -> :ok end
    tests = Benchmark.create_tests(:enum_to_rec, before_test, after_test)

    assert Map.has_key?(tests, "Before (enum)")
    assert Map.has_key?(tests, "After  (rec) ")
  end
end
