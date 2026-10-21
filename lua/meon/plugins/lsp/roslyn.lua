return {
    "seblyng/roslyn.nvim",
    ft = "cs",
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
        -- Let Roslyn watch files itself; nvim's watcher floods it with
        -- didChangeWatchedFiles on this large solution and slows navigation.
        filewatching = "roslyn",
        config = {
            settings = {
                ["csharp|background_analysis"] = {
                    dotnet_analyzer_diagnostics_scope = "openFiles",
                    dotnet_compiler_diagnostics_scope = "openFiles",
                },
                ["csharp|inlay_hints"] = {
                    csharp_enable_inlay_hints_for_implicit_object_creation = false,
                    csharp_enable_inlay_hints_for_implicit_variable_types = false,
                    csharp_enable_inlay_hints_for_lambda_parameter_types = false,
                    csharp_enable_inlay_hints_for_types = false,
                    dotnet_enable_inlay_hints_for_indexer_parameters = false,
                    dotnet_enable_inlay_hints_for_literal_parameters = false,
                    dotnet_enable_inlay_hints_for_object_creation_parameters = false,
                    dotnet_enable_inlay_hints_for_other_parameters = false,
                    dotnet_enable_inlay_hints_for_parameters = false,
                    dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
                    dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
                    dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
                },
            },
        },
    },
}
