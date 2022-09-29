common_checks = [
  {Credo.Check.Consistency.ExceptionNames},
  {Credo.Check.Consistency.LineEndings},
  {Credo.Check.Consistency.SpaceAroundOperators},
  {Credo.Check.Consistency.SpaceInParentheses},
  {Credo.Check.Consistency.TabsOrSpaces},
  {Credo.Check.Design.AliasUsage, if_called_more_often_than: 4, if_nested_deeper_than: 1},
  {Credo.Check.Design.TagTODO, false},
  {Credo.Check.Design.TagFIXME},
  {Credo.Check.Readability.AliasOrder, false},
  {Credo.Check.Readability.FunctionNames},
  {Credo.Check.Readability.LargeNumbers},
  {Credo.Check.Readability.MaxLineLength, max_length: 150},
  {Credo.Check.Readability.ModuleAttributeNames},
  {Credo.Check.Readability.ModuleDoc, false},
  {Credo.Check.Readability.ModuleNames},
  {Credo.Check.Readability.ParenthesesInCondition},
  {Credo.Check.Readability.PredicateFunctionNames},
  {Credo.Check.Readability.SinglePipe,
   files: %{
     excluded: [
       "apps/kube_ext/lib/mix/tasks/gen_resource.ex"
     ]
   }},
  {Credo.Check.Readability.StrictModuleLayout},
  {Credo.Check.Readability.TrailingBlankLine},
  {Credo.Check.Readability.TrailingWhiteSpace},
  {Credo.Check.Readability.VariableNames},
  {Credo.Check.Refactor.ABCSize,
   max_size: 40,
   files: %{
     excluded: [
       "apps/control_server/lib/control_server/services/runnable_service.ex",
       "apps/kube_resources/lib/kube_resources/security/cert_manager.ex",
       "apps/kube_resources/lib/kube_resources/data/rook.ex"
     ]
   }},
  {Credo.Check.Refactor.Apply,
   files: %{
     excluded: [
       "apps/home_base_web/lib/home_base_web.ex",
       "apps/control_server_web/lib/control_server_web.ex"
     ]
   }},
  {Credo.Check.Refactor.CaseTrivialMatches},
  {Credo.Check.Refactor.CondStatements},
  {Credo.Check.Refactor.FunctionArity},
  {Credo.Check.Refactor.MatchInCondition},
  {Credo.Check.Refactor.PipeChainStart,
   excluded_argument_types: ~w(atom binary fn keyword)a, excluded_functions: ~w(from)},
  {Credo.Check.Refactor.CyclomaticComplexity},
  {Credo.Check.Refactor.NegatedConditionsInUnless},
  {Credo.Check.Refactor.NegatedConditionsWithElse},
  {Credo.Check.Refactor.Nesting},
  {Credo.Check.Refactor.UnlessWithElse},
  {Credo.Check.Refactor.WithClauses},
  {Credo.Check.Warning.IExPry},
  {Credo.Check.Warning.IoInspect},
  {Credo.Check.Warning.LazyLogging, false},
  {Credo.Check.Warning.OperationOnSameValues},
  {Credo.Check.Warning.BoolOperationOnSameValues},
  {Credo.Check.Warning.UnusedEnumOperation},
  {Credo.Check.Warning.UnusedKeywordOperation},
  {Credo.Check.Warning.UnusedListOperation},
  {Credo.Check.Warning.UnusedStringOperation},
  {Credo.Check.Warning.UnusedTupleOperation},
  {Credo.Check.Warning.OperationWithConstantResult},
  {CredoEnvvar.Check.Warning.EnvironmentVariablesAtCompileTime,
   files: %{
     excluded: ["apps/kube_raw_resources/lib/kube_raw_resources/battery/battery_settings.ex"]
   }},
  {CredoNaming.Check.Warning.AvoidSpecificTermsInModuleNames,
   terms: [
     "Fetcher",
     "Persister",
     "Serializer",
     ~r/^Helpers?$/i,
     ~r/^Utils?$/i
   ],
   files: %{
     excluded: [
       "apps/*/lib/*/live/live_helpers.ex",
       "apps/*/lib/*/views/error_helpers.ex"
     ]
   }}
]

%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: [
          "*.exs",
          "rel/",
          "config",
          "apps/*/lib/"
        ],
        excluded: ["apps/kube_ext/lib/mix/tasks/gen_resource.ex"]
      },
      checks:
        common_checks ++
          [
            {Credo.Check.Design.DuplicatedCode,
             excluded_macros: [],
             files: %{
               excluded: [
                 "apps/control_server/lib/control_server/services/*.ex",
                 "apps/*/lib/*/live/live_helpers.ex"
               ]
             }}
          ]
    },
    %{
      name: "test",
      strict: true,
      files: %{
        included: [
          "apps/*/test/"
        ],
        excluded: []
      },
      checks: common_checks
    }
  ]
}
