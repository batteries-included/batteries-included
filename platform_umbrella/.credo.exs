%{
  configs: [
    %{
      name: "default",
      checks: [
        # deactivate checks that are not compatible with Elixir 1.9.1
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false},
        # don't fail on TODO tags
        {Credo.Check.Design.TagTODO, false}
      ]
    }
  ]
}
