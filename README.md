# Trunk

Trunk is a Gleam logger that prints UTC times like `10:32:18PM` and uses Moss to
style severity labels.

```gleam
import trunk as log

pub fn main() -> Nil {
  log.info("Server started")
  log.warn("Using defaults")
  log.error("Could not open config")
}
```

These helpers use the default `Info` threshold.

### Custom thresholds

Create a logger with `trunk.new(minimum_level)` and use
`trunk.log(logger, level, message)`. The levels from lowest to highest are
`Debug`, `Info`, `Warn`, `Error`, and `Fatal`. Use
`trunk.enabled(logger, level)` to check the threshold before building an
expensive message.

## Development

Keep the Moss checkout at `../moss` so Gleam can resolve the local dependency.
GitHub Actions checks out Moss beside Trunk from `<owner>/moss` by default.
Set the `MOSS_REPOSITORY` Actions variable to `owner/repo` if Moss is hosted in
a different public repository.

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
