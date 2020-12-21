defmodule Absinthe.FunctionEvaluationHelpers do
  def function_evaluation_test_params do
    [
      %{test_label: :normal_string, expected_value: "string"},
      %{test_label: :local_function_call, expected_value: "red"},
      %{test_label: :function_call_using_absolute_path_to_current_module, expected_value: "red"},
      %{test_label: :standard_library_function, expected_value: "rad"},
      %{test_label: :function_in_nested_module, expected_value: "hello"},
      %{test_label: :external_module_function_call, expected_value: "the value is hello"},
      %{test_label: :module_attribute_string_concat, expected_value: "hello goodbye"},
      %{test_label: :interpolation_of_module_attribute, expected_value: "hello goodbye"}
    ]
  end

  def external_function(arg) do
    "the value is #{arg}"
  end
end
