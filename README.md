# 🔐 Secure Property Storage
> Helps you define secure storages for your properties using Swift *property wrappers*.

[![Twitter](https://img.shields.io/badge/contact-%40alexruperez-blue)](http://twitter.com/alexruperez)
[![Swift](https://img.shields.io/badge/swift-5-orange)](https://swift.org)
[![License](https://img.shields.io/github/license/alexruperez/SecurePropertyStorage)](LICENSE)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Action](https://github.com/alexruperez/SecurePropertyStorage/workflows/Swift/badge.svg)](https://github.com/alexruperez/SecurePropertyStorage/actions)
[![Build Status](https://travis-ci.com/alexruperez/SecurePropertyStorage.svg?branch=master)](https://travis-ci.com/alexruperez/SecurePropertyStorage)
[![Build Status](https://app.bitrise.io/app/4fed1af31836d3bc/status.svg?token=bYImtoKj0hxqCxnORhdgyg&branch=master)](https://app.bitrise.io/app/4fed1af31836d3bc)
[![CodeBeat](https://codebeat.co/badges/09a12f07-f53c-4149-b033-df576ec3733b)](https://codebeat.co/projects/github-com-alexruperez-propertywrappers-master)
[![Coverage](https://img.shields.io/codecov/c/github/alexruperez/SecurePropertyStorage)](https://codecov.io/gh/alexruperez/SecurePropertyStorage)
[![Documentation](docs/badge.svg)](https://alexruperez.github.io/SecurePropertyStorage)

## 🌟 Features

All keys are hashed using [SHA512](https://en.wikipedia.org/wiki/SHA-2) and all values are encrypted using [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)-[GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode) to keep user information safe, auto*magic*ally. Symmetric key and nonce, are stored in Keychain in a totally secure way. 

## 🐒 Basic usage

### @UserDefault

This property wrapper will store your property in [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults) using `StoreKey` (any `String` but i recommend you a String typed enum). Optionally, you can assign a default value to the property that will be secure stored at initialization.

```swift
@UserDefault(<#StoreKey#>)
var yourProperty: YourType? = yourDefaultValueIfNeeded
```

[`UserDefaultsStorage`](Sources/UserDefault/UserDefaultsStorage.swift) is also available, a subclass of [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults) with all the security provided by this library.

### @Keychain

This property wrapper will store your property in [Keychain](https://developer.apple.com/documentation/security/keychain_services) using `StoreKey`.

```swift
@Keychain(<#StoreKey#>)
var yourProperty: YourType? = yourDefaultValueIfNeeded
```

As `UserDefaultsStorage`, [`KeychainStorage`](Sources/Keychain/KeychainStorage.swift) is also available.

### @Singleton

This property wrapper will store your property in a memory [singleton](https://en.wikipedia.org/wiki/Singleton_pattern),  every property with the same wrapper and key can access or modify the value from wherever it is.

```swift
@Singleton(<#StoreKey#>)
var yourProperty: YourType? = yourDefaultValueIfNeeded
```

As `KeychainStorage`, [`SingletonStorage`](Sources/Singleton/SingletonStorage.swift) is also available.

### @Inject

This property wrapper is similar to `@Singleton` but, together with `@Register`, will inject your dependencies. More details in [Dependency Injection usage](#-dependency-injection-usage) guide.

```swift
@Inject
var yourDependency: YourProtocol?
```

As `SingletonStorage`, [`InjectStorage`](Sources/Inject/InjectStorage.swift) is also available.

### @Store

This is a custom wrapper, you can define your own [`Storage`](Sources/Storage/Storage.swift) protocol implementation.

```swift
@Store(<#Storage#>, <#StoreKey#>)
var yourProperty: YourType? = yourDefaultValueIfNeeded
```

As `InjectStorage`, [`DelegatedStorage`](Sources/Storage/DelegatedStorage.swift) is also available with all the magic of this library.

## 🧙‍♂️ Codable usage

If your property conforms [`Codable`](https://developer.apple.com/documentation/swift/codable) protocol, just add `Codable` keyword as prefix of your property wrapper.

- **@CodableUserDefault**
- **@CodableKeychain**
- **@CodableSingleton**
- **@CodableStore**

## 🥡 Unwrapped usage

To avoid continually unwrapping your property, just add `Unwrapped` keyword as prefix of your property wrapper, assign a default value (mandatory except for `@UnwrappedInject`), and it will return stored value or default value, but your property will always be there for you.

- **@UnwrappedUserDefault**
- **@UnwrappedKeychain**
- **@UnwrappedSingleton**
- **@UnwrappedInject**
- **@UnwrappedStore**

## 🥡 + 🧙‍♂️ Combo usage

You can also combine previous cases in case you need it, unwrapped first please.

- **@UnwrappedCodableUserDefault**
- **@UnwrappedCodableKeychain**
- **@UnwrappedCodableSingleton**
- **@UnwrappedCodableStore**

## 💉 Dependency Injection usage

- **@Register**

This property wrapper will register the implementations of your dependencies. You can register them wherever you want before inject it, but be sure to do it only once (except if you use [qualifiers](#qualifiers)), for example, in an `Injector` class.

```swift
@Register
var yourDependency: YourProtocol = YourImplementation
```

- **@Inject** and **@UnwrappedInject**

This property wrapper injects your dependencies `@Register` implementations.

```swift
@Inject
var yourDependency: YourProtocol?

@UnwrappedInject
var yourUnwrappedDependency: YourProtocol
```

### Qualifiers

You can use [qualifiers](https://javaee.github.io/tutorial/cdi-basic006.html) to provide various implementations of a particular dependency. A qualifier is just a `@objc protocol` that you apply to a `class`.

For example, you could declare `Dog` and `Cat` qualifier protocols and apply it to another class that conforms `Animal` protocol. To declare this qualifier, use the following code:

```swift
protocol Animal {
  func sound()
}

@objc protocol Dog {}

@objc protocol Cat {}
```

You can then define multiple classes that conforms `Animal` protocol and uses this qualifiers:

```swift
class DogImplementation: Animal, Dog {
    func sound() { print("Woof!") }
}

class CatImplementation: Animal, Cat {
    func sound() { print("Meow!") }
}
```

Both implementations of the class can now be `@Register`:

```swift
@Register
var registerDog: Animal = DogImplementation()

@Register
var registerCat: Animal = CatImplementation()
```

To inject one or the other implementation, simply add the qualifier(s) to your `@Inject`:

```swift
@UnwrappedInject(Dog.self)
var dog: Animal

@UnwrappedInject(Cat.self)
var cat: Animal

dog.sound() // prints Woof!
cat.sound() // prints Meow!
```

## 👀 Examples

> Talk is cheap. Show me the code.

```swift
    // Securely stored in UserDefaults.
    @UserDefault("username")
    var username: String?

    // Securely stored in Keychain.
    @Keychain("password")
    var password: String?

    // Securely stored in a Singleton storage.
    @Singleton("sessionToken")
    var sessionToken: String?

    // Securely stored in a Singleton storage.
    // Always has a value, the stored or the default.
    @UnwrappedSingleton("refreshToken")
    var refreshToken: String = "B0610306-A33F"

    struct User: Codable {
        let username: String
        let password: String?
        let sessionToken: String?
    }

    // Codable model securely stored in UserDefaults.
    @CodableUserDefault("user")
    var user: User?
```

## 🛠 Compatibility

- macOS 10.15+
- iOS 13.0+
- iPadOS 13.0+
- tvOS 13.0+
- watchOS 6.0+

## ⚙️ Installation

#### You can use the [Swift Package Manager](https://github.com/apple/swift-package-manager) by declaring SecurePropertyStorage as a dependency in your `Package.swift` file:

```swift
.package(url: "https://github.com/alexruperez/SecurePropertyStorage", from: "0.3.0")
```

You have a series of products that you can choose:

- **SecurePropertyStorage**: All property wrappers, by default.
- **UserDefault**: @*UserDefault property wrappers.
- **Keychain**: @*Keychain property wrappers.
- **Singleton**: @*Singleton property wrappers.
- **Storage**: @*Store property wrappers.
- **Inject**: @*Inject property wrappers.

*For more information, see [the Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).*

#### Or you can use [Carthage](https://github.com/Carthage/Carthage):

```ogdl
github "alexruperez/SecurePropertyStorage"
```

## 🍻 Etc.

- Featured in [Dave Verwer](https://twitter.com/daveverwer)'s iOS Dev Weekly - [Issue 450](https://iosdevweekly.com/issues/450?#ll98q5s), thanks Dave!
- Contributions are very welcome.
- Attribution is appreciated (let's spread the word!), but not mandatory.

## 👨‍💻 Author

Alex Rupérez – [@alexruperez](https://twitter.com/alexruperez) – me@alexruperez.com

## 👮‍♂️ License

*SecurePropertyStorage* is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
