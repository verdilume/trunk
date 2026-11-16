import gleam/list
import gleam/time/calendar
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
  let time = timestamp_for_local_clock("2026-11-15T22:32:18.987827583Z")

  list.each(
    [
      #(trunk.Debug, "\u{001b}[1;36mDEBU"),
      #(trunk.Info, "\u{001b}[1;32mINFO"),
      #(trunk.Warn, "\u{001b}[1;33mWARN"),
      #(trunk.Error, "\u{001b}[1;31mERRO"),
      #(trunk.Fatal, "\u{001b}[1;37;41mFATA"),
    ],
    fn(example) {
      let #(level, styled_label) = example

      trunk.Log(time, level, "hello", [])
      |> trunk.render_log
      |> should.equal("10:32:18PM " <> styled_label <> "\u{001b}[0m hello")
    },
  )
}

pub fn render_log_appends_escaped_fields_in_order_test() {
  let time = timestamp_for_local_clock("2026-11-15T22:32:18Z")

  trunk.Log(time, trunk.Info, "Request completed", [
    #("method", "GET"),
    #("status", "200"),
    #("request path", "/café menu"),
    #("detail", "a=\"b\"\\c\n\t\u{001b}"),
    #("err", "permission denied"),
    #("empty", ""),
  ])
  |> trunk.render_log
  |> should.equal(
    "10:32:18PM \u{001b}[1;32mINFO\u{001b}[0m Request completed"
    <> " method=GET status=200 \"request path\"=\"/café menu\""
    <> " detail=\"a=\\\"b\\\"\\\\c\\n\\t\\u{1B}\""
    <> " \u{001b}[90merr=\u{001b}[0m\"permission denied\" empty=\"\"",
  )
}

pub fn render_log_uses_12_hour_time_test() {
  list.each(
    [
      #("1970-01-01T00:00:00Z", "12:00:00AM"),
      #("1970-01-01T01:02:03Z", "01:02:03AM"),
      #("1970-01-01T12:00:00Z", "12:00:00PM"),
    ],
    fn(example) {
      let #(input, expected) = example
      let time = timestamp_for_local_clock(input)

      trunk.Log(time, trunk.Info, "hello", [])
      |> trunk.render_log
      |> should.equal(expected <> " \u{001b}[1;32mINFO\u{001b}[0m hello")
    },
  )
}

fn timestamp_for_local_clock(input: String) -> timestamp.Timestamp {
  let assert Ok(time) = timestamp.parse_rfc3339(input)
  timestamp.subtract(time, calendar.local_offset())
}
