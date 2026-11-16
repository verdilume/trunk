import gleam/int
import gleam/io
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import moss

pub type Log {
  Log(time: timestamp.Timestamp, level: Level, message: String)
}

pub type Level {
  Debug
  Info
  Warn
  Error
  Fatal
}

pub opaque type Logger {
  Logger(minimum_level: Level)
}

const default_logger = Logger(Info)

/// Create a logger that prints messages at or above `minimum_level`.
pub fn new(minimum_level: Level) -> Logger {
  Logger(minimum_level)
}

/// Check the logger's threshold before building an expensive message.
pub fn enabled(logger: Logger, level: Level) -> Bool {
  level_rank(level) >= level_rank(logger.minimum_level)
}

/// Print a message with the current UTC time if its level is enabled.
pub fn log(logger: Logger, level: Level, message: String) -> Nil {
  case enabled(logger, level) {
    True -> print_log(Log(timestamp.system_time(), level, message))
    False -> Nil
  }
}

/// Log an informational message with the default logger.
pub fn info(message: String) -> Nil {
  log(default_logger, Info, message)
}

/// Log a warning with the default logger.
pub fn warn(message: String) -> Nil {
  log(default_logger, Warn, message)
}

/// Log an error with the default logger.
pub fn error(message: String) -> Nil {
  log(default_logger, Error, message)
}

fn level_rank(level: Level) -> Int {
  case level {
    Debug -> 0
    Info -> 1
    Warn -> 2
    Error -> 3
    Fatal -> 4
  }
}

pub fn level_to_string(level: Level) -> String {
  case level {
    Debug -> "DEBUG"
    Info -> "INFO"
    Warn -> "WARN"
    Error -> "ERROR"
    Fatal -> "FATAL"
  }
}

/// Render the UTC time in 12-hour format and an ANSI-styled severity label.
pub fn render_log(log: Log) -> String {
  let time_str = format_time(log.time)
  let style = moss.new()
  let level_style = case log.level {
    Debug -> moss.foreground(style, moss.Cyan)
    Info -> moss.foreground(style, moss.Green)
    Warn -> moss.foreground(style, moss.Yellow)
    Error -> moss.foreground(style, moss.Red)
    Fatal ->
      style
      |> moss.foreground(moss.White)
      |> moss.background(moss.Red)
      |> moss.bold
  }
  let level_str = moss.render(level_style, level_to_string(log.level))

  time_str <> " " <> level_str <> " " <> log.message
}

fn format_time(time: timestamp.Timestamp) -> String {
  let #(_, time) = timestamp.to_calendar(time, calendar.utc_offset)
  let hour = case time.hours % 12 {
    0 -> 12
    hour -> hour
  }
  let period = case time.hours < 12 {
    True -> "AM"
    False -> "PM"
  }

  two_digits(hour)
  <> ":"
  <> two_digits(time.minutes)
  <> ":"
  <> two_digits(time.seconds)
  <> period
}

fn two_digits(value: Int) -> String {
  value |> int.to_string |> string.pad_start(to: 2, with: "0")
}

pub fn print_log(log: Log) -> Nil {
  io.println(render_log(log))
}

pub fn main() -> Nil {
  info("Server started")
  warn("Using defaults")
  error("Could not open config")
}
