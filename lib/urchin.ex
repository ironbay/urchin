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
      |> Enum.find(:ok, fn
          result = {:error, _} -> true
          _ -> false
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
    %{
      "accessibility" => %{"service" => "basic", "wheelchair" => false},
      "address" => %{
        "format" => "380 Rector Place, New York, NY, USA",
        "lat" => 40.7090972,
        "lng" => -74.01775609999999,
        "name" => "380 Rector Pl",
        "raw" => "380 Rector Pl, New York, NY 10280, USA"
      },
      "communication" => %{"has_mobile" => false},
      "created" => 1520606988817,
      "key" => "0QloFs3iIwuAkvOstFn9",
      "language" => "en",
      "name" => %{"first" => "Dax", "last" => ""},
      "timezone" => "America/New_York"
    }
    |> validate do
			field: ["name", "first"], tests: [Urchin.string(1)] -> "First name is invalid"
			field: ["name", "last"], tests: [Urchin.string(1)] -> "Last name is invalid"
			field: ["timezone"], tests: [Urchin.required()] -> "Timezone is invalid"
			field: ["address", "raw"], tests: [Urchin.required()] -> "Address is invalid"
			field: ["language"], tests: [Urchin.required()] -> "Language is invalid"
			field: ["communication", "has_mobile"], tests: [Urchin.required()] -> "Please specify if patient has a mobile number"
    end
  end
end
