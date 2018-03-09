defmodule Urchin.Required do
	def check(nil), do: false
	def check(_), do: true
end

defmodule Urchin.NotBlank do
	def check(""), do: false
	def check(nil), do: false
	def check(_), do: true
end