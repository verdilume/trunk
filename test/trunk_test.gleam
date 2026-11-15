import gleam/list
import gleam/time/timestamp
import gleeunit
import gleeunit/should
import trunk

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn minimum_level_includes_the_threshold_and_higher_levels_test() {
  let logger = trunk.new(trunk.Warn)
  let levels = [trunk.Debug, trunk.Info, trunk.Warn, trunk.Error, trunk.Fatal]

  levels
  |> list.filter(trunk.enabled(logger, _))
  |> should.equal([trunk.Warn, trunk.Error, trunk.Fatal])
}

pub fn render_log_styles_only_the_level_test() {
  let time = timestamp.from_unix_seconds(0)

  list.each(
    [
      #(trunk.Debug, "\u{001b}[36mDEBUG"),
      #(trunk.Info, "\u{001b}[32mINFO"),
      #(trunk.Warn, "\u{001b}[33mWARN"),
      #(trunk.Error, "\u{001b}[31mERROR"),
      #(trunk.Fatal, "\u{001b}[1;37;41mFATAL"),
    ],
    fn(example) {
      let #(level, styled_label) = example

      trunk.Log(time, level, "hello")
      |> trunk.render_log
      |> should.equal(
        "1970-01-01T00:00:00Z " <> styled_label <> "\u{001b}[0m hello",
      )
    },
  )
}
