defmodule Absinthe.FunctionEvaluationHelpers do
  def function_evaluation_test_params do
    [
      %{test_label: :normal_string, expected_description: "string"},
      %{test_label: :local_function_call, expected_description: "red"},
      %{test_label: :function_call_using_absolute_path, expected_description: "red"},
      %{test_label: :standard_library_function_works, expected_description: "rad"},
      %{test_label: :function_nested_in_module, expected_description: "hello"},
      %{test_label: :module_attribute, expected_description: "hello goodbye"},
      %{test_label: :interpolation_of_module_attribute, expected_description: "hello goodbye"}
    ]
  end
end
