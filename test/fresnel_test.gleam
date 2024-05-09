import fresnel/fan_out
import fresnel/roundrobin
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub type Event {
  Emit(String)
  List(Subject(List(String)))
}

pub fn fan_out_test() {
  let assert Ok(publisher) = actor.start([], fan_out.handler)

  let subscriber = fn(event: Event, events: List(String)) {
    case event {
      Emit(msg) -> actor.continue(list.append(events, [msg]))
      List(target) -> {
        process.send(target, events)
        actor.continue(events)
      }
    }
  }

  let assert Ok(sub1) = actor.start([], subscriber)
  let assert Ok(sub2) = actor.start([], subscriber)
  process.send(publisher, fan_out.Subscribe(sub1))
  process.send(publisher, fan_out.Subscribe(sub2))
  process.send(publisher, fan_out.Publish(Emit("1")))
  process.send(publisher, fan_out.Unsubscribe(sub2))
  process.send(publisher, fan_out.Publish(Emit("2")))
  process.sleep(100)
  should.equal(
    ["1", "2"],
    process.call(
      sub1,
      fn(sub: Subject(List(String))) -> Event { List(sub) },
      100,
    ),
  )
  should.equal(
    ["1"],
    process.call(
      sub2,
      fn(sub: Subject(List(String))) -> Event { List(sub) },
      100,
    ),
  )
}

pub fn roundrobin_test() {
  let assert Ok(loadbalancer) = actor.start([], roundrobin.handler)

  let handler = fn(event: Event, events: List(String)) {
    case event {
      Emit(msg) -> actor.continue(list.append(events, [msg]))
      List(target) -> {
        process.send(target, events)
        actor.continue(events)
      }
    }
  }

  let assert Ok(target1) = actor.start([], handler)
  let assert Ok(target2) = actor.start([], handler)
  process.send(loadbalancer, roundrobin.Register(target1))
  process.send(loadbalancer, roundrobin.Register(target2))
  process.send(loadbalancer, roundrobin.Push(Emit("1")))
  process.send(loadbalancer, roundrobin.Push(Emit("2")))
  process.send(loadbalancer, roundrobin.Push(Emit("3")))
  process.send(loadbalancer, roundrobin.Push(Emit("4")))
  process.send(loadbalancer, roundrobin.Unregister(target1))
  process.send(loadbalancer, roundrobin.Push(Emit("5")))
  process.sleep(100)
  should.equal(
    ["1", "3"],
    process.call(
      target1,
      fn(sub: Subject(List(String))) -> Event { List(sub) },
      100,
    ),
  )
  should.equal(
    ["2", "4", "5"],
    process.call(
      target2,
      fn(sub: Subject(List(String))) -> Event { List(sub) },
      100,
    ),
  )
}
