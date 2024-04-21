import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/list
import gleam/otp/actor

pub type Message(e) {
  Subscribe(Subject(e))
  Unsubscribe(Subject(e))
  Publish(e)
}

pub fn handler(
  msg: Message(e),
  subscribers: List(Subject(e)),
) -> actor.Next(Message(e), List(Subject(e))) {
  case msg {
    Publish(event) -> {
      list.map(subscribers, fn(s) { process.send(s, event) })
      actor.continue(subscribers)
    }
    Subscribe(subscriber) ->
      actor.continue(list.concat([subscribers, [subscriber]]))
    Unsubscribe(subscriber) ->
      actor.continue(list.filter(subscribers, fn(s) { s != subscriber }))
  }
}
