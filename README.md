# fresnel

[![Package Version](https://img.shields.io/hexpm/v/fresnel)](https://hex.pm/packages/fresnel)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/fresnel/)

✨ Make your actors shine 🎭

fresnel is a library to help in working with the OTP framework and actors in gleam. The current supported
features include:

- Round Robin load balancer actor for distributing messages across multiple actor targets
- Fan Out Pub/Sub actor for distributing messages across all subscribed actors

## Usage

```sh
gleam add fresnel
```
```gleam
import fresnel/fan_out
import gleam/otp/actor
import gleam/erlang/process
import gleam/io

type Event {
  Lights
  Camera
  Action
}

fn subscriber(event: Event, id: String) -> actor.Next(Event, String) {
  case event {
    Lights -> {
      io.println(id<>": lights")
      actor.continue(id)
    }
    Camera -> {
      io.println(id<>": camera")
      actor.continue(id)
    }
    Action -> {
      io.println(id<>": action!")
      actor.continue(id)
    }
  }
}

pub fn main() {
  let assert Ok(publisher) = actor.start([], fan_out.handler)  
  let assert Ok(listener1) = actor.start("1", subscriber)
  let assert Ok(listener2) = actor.start("2", subscriber)
  process.send(publisher, Lights)
  process.send(publisher, Camera)
  process.send(publisher, Action)
}
```

outputs:
```
1: lights
2: lights
1: camera
2: camera
1: action!
2: action!
```

Further documentation can be found at <https://hexdocs.pm/fresnel>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
