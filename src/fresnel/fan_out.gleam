//// An actor that distributes published messages to all subscribed subject. 
//// Subjects can be dynamically subscribed or unsubscribed from the publisher.

import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor

/// Messages that can be sent to the fan_out publisher actor.
pub type Message(e) {
  /// Add a new subscriber that will begin receiving events
  Subscribe(Subject(e))
  /// Remove a subscriber from receiving published messages
  Unsubscribe(Subject(e))
  /// Publish an event to all subscribers
  Publish(e)
}

/// The handler to start the round robin actor
///
/// Examples:
/// ```gleam
/// import fresnel/fan_out
/// import gleam/otp/actor
/// import gleam/erlang/process
/// import gleam/io
///
/// type Event {
///   Lights
///   Camera
///   Action
/// }
///
/// fn subscriber(event: Event, id: String) -> actor.Next(Event, String) {
///   case event {
///     Lights -> {
///       io.println(id<>": lights")
///       actor.continue(id)
///     }
///     Camera -> {
///       io.println(id<>": camera")
///       actor.continue(id)
///     }
///     Action -> {
///       io.println(id<>": action!")
///       actor.continue(id)
///     }
///   }
/// }
///
/// pub fn main() {
///   let assert Ok(publisher) = actor.start([], fan_out.handler)  
///   let assert Ok(listener1) = actor.start("1", subscriber)
///   let assert Ok(listener2) = actor.start("2", subscriber)
///   process.send(publisher, Lights)
///   process.send(publisher, Camera)
///   process.send(publisher, Action)
/// }
/// ```
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
