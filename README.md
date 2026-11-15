# Trunk

Trunk is a Gleam logger that prints UTC times like `10:32:18PM` and uses Moss to
style severity labels.

```gleam
import trunk

pub fn main() -> Nil {
  let logger = trunk.new(trunk.Warn)
  trunk.log(logger, trunk.Debug, "Opening config file")
  trunk.log(logger, trunk.Warn, "Config file missing; using defaults")
}
```

This prints only the warning. From lowest to highest, the levels are `Debug`,
`Info`, `Warn`, `Error`, and `Fatal`. Check `trunk.enabled(logger, level)` before
building a message if preparing it is expensive.

## Development

Keep the Moss checkout at `../moss` so Gleam can resolve the local dependency.
GitHub Actions checks out Moss beside Trunk from `<owner>/moss` by default.
Set the `MOSS_REPOSITORY` Actions variable to `owner/repo` if Moss is hosted in
a different public repository.

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
