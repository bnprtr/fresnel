import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/list
import gleam/otp/actor

pub type Message(e) {
  Register(Subject(e))
  Unregister(Subject(e))
  Push(e)
}

pub fn handler(
  msg: Message(e),
  targets: List(Subject(e)),
) -> actor.Next(Message(e), List(Subject(e))) {
  case msg {
    Push(event) -> {
      let assert Ok(target) = list.first(targets)
      process.send(target, event)
      actor.continue(rotate(targets))
    }
    Register(target) -> actor.continue(list.append(targets, [target]))
    Unregister(target) ->
      actor.continue(list.filter(targets, fn(t) { t != target }))
  }
}

fn rotate(targets: List(Subject(e))) -> List(Subject(e)) {
  case targets {
    [] -> []
    [first] -> [first]
    [first, ..rest] -> list.append(rest, [first])
  }
}
