import Foundation
import Storage

/// Any `@objc protocol` to be used as qualifier of your dependencies.
public typealias Qualifier = Protocol

/// Mock qualifier indicating that dependency must be injected before any other registered.
@objc public protocol Mock {}

/// Inject property wrapper reusable class.
open class InjectPropertyWrapper<Dependency, Parameters>: StorePropertyWrapper<InjectStorage> {
    /// Injection scope.
    public enum Scope {
        /// Singleton injection scope.
        case singleton
        /// Instance injection scope.
        case instance
    }

    /// All `@objc protocol`s to be used as qualifiers of your dependencies.
    open var qualifiers: [Qualifier]?

    /**
     Create a inject property wrapper.

     - Parameter qualifier: Any `@objc protocol` to be used as qualifier of your dependencies.
     */
    public convenience init(_ qualifier: Qualifier) {
        self.init([qualifier])
    }

    /**
     Create a inject property wrapper.

     - Parameter qualifiers: All `@objc protocol`s to be used as qualifiers of your dependencies.
     */
    public convenience init(_ qualifiers: [Qualifier]) {
        var key = String(describing: Dependency.self)
        if let index = key.lastIndex(of: " ") {
            key = String(key[key.index(after: index)...])
        }
        self.init(InjectStorage.standard, key)
        self.qualifiers = qualifiers
    }

    /**
     Register a dependency.

     - Parameter dependency: Dependency to register.
     */
    open func register(_ dependency: Dependency?) {
        storage.set(dependency, forKey: key)
    }

    /**
     Resolve a dependency.

     - Parameter scope: Dependency injection scope.
     - Parameter parameters: Parameters to inject in builder.

     - Throws: `InjectError`.

     - Returns: Resolved dependency.
     */
    open func resolve(_ scope: Scope = .singleton,
                      _ parameters: Parameters? = nil) throws -> Dependency {
        guard var dependencies: [Any] = storage.array(forKey: key) else {
            throw InjectError.notFound(Dependency.self)
        }
        if let dependency = instance(dependencies, scope, parameters) {
            return dependency
        }
        if let qualifiers = qualifiers {
            let qualifiedDependencies = dependencies.filter { dependency in
                qualifiers.allSatisfy { qualifier in
                    class_conformsToProtocol(type(of: dependency) as? AnyClass, qualifier)
                }
            }
            if let dependency = instance(qualifiedDependencies, scope, parameters) {
                return dependency
            } else if qualifiedDependencies.count > 1 {
                dependencies = qualifiedDependencies
            }
        }
        let mockDependencies = dependencies.filter { dependency in
            class_conformsToProtocol(type(of: dependency) as? AnyClass, Mock.self)
        }
        if let dependency = instance(mockDependencies, scope, parameters) {
            return dependency
        }
        throw InjectError.moreThanOne(Dependency.self)
    }

    /**
     Resolve a dependency from candidate dependencies or by calling the builder if necessary.

     - Parameter dependencies: Candidate dependencies.
     - Parameter scope: Dependency injection scope.
     - Parameter parameters: Parameters to inject in builder.

     - Returns: Resolved dependency.
     */
    open func instance(_ dependencies: [Any],
                       _ scope: Scope,
                       _ parameters: Parameters?) -> Dependency? {
        var dependency: Dependency?
        let instances: [Dependency] = map(dependencies)
        if scope == .singleton,
            instances.count == 1 {
            dependency = instances.first
        }
        if let parameters = parameters {
            let builders: [(Parameters) -> Dependency] = map(dependencies)
            if builders.count == 1,
                let builder = builders.first {
                dependency = builder(parameters)
            }
        }
        let builders: [() -> Dependency] = map(dependencies)
        if builders.count == 1,
            let builder = builders.first {
            let instance = builder()
            if scope == .instance, dependency == nil {
                dependency = instance
            } else if instances.isEmpty {
                register(instance)
                dependency = instance
            }
        }
        return dependency
    }

    func map<Result>(_ dependencies: [Any]) -> [Result] {
        dependencies.compactMap { $0 as? Result }
    }

    /**
     A `String` representation of `Error`.

     - Parameter error: Any `Error`.
     */
    open func description(_ error: Error) -> String {
        if let error = error as? InjectError {
            return error.description
        }
        return error.localizedDescription
    }
}

/// `@Inject` property wrapper.
@propertyWrapper
public class Inject<Dependency>: InjectPropertyWrapper<Dependency, Void> {
    /// Injection scope.
    public var scope: Scope = .singleton

    /**
     Create a `Inject` property wrapper.

     - Parameter scope: Injection scope.
     */
    public convenience init(_ scope: Scope = .singleton) {
        self.init([])
        self.scope = scope
    }

    /// Property wrapper stored dependency.
    public var wrappedValue: Dependency? { try? resolve(scope) }
}

/// `@InjectWith` property wrapper.
@propertyWrapper
public class InjectWith<Dependency, Parameters>: InjectPropertyWrapper<Dependency, Parameters> {
    /// Parameters to inject in builder.
    public var parameters: Parameters?

    /**
     Create a `InjectWith` property wrapper.

     - Parameter parameters: Parameters to inject in builder.
     */
    public convenience init(_ parameters: Parameters) {
        self.init([])
        self.parameters = parameters
    }

    /// New dependency instance with parameters injected.
    public var wrappedValue: Dependency? { try? resolve(.instance, parameters) }
}

/// `@UnwrappedInject` property wrapper.
@propertyWrapper
public class UnwrappedInject<Dependency>: InjectPropertyWrapper<Dependency, Void> {
    /// Injection scope.
    public var scope: Scope = .singleton

    /**
     Create a `UnwrappedInject` property wrapper.

     - Parameter scope: Injection scope.
     */
    public convenience init(_ scope: Scope = .singleton) {
        self.init([])
        self.scope = scope
    }

    /// Property wrapper stored dependency.
    public var wrappedValue: Dependency {
        do {
            return try resolve(scope)
        } catch {
            fatalError(description(error))
        }
    }
}

/// `@UnwrappedInjectWith` property wrapper.
@propertyWrapper
public class UnwrappedInjectWith<Dependency, Parameters>: InjectPropertyWrapper<Dependency, Parameters> {
    /// Parameters to inject in builder.
    public var parameters: Parameters?

    /**
     Create a `UnwrappedInjectWith` property wrapper.

     - Parameter parameters: Parameters to inject in builder.
     */
    public convenience init(_ parameters: Parameters) {
        self.init([])
        self.parameters = parameters
    }

    /// New dependency instance with parameters injected.
    public var wrappedValue: Dependency {
        do {
            return try resolve(.instance, parameters)
        } catch {
            fatalError(description(error))
        }
    }
}

/// `@Register` property wrapper.
@propertyWrapper
public class Register<Dependency>: InjectPropertyWrapper<Dependency, Void> {
    /**
     Create a `Register` property wrapper.

     - Parameter wrappedValue: Registered dependency.
     */
    public convenience init(wrappedValue: Dependency) {
        self.init([])
        self.wrappedValue = wrappedValue
    }

    /// Property wrapper stored dependency.
    public var wrappedValue: Dependency {
        get {
            do {
                return try resolve()
            } catch {
                fatalError(description(error))
            }
        }
        set { register(newValue) }
    }
}
