//// An actor that load balances pushed messages to registered subjects in a roundrobin fashion. 
//// Subjects can be dynamically registered and unregistered

import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor

/// Messages that can be sent to the Roundrobin actor.
pub type Message(e) {
  /// Registeres a new loadbalancer target
  Register(Subject(e))
  /// Removes a loadbalancer target
  Unregister(Subject(e))
  /// Emit an event that will be loadbalanced to the registered targets
  Push(e)
}

/// The handler to start the round robin actor
///
/// # Examples:
/// ```gleam
/// import fresnel/roundrobin
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
/// fn target(event: Event, id: String) -> actor.Next(Event, String) {
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
///   let assert Ok(loadbalancer) = actor.start([], roundrobin.handler)  
///   let assert Ok(listener1) = actor.start("1", target)
///   let assert Ok(listener2) = actor.start("2", target)
///   process.send(loadbalancer, Lights)
///   process.send(loadbalancer, Camera)
///   process.send(loadbalancer, Action)
/// }
/// ```
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
