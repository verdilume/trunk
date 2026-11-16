import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import moss

pub type Log {
  Log(
    time: timestamp.Timestamp,
    level: Level,
    message: String,
    fields: List(#(String, String)),
  )
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

/// Print a message with the current local time if its level is enabled.
pub fn log(logger: Logger, level: Level, message: String) -> Nil {
  log_with(logger, level, message, [])
}

/// Print a message with key-value fields if its level is enabled.
pub fn log_with(
  logger: Logger,
  level: Level,
  message: String,
  fields: List(#(String, String)),
) -> Nil {
  case enabled(logger, level) {
    True -> print_log(Log(timestamp.system_time(), level, message, fields))
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

/// Log an informational message with key-value fields.
pub fn info_with(message: String, fields: List(#(String, String))) -> Nil {
  log_with(default_logger, Info, message, fields)
}

/// Log a warning with key-value fields.
pub fn warn_with(message: String, fields: List(#(String, String))) -> Nil {
  log_with(default_logger, Warn, message, fields)
}

/// Log an error with key-value fields.
pub fn error_with(message: String, fields: List(#(String, String))) -> Nil {
  log_with(default_logger, Error, message, fields)
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
    Debug -> "DEBU"
    Info -> "INFO"
    Warn -> "WARN"
    Error -> "ERRO"
    Fatal -> "FATA"
  }
}

/// Render a 12-hour timestamp and an ANSI-styled severity label.
/// The timestamp uses the machine's current local offset.
pub fn render_log(log: Log) -> String {
  let time_str = format_time(log.time)
  let style =
    moss.new()
    |> moss.bold
  let level_style = case log.level {
    Debug -> moss.foreground(style, moss.Cyan)
    Info -> moss.foreground(style, moss.Green)
    Warn -> moss.foreground(style, moss.Yellow)
    Error -> moss.foreground(style, moss.Red)
    Fatal ->
      style
      |> moss.foreground(moss.White)
      |> moss.background(moss.Red)
  }
  let level_str = moss.render(level_style, level_to_string(log.level))

  time_str
  <> " "
  <> level_str
  <> " "
  <> log.message
  <> render_fields(log.fields)
}

fn render_fields(fields: List(#(String, String))) -> String {
  fields
  |> list.map(fn(field) {
    let #(key, value) = field
    " " <> field_token(key) <> "=" <> field_token(value)
  })
  |> string.concat
}

fn field_token(text: String) -> String {
  let characters = string.to_utf_codepoints(text)
  let bare =
    characters != []
    && list.all(characters, fn(character) {
      let code = string.utf_codepoint_to_int(character)
      // Bare tokens use printable ASCII except double quote, equals, and backslash.
      code > 32 && code < 127 && code != 34 && code != 61 && code != 92
    })

  case bare {
    True -> text
    False ->
      "\""
      <> { characters |> list.map(escape_field_character) |> string.concat }
      <> "\""
  }
}

fn escape_field_character(character: UtfCodepoint) -> String {
  case string.utf_codepoint_to_int(character) {
    9 -> "\\t"
    10 -> "\\n"
    13 -> "\\r"
    34 -> "\\\""
    92 -> "\\\\"
    code
      if code < 32
      || { code >= 127 && code <= 159 }
      || code == 0x2028
      || code == 0x2029
    -> "\\u{" <> int.to_base16(code) <> "}"
    _ -> string.from_utf_codepoints([character])
  }
}

fn format_time(time: timestamp.Timestamp) -> String {
  let #(_, time) = timestamp.to_calendar(time, calendar.local_offset())
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
