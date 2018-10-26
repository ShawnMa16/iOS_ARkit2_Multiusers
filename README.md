# iOS ARKit2 Multiplayer Demo

A ARKit2 multiplayer demo created and simplified based on [SwifShot Demo](https://developer.apple.com/documentation/arkit/swiftshot_creating_a_game_for_augmented_reality) 

![](AR_multiuser.gif)

## Getting Started

These instructions will get you a copy of the project up and running on your iOS devices for development and testing purposes. See deployment for notes on how to deploy the project.

### Prerequisites

Environments and devices you will need

*  iOS 12
*  Xcode 10
*  two or more iOS devices that are capable of AR

### Installing dependencies

Clone the project and go to its folder in Terminal

Get [CocoaPods](https://guides.cocoapods.org/using/getting-started.html)

```
$ sudo gem install cocoapods
```

Install [SnapKit Library](http://snapkit.io) for Auto Layout 

```
$ pod install
```

## Running the app

You are going to use two or more devices

### Host the game with one device

1. Find and scan the ground plane

2. Wait for the ARKit status label to show "Maped"

**DO NOT ADD GAME OBJECT FOR NOW**

### Join the game 

1. Find and scan the same ground plane

2. Wait for the ARKit status label to show "Maped" on the second device

### Place the game objects on all devices
Game objects will be placed on the center of the yellow Four Square


## Built With

* [SnapKit](http://snapkit.io) - For Auto Layout 
* [AR Joystick](https://www.youtube.com/watch?v=TLBKQFsEFcg) - AR Joystick
* [SwiftShot](https://developer.apple.com/documentation/arkit/swiftshot_creating_a_game_for_augmented_reality) - Based on it

## Authors

* **Shawn Ma**  - [portfolio](https://xiaoma.space)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
