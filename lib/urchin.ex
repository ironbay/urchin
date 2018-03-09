defmodule Urchin do
  defmacro validate(data, body) do
    checks =
      body
      |> Keyword.get(:do)
      |> Enum.map(fn {:->, _, [[opts], error]} ->
        opts =
          [
            field: [],
            tests: [],
          ]
          |> Keyword.merge(opts)
        field = Keyword.get(opts, :field)
        tests = Keyword.get(opts, :tests)
        quote do
          {unquote(field), unquote(tests), unquote(error)}
        end
      end)
    quote do
      data = unquote(data)
      unquote(checks)
      |> Stream.map(fn {field, tests, error} ->
        value = Dynamic.get(data, field)
        tests
        |> Stream.map(fn
          result when is_function(result) -> result.(value)
          result when is_atom(result) -> result.check(value)
        end)
        |> Enum.all?(&(&1))
        |> case do
          true -> :ok
          _ -> {:error, error}
        end
      end)
      |> Enum.find_value(fn
        result = {:error, _} -> result
        _ -> :ok
      end)
    end
  end

  def string(min \\ -1, max \\ nil) do
    fn
      x when is_binary(x) ->
        length = String.length(x)
        length >= min && length <= max
      _ -> false
    end
  end

  def required() do
    fn
      nil -> false
      _ -> true
    end
  end
end

defmodule Urchin.Example do
  import Urchin

  def run() do
    data = %{
      "lol" => "",
      "some" => %{
        "data" => "ok"
      },
    }

    validate data do
      field: ["lol"], tests: [Urchin.string(1, 10)] -> "lol is invalid"
      field: ["some", "data"], tests: [Urchin.required()] -> "Some data is invalid"
    end
  end
end
